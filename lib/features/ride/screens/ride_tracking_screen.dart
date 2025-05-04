
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_dash/core/themes/app_theme.dart';
import 'package:campus_dash/features/ride/models/active_ride_model.dart';
import 'package:campus_dash/features/ride/providers/active_ride_provider.dart';
import 'package:campus_dash/shared/widgets/custom_snackbar.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class RideTrackingScreen extends ConsumerStatefulWidget {
  final String rideId;

  const RideTrackingScreen({
    super.key,
    required this.rideId,
  });

  @override
  ConsumerState<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends ConsumerState<RideTrackingScreen> {
  late MapController _mapController;
  Timer? _pollingTimer;
  bool _isMapReady = false;
  bool _isRatingRide = false;
  double _ratingValue = 5.0;
  TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController(
      initPosition: GeoPoint(latitude: 6.5244, longitude: 3.3792), // Lagos
    );
    
    Future.microtask(() {
      ref.read(activeRideProvider.notifier).fetchRideDetails(widget.rideId);
    });
    
    // Setup polling for ride status updates
    _startStatusPolling();
  }
  
  void _startStatusPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        ref.read(activeRideProvider.notifier).fetchRideDetails(widget.rideId);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _mapController.dispose();
    _reviewController.dispose();
    super.dispose();
  }
  
  Future<void> _updateMap(ActiveRide ride) async {
    if (!_isMapReady) return;
    
    try {
      // Clear existing markers and roads
      await _mapController.clearAllRoads();
      
      // Add pickup marker
      final pickupPoint = GeoPoint(
        latitude: ride.pickupCoordinates[1],
        longitude: ride.pickupCoordinates[0],
      );
      
      await _mapController.addMarker(
        pickupPoint,
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.circle,
            color: Colors.green,
            size: 24,
          ),
        ),
      );
      
      // Add dropoff marker
      final dropoffPoint = GeoPoint(
        latitude: ride.dropoffCoordinates[1],
        longitude: ride.dropoffCoordinates[0],
      );
      
      await _mapController.addMarker(
        dropoffPoint,
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.place,
            color: Colors.red,
            size: 36,
          ),
        ),
      );
      
      // Draw route between pickup and dropoff
      await _mapController.drawRoad(
        pickupPoint,
        dropoffPoint,
        roadType: RoadType.car,
        roadOption: const RoadOption(
          roadWidth: 10,
          roadColor: primaryColor,
        ),
      );
      
      // If driver location is available, add driver marker
      if (ride.status == RideStatus.accepted || ride.status == RideStatus.ongoing) {
        // In a real app, we would have the driver's current location
        // For now, we'll simulate by placing the driver near the pickup location
        final driverPoint = GeoPoint(
          latitude: ride.pickupCoordinates[1] + 0.001,
          longitude: ride.pickupCoordinates[0] + 0.001,
        );
        
        await _mapController.addMarker(
          driverPoint,
          markerIcon: const MarkerIcon(
            icon: Icon(
              Icons.local_taxi,
              color: primaryColor,
              size: 36,
            ),
          ),
        );
      }
      
      // Adjust map bounds to show all markers
      final bounds = BoundingBox(
        north: pickupPoint.latitude > dropoffPoint.latitude
            ? pickupPoint.latitude
            : dropoffPoint.latitude,
        east: pickupPoint.longitude > dropoffPoint.longitude
            ? pickupPoint.longitude
            : dropoffPoint.longitude,
        south: pickupPoint.latitude < dropoffPoint.latitude
            ? pickupPoint.latitude
            : dropoffPoint.latitude,
        west: pickupPoint.longitude < dropoffPoint.longitude
            ? pickupPoint.longitude
            : dropoffPoint.longitude,
      );
      
      await _mapController.zoomToBoundingBox(
        bounds,
        paddinInPixel: 60,
      );
    } catch (e) {
      print('Error updating map: $e');
    }
  }
  
  Future<void> _cancelRide() async {
    try {
      await ref.read(activeRideProvider.notifier).cancelRide(widget.rideId);
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Ride cancelled successfully',
        );
        
        // Navigate back to dashboard after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/dashboard');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Failed to cancel ride: ${e.toString()}',
          isError: true,
        );
      }
    }
  }
  
  Future<void> _rateRide() async {
    if (_isRatingRide) return;
    
    setState(() {
      _isRatingRide = true;
    });
    
    try {
      await ref.read(activeRideProvider.notifier).rateRide(
        widget.rideId,
        _ratingValue,
        _reviewController.text,
      );
      
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Thank you for your rating!',
        );
        
        // Navigate back to dashboard after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go('/dashboard');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Failed to submit rating: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRatingRide = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final activeRideState = ref.watch(activeRideProvider);
    final ride = activeRideState.ride;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Status'),
      ),
      body: activeRideState.isLoading && ride == null
          ? const Center(child: CircularProgressIndicator())
          : ride == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load ride details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activeRideState.error ?? 'Unknown error',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(activeRideProvider.notifier).fetchRideDetails(widget.rideId);
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Status indicator
                    _buildStatusIndicator(ride.status),
                    
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
                            onMapIsReady: (isReady) {
                              setState(() {
                                _isMapReady = isReady;
                              });
                              if (isReady) {
                                _updateMap(ride);
                              }
                            },
                          ),
                          
                          // Driver found overlay for accepted status
                          if (ride.status == RideStatus.accepted && ride.driver != null)
                            Positioned(
                              top: 16,
                              left: 16,
                              right: 16,
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: primaryLightColor,
                                            backgroundImage: ride.driver!.profilePicture != null
                                                ? NetworkImage(ride.driver!.profilePicture!)
                                                : null,
                                            child: ride.driver!.profilePicture == null
                                                ? Text(
                                                    ride.driver!.firstName.substring(0, 1),
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${ride.driver!.firstName} ${ride.driver!.lastName}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${ride.driver!.vehicle.color} ${ride.driver!.vehicle.make} ${ride.driver!.vehicle.model}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'License Plate: ${ride.driver!.vehicle.licensePlate}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                // Call driver
                                              },
                                              icon: const Icon(Icons.phone),
                                              label: const Text('Call'),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                // Message driver
                                              },
                                              icon: const Icon(Icons.chat),
                                              label: const Text('Message'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Ride details bottom sheet
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ride info row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fare',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '₦${ride.fare.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Payment Method',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    ride.paymentMethod.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Action button based on ride status
                          if (ride.status == RideStatus.pending)
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _cancelRide,
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancel Ride'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            )
                          else if (ride.status == RideStatus.completed && ride.rating == null)
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showRatingDialog();
                                },
                                icon: const Icon(Icons.star),
                                label: const Text('Rate Your Ride'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildStatusIndicator(RideStatus status) {
    String message;
    Color color;
    bool showLoading = false;
    
    switch (status) {
      case RideStatus.pending:
        message = 'Finding a driver...';
        color = Colors.blue;
        showLoading = true;
        break;
      case RideStatus.accepted:
        message = 'Driver is on the way';
        color = Colors.orange;
        showLoading = false;
        break;
      case RideStatus.ongoing:
        message = 'Your ride is in progress';
        color = primaryColor;
        showLoading = false;
        break;
      case RideStatus.completed:
        message = 'Ride completed';
        color = Colors.green;
        showLoading = false;
        break;
      case RideStatus.cancelled:
        message = 'Ride cancelled';
        color = Colors.red;
        showLoading = false;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: color.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showLoading) ...[
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(width: 8),
          ] else
            Icon(
              status == RideStatus.completed
                  ? Icons.check_circle
                  : status == RideStatus.cancelled
                      ? Icons.cancel
                      : Icons.local_taxi,
              color: color,
            ),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Rate Your Ride'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Rating stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            _ratingValue > index ? Icons.star : Icons.star_border,
                            size: 32,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _ratingValue = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _reviewController,
                      decoration: const InputDecoration(
                        labelText: 'Review (optional)',
                        hintText: 'Share your experience...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _rateRide();
                  },
                  child: _isRatingRide
                      ? const CircularProgressIndicator()
                      : const Text('SUBMIT'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
