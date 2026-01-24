// import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for location data
class LocationData {
  final String locationName; // City, State or Region
  final double latitude;
  final double longitude;
  final Timestamp updatedAt;
  final bool isAutoDetected;

  LocationData({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    this.isAutoDetected = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'location': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'locationUpdatedAt': updatedAt,
      'isAutoDetected': isAutoDetected,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      locationName: json['location'] as String? ?? 'Unknown',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['locationUpdatedAt'] as Timestamp? ?? Timestamp.now(),
      isAutoDetected: json['isAutoDetected'] as bool? ?? true,
    );
  }
}

/// Result class for location detection
class LocationResult {
  final bool success;
  final LocationData? data;
  final String? errorMessage;
  final LocationPermissionStatus? permissionStatus;

  LocationResult({
    required this.success,
    this.data,
    this.errorMessage,
    this.permissionStatus,
  });

  factory LocationResult.success(LocationData data) {
    return LocationResult(
      success: true,
      data: data,
    );
  }

  factory LocationResult.error(String message, {LocationPermissionStatus? status}) {
    return LocationResult(
      success: false,
      errorMessage: message,
      permissionStatus: status,
    );
  }
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unknown,
}

/// Service for handling location detection and geocoding
/// 
/// This service uses the device's GPS to detect the user's location
/// and then reverse geocodes it to get the city/region name.
/// 
/// Why auto-detection?
/// - Prevents location spoofing/fraud
/// - Ensures accurate distance-based matching
/// - Updates location when user moves to new city
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled and permissions are granted
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionStatus.serviceDisabled;
      }

      // Check location permission
      permission = await Geolocator.checkPermission();
      switch (permission) {
        case LocationPermission.denied:
          return LocationPermissionStatus.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.deniedForever;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return LocationPermissionStatus.granted;
        default:
          return LocationPermissionStatus.unknown;
      }
    } catch (e) {
      debugPrint('[LocationService] Error checking permission: $e');
      return LocationPermissionStatus.unknown;
    }
  }

  /// Request location permission from the user
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      // First check if services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionStatus.serviceDisabled;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      switch (permission) {
        case LocationPermission.denied:
          return LocationPermissionStatus.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.deniedForever;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return LocationPermissionStatus.granted;
        default:
          return LocationPermissionStatus.unknown;
      }
    } catch (e) {
      debugPrint('[LocationService] Error requesting permission: $e');
      return LocationPermissionStatus.unknown;
    }
  }

  /// Get the current location and reverse geocode it to get city/region
  /// 
  /// This method:
  /// 1. Gets the device's current GPS coordinates
  /// 2. Reverse geocodes to get the city and state/region name
  /// 3. Returns a LocationData object with all the information
  /// 
  /// The location accuracy is set to 'medium' to balance between
  /// accuracy and battery usage. For matching purposes, we only need
  /// city-level accuracy.
  Future<LocationResult> detectCurrentLocation() async {
    try {
      // Check permission first
      final permissionStatus = await requestPermission();
      if (permissionStatus != LocationPermissionStatus.granted) {
        return LocationResult.error(
          _getPermissionErrorMessage(permissionStatus),
          status: permissionStatus,
        );
      }

      // Get current position with medium accuracy (city-level is sufficient)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      // Reverse geocode to get the location name
      final locationName = await _reverseGeocode(position.latitude, position.longitude);

      return LocationResult.success(LocationData(
        locationName: locationName,
        latitude: position.latitude,
        longitude: position.longitude,
        updatedAt: Timestamp.now(),
        isAutoDetected: true,
      ));
    } catch (e) {
      debugPrint('[LocationService] Error detecting location: $e');
      return LocationResult.error('Failed to detect location: ${e.toString()}');
    }
  }

  /// Reverse geocode coordinates to get a human-readable location name
  Future<String> _reverseGeocode(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isEmpty) {
        return 'Unknown Location';
      }

      final place = placemarks.first;
      
      // Build location string: City, State/Region
      final components = <String>[];
      
      if (place.locality != null && place.locality!.isNotEmpty) {
        components.add(place.locality!);
      } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
        components.add(place.subAdministrativeArea!);
      }
      
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        components.add(place.administrativeArea!);
      }
      
      if (components.isEmpty) {
        // Fallback to country if no city/state available
        if (place.country != null && place.country!.isNotEmpty) {
          return place.country!;
        }
        return 'Unknown Location';
      }
      
      return components.join(', ');
    } catch (e) {
      debugPrint('[LocationService] Geocoding error: $e');
      return 'Location detected';
    }
  }

  String _getPermissionErrorMessage(LocationPermissionStatus status) {
    switch (status) {
      case LocationPermissionStatus.denied:
        return 'Location permission denied. Please grant permission to detect your location.';
      case LocationPermissionStatus.deniedForever:
        return 'Location permission permanently denied. Please enable it in your device settings.';
      case LocationPermissionStatus.serviceDisabled:
        return 'Location services are disabled. Please enable GPS/Location services.';
      default:
        return 'Unable to access location. Please check your settings.';
    }
  }

  /// Calculate distance between two coordinates in kilometers
  /// Uses the Haversine formula for accurate distance calculation
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  /// Check if a location update is needed
  /// Location should be refreshed periodically (e.g., every 24 hours)
  /// or if the user has moved significantly
  bool shouldUpdateLocation(Timestamp? lastUpdated, {Duration maxAge = const Duration(hours: 24)}) {
    if (lastUpdated == null) return true;
    
    final lastUpdate = lastUpdated.toDate();
    final now = DateTime.now();
    
    return now.difference(lastUpdate) > maxAge;
  }

  /// Open app settings (for when permission is denied forever)
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings (for when location service is disabled)
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
