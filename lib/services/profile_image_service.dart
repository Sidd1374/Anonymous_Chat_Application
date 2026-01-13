import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A singleton service to manage profile image caching and provide
/// ImageProviders across the app without reloading.
class ProfileImageService extends ChangeNotifier {
  static final ProfileImageService _instance = ProfileImageService._internal();
  factory ProfileImageService() => _instance;
  ProfileImageService._internal();

  ImageProvider? _profileImageProvider;
  String? _currentUrl;
  bool _isLoading = false;
  File? _cachedFile;

  /// Get the current cached image provider (may be null if not loaded)
  ImageProvider? get imageProvider => _profileImageProvider;

  /// Check if the image is currently being loaded
  bool get isLoading => _isLoading;

  /// Get the cached file directly (useful for file operations)
  File? get cachedFile => _cachedFile;

  /// Get the current URL being cached
  String? get currentUrl => _currentUrl;

  /// Pre-load and cache the profile image from a URL.
  /// Returns the ImageProvider once ready.
  Future<ImageProvider?> loadProfileImage(String? url) async {
    if (url == null || url.isEmpty) {
      _profileImageProvider = null;
      _currentUrl = null;
      _cachedFile = null;
      notifyListeners();
      return null;
    }

    // If same URL is already loaded, return existing provider
    if (_currentUrl == url && _profileImageProvider != null) {
      return _profileImageProvider;
    }

    _isLoading = true;
    _currentUrl = url;
    notifyListeners();

    try {
      // Try to get from cache first, download if needed
      final file = await DefaultCacheManager().getSingleFile(url);
      _cachedFile = file;
      _profileImageProvider = FileImage(file);
      debugPrint('[ProfileImageService] Image loaded from cache: ${file.path}');
    } catch (e) {
      debugPrint('[ProfileImageService] Cache error, using network provider: $e');
      // Fallback to network provider (will still use cache internally)
      _profileImageProvider = CachedNetworkImageProvider(url);
      _cachedFile = null;
    }

    _isLoading = false;
    notifyListeners();
    return _profileImageProvider;
  }

  /// Update the image provider directly (e.g., after uploading a new image)
  void updateImageProvider(ImageProvider? provider, {String? url, File? file}) {
    _profileImageProvider = provider;
    _currentUrl = url;
    _cachedFile = file;
    notifyListeners();
  }

  /// Clear the cached image (e.g., on logout)
  void clear() {
    _profileImageProvider = null;
    _currentUrl = null;
    _cachedFile = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Refresh the image from network (force re-download)
  Future<ImageProvider?> refreshProfileImage(String? url) async {
    if (url == null || url.isEmpty) return null;

    _isLoading = true;
    notifyListeners();

    try {
      // Remove from cache first
      await DefaultCacheManager().removeFile(url);
      // Re-download
      final file = await DefaultCacheManager().downloadFile(url);
      _cachedFile = file.file;
      _profileImageProvider = FileImage(file.file);
      _currentUrl = url;
      debugPrint('[ProfileImageService] Image refreshed: ${file.file.path}');
    } catch (e) {
      debugPrint('[ProfileImageService] Refresh error: $e');
      _profileImageProvider = CachedNetworkImageProvider(url);
    }

    _isLoading = false;
    notifyListeners();
    return _profileImageProvider;
  }
}
