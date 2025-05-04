
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_dash/core/themes/app_theme.dart';
import 'package:campus_dash/features/ride/providers/ride_request_provider.dart';
import 'package:campus_dash/features/ride/widgets/location_search_field.dart';
import 'package:campus_dash/shared/widgets/custom_snackbar.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class RequestRideScreen extends ConsumerStatefulWidget {
  const RequestRideScreen({super.key});

  @override
  ConsumerState<RequestRideScreen> createState() => _RequestRideScreenState();
}

class _RequestRideScreenState extends ConsumerState<RequestRideScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  
  late MapController _mapController;
  GeoPoint? _pickupLocation;
  GeoPoint? _dropoffLocation;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController(
      initPosition: GeoPoint(latitude: 6.5244, longitude: 3.3792), // Lagos
    );
  }
  
  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _mapController.dispose();
    super.dispose();
  }
  
  Future<void> _onPickupSelected(GeoPoint point, String address) async {
    setState(() {
      _pickupLocation = point;
      _pickupController.text = address;
    });
    
    await _mapController.addMarker(
      point,
      markerIcon: const MarkerIcon(
        icon: Icon(
          Icons.location_on,
          color: Colors.green,
          size: 48,
        ),
      ),
    );
    
    await _mapController.centerMap(point);
    _updateMapBounds();
  }
  
  Future<void> _onDropoffSelected(GeoPoint point, String address) async {
    setState(() {
      _dropoffLocation = point;
      _dropoffController.text = address;
    });
    
    await _mapController.addMarker(
      point,
      markerIcon: const MarkerIcon(
        icon: Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 48,
        ),
      ),
    );
    
    _updateMapBounds();
  }
  
  void _updateMapBounds() {
    if (_pickupLocation != null && _dropoffLocation != null) {
      final bounds = BoundingBox(
        north: _pickupLocation!.latitude > _dropoffLocation!.latitude
            ? _pickupLocation!.latitude
            : _dropoffLocation!.latitude,
        east: _pickupLocation!.longitude > _dropoffLocation!.longitude
            ? _pickupLocation!.longitude
            : _dropoffLocation!.longitude,
        south: _pickupLocation!.latitude < _dropoffLocation!.latitude
            ? _pickupLocation!.latitude
            : _dropoffLocation!.latitude,
        west: _pickupLocation!.longitude < _dropoffLocation!.longitude
            ? _pickupLocation!.longitude
            : _dropoffLocation!.longitude,
      );
      
      _mapController.zoomToBoundingBox(
        bounds,
        paddinInPixel: 60,
      );
      
      // Draw route
      _mapController.drawRoad(
        _pickupLocation!,
        _dropoffLocation!,
        roadType: RoadType.car,
        roadOption: const RoadOption(
          roadWidth: 10,
          roadColor: primaryColor,
        ),
      );
      
      // Calculate distance and fare
      _calculateRideDetails();
    } else if (_pickupLocation != null) {
      _mapController.centerMap(_pickupLocation!);
    } else if (_dropoffLocation != null) {
      _mapController.centerMap(_dropoffLocation!);
    }
  }
  
  Future<void> _calculateRideDetails() async {
    if (_pickupLocation != null && _dropoffLocation != null) {
      try {
        final roadInfo = await _mapController.drawRoad(
          _pickupLocation!,
          _dropoffLocation!,
          roadType: RoadType.car,
          roadOption: const RoadOption(
            roadWidth: 10,
            roadColor: primaryColor,
          ),
        );
        
        // Pass distance and duration to provider
        ref.read(rideRequestProvider.notifier).setRideDetails(
          distance: roadInfo.distance,
          duration: roadInfo.duration ~/ 60, // Convert seconds to minutes
          pickupLocation: _pickupLocation!,
          pickupAddress: _pickupController.text,
          dropoffLocation: _dropoffLocation!,
          dropoffAddress: _dropoffController.text,
        );
      } catch (e) {
        if (mounted) {
          showCustomSnackBar(
            context: context,
            message: 'Failed to calculate route',
            isError: true,
          );
        }
      }
    }
  }
  
  Future<void> _requestRide() async {
    if (_pickupLocation == null || _dropoffLocation == null) {
      showCustomSnackBar(
        context: context,
        message: 'Please select pickup and dropoff locations',
        isError: true,
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final rideId = await ref.read(rideRequestProvider.notifier).requestRide();
      
      if (mounted && rideId != null) {
        context.push('/ride/$rideId');
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Failed to request ride: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final rideRequestState = ref.watch(rideRequestProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Ride'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LocationSearchField(
                  controller: _pickupController,
                  label: 'Pick up',
                  hint: 'Where are you?',
                  prefixIcon: Icons.circle,
                  prefixIconColor: Colors.green,
                  onLocationSelected: _onPickupSelected,
                ),
                const SizedBox(height: 12),
                LocationSearchField(
                  controller: _dropoffController,
                  label: 'Drop off',
                  hint: 'Where are you going?',
                  prefixIcon: Icons.place,
                  prefixIconColor: Colors.red,
                  onLocationSelected: _onDropoffSelected,
                ),
              ],
            ),
          ),
          
          // Map view
          Expanded(
            child: Stack(
              children: [
                OSMFlutter(
                  controller: _mapController,
                  osmOption: const OSMOption(
                    zoomOption: ZoomOption(
                      initZoom: 15,
                      minZoomLevel: 3,
                      maxZoomLevel: 19,
                      stepZoom: 1.0,
                    ),
                  ),
                ),
                
                // Ride details overlay when both points are selected
                if (_pickupLocation != null && _dropoffLocation != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Ride Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Campus Ride',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildDetailItem(
                                Icons.route,
                                '${rideRequestState.distance.toStringAsFixed(1)} km',
                                'Distance',
                              ),
                              _buildDetailItem(
                                Icons.timer,
                                '${rideRequestState.duration} min',
                                'Duration',
                              ),
                              _buildDetailItem(
                                Icons.attach_money,
                                '₦${rideRequestState.fare.toStringAsFixed(2)}',
                                'Fare',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: rideRequestState.isRequestingRide
                                      ? null
                                      : () {
                                          // Reset selection
                                          setState(() {
                                            _pickupLocation = null;
                                            _dropoffLocation = null;
                                            _pickupController.clear();
                                            _dropoffController.clear();
                                          });
                                          _mapController.clearAllRoads();
                                          _mapController.removeMarker(_pickupLocation!);
                                          _mapController.removeMarker(_dropoffLocation!);
                                        },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reset'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _requestRide,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: _isLoading
                                      ? Container(
                                          width: 24,
                                          height: 24,
                                          padding: const EdgeInsets.all(2.0),
                                          child: const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.local_taxi),
                                  label: Text(_isLoading ? 'Requesting...' : 'Request Ride'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
