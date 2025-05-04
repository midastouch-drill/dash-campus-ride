
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/features/ride/providers/driver_ride_provider.dart';
import 'package:campus_dash/features/ride/models/active_ride_model.dart';
import 'package:campus_dash/shared/widgets/shimmer_loading.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:campus_dash/features/auth/providers/driver_provider.dart';
import 'package:go_router/go_router.dart';

class DriverRideTrackingScreen extends ConsumerStatefulWidget {
  final String rideId;
  
  const DriverRideTrackingScreen({
    super.key,
    required this.rideId,
  });

  @override
  ConsumerState<DriverRideTrackingScreen> createState() => _DriverRideTrackingScreenState();
}

class _DriverRideTrackingScreenState extends ConsumerState<DriverRideTrackingScreen> {
  final MapController _mapController = MapController();
  Timer? _locationTimer;
  Position? _currentPosition;
  bool _isTrackingLocation = false;
  TextEditingController _cancelReasonController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _fetchCurrentRide();
    _getCurrentLocation();
    _startLocationUpdates();
  }
  
  @override
  void dispose() {
    _locationTimer?.cancel();
    _cancelReasonController.dispose();
    super.dispose();
  }
  
  void _fetchCurrentRide() {
    ref.read(driverRideProvider.notifier).fetchActiveRide();
  }
  
  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _getCurrentLocation();
    });
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
        _isTrackingLocation = true;
      });
      
      // Update driver location in API
      ref.read(driverProvider.notifier).updateLocation([
        position.longitude,
        position.latitude,
      ]);
      
      // Optionally update map view
      if (_mapController.camera.zoom > 0) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          _mapController.camera.zoom,
        );
      }
    } catch (e) {
      setState(() {
        _isTrackingLocation = false;
      });
      print('Error getting current location: $e');
    }
  }
  
  Future<void> _showCancelDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Ride'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Please provide a reason for cancellation:'),
                const SizedBox(height: 16),
                TextField(
                  controller: _cancelReasonController,
                  decoration: const InputDecoration(
                    hintText: 'Enter reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('BACK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('SUBMIT'),
              onPressed: () {
                if (_cancelReasonController.text.isNotEmpty) {
                  ref.read(driverRideProvider.notifier).cancelRide(
                    widget.rideId,
                    _cancelReasonController.text,
                  );
                  Navigator.of(context).pop();
                  context.go('/dashboard');
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(driverRideProvider);
    final activeRide = rideState.activeRide;
    
    // Check if the active ride matches the requested ride ID
    final isCorrectRide = activeRide?.id == widget.rideId;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        actions: [
          if (isCorrectRide && (activeRide?.status == 'accepted' || activeRide?.status == 'started'))
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: _showCancelDialog,
              tooltip: 'Cancel Ride',
            ),
        ],
      ),
      body: rideState.isLoadingActiveRide
          ? const Center(child: CircularProgressIndicator())
          : activeRide == null || !isCorrectRide
              ? _buildRideNotFoundWidget()
              : _buildRideDetailsWidget(context, activeRide),
      bottomNavigationBar: isCorrectRide && activeRide != null
          ? _buildActionButton(activeRide)
          : null,
    );
  }
  
  Widget _buildRideNotFoundWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ride not found or no longer active',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The ride may have been completed or cancelled',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.go('/dashboard');
            },
            child: const Text('Return to Dashboard'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRideDetailsWidget(BuildContext context, ActiveRide ride) {
    final pickupLatLng = LatLng(
      ride.pickupLocation.coordinates[1],
      ride.pickupLocation.coordinates[0],
    );
    final dropoffLatLng = LatLng(
      ride.dropoffLocation.coordinates[1],
      ride.dropoffLocation.coordinates[0],
    );
    
    final currentLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : pickupLatLng;
    
    return Column(
      children: [
        // Map view (takes 40% of screen height)
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLatLng,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.campus_dash.app',
              ),
              MarkerLayer(
                markers: [
                  // Current location marker
                  if (_currentPosition != null)
                    Marker(
                      width: 40,
                      height: 40,
                      point: currentLatLng,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                    ),
                  
                  // Pickup location marker
                  Marker(
                    width: 40,
                    height: 40,
                    point: pickupLatLng,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.trip_origin,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // Dropoff location marker
                  Marker(
                    width: 40,
                    height: 40,
                    point: dropoffLatLng,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.place,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Ride details (60% of the screen)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rider information card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            size: 28,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ride.riderName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildStatusBadge(ride.status),
                                  const SizedBox(width: 8),
                                  Text(
                                    ride.paymentMethod.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone),
                          onPressed: () {
                            // Implement phone call to rider
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Ride details card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ride Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Pickup location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.trip_origin, size: 16, color: Colors.green.shade800),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pickup',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    ride.pickupLocation.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Dotted line
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: SizedBox(
                            height: 20,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                3,
                                (index) => Container(
                                  width: 2,
                                  height: 2,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Dropoff location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.place, size: 16, color: Colors.red.shade800),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dropoff',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    ride.dropoffLocation.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Trip metrics
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricItem(
                              context,
                              'Distance',
                              '${ride.distance.toStringAsFixed(1)} km',
                              Icons.map,
                            ),
                            _buildMetricItem(
                              context,
                              'Duration',
                              '${ride.duration} min',
                              Icons.access_time,
                            ),
                            _buildMetricItem(
                              context,
                              'Fare',
                              '₦${ride.amount.toStringAsFixed(2)}',
                              Icons.attach_money,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Location tracking status
                if (!_isTrackingLocation)
                  Card(
                    elevation: 0,
                    color: Colors.amber.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_disabled,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Location tracking is disabled. Please enable it for accurate navigation.',
                              style: TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton(ActiveRide ride) {
    final canStart = ride.status == 'accepted';
    final canComplete = ride.status == 'started';
    
    if (canStart) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              ref.read(driverRideProvider.notifier).startRide(ride.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('START RIDE'),
          ),
        ),
      );
    } else if (canComplete) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              ref.read(driverRideProvider.notifier).completeRide(ride.id);
              context.go('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('COMPLETE RIDE'),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
  
  Widget _buildMetricItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
  
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Pending';
        break;
      case 'accepted':
        color = Colors.blue;
        text = 'Accepted';
        break;
      case 'started':
        color = Colors.green;
        text = 'In Progress';
        break;
      case 'completed':
        color = Colors.purple;
        text = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      default:
        color = Colors.grey;
        text = status.toUpperCase();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
