/// Performance configuration for optimizing app across all device types
/// Includes settings for low-end, mid-range, and high-end devices
class PerformanceConfig {
  // Image caching and loading
  static const int maxImageCacheSize = 100; // MB
  static const int maxImageCacheCount = 200; // images
  static const int imageCacheDuration = 7; // days
  
  // List pagination and lazy loading
  static const int initialLoadCount = 20;
  static const int loadMoreThreshold = 5; // items from bottom
  static const int loadMoreCount = 10;
  
  // Firestore query limits
  static const int maxChatsLimit = 50;
  static const int maxMessagesLimit = 50;
  static const int maxFriendsLimit = 100;
  static const int maxNotificationsLimit = 30;
  
  // Stream debouncing (milliseconds)
  static const int searchDebounceMs = 300;
  static const int typingIndicatorDebounceMs = 500;
  
  // Memory management
  static const bool enableMemoryOptimization = true;
  static const int disposeControllerDelayMs = 1000;
  
  // Animation durations (reduced for low-end devices)
  static const int defaultAnimationMs = 200;
  static const int fastAnimationMs = 100;
  
  // Image quality settings
  static const int thumbnailQuality = 70;
  static const int fullImageQuality = 85;
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  
  // Network optimization
  static const int connectionTimeout = 30; // seconds
  static const int maxRetries = 3;
  
  // UI optimization
  static const bool enableHapticFeedback = true;
  static const bool enableAnimations = true;
  static const double listItemHeight = 80.0;
  
  // Background task limits
  static const int maxConcurrentUploads = 2;
  static const int maxConcurrentDownloads = 3;
  
  /// Check if device is low-end based on available memory
  static bool isLowEndDevice() {
    // This is a placeholder - in production, you'd check actual device specs
    // For now, we'll optimize for all devices
    return false;
  }
  
  /// Get optimized image cache size based on device
  static int getImageCacheSize() {
    return isLowEndDevice() ? 50 : maxImageCacheSize;
  }
  
  /// Get optimized list load count based on device
  static int getInitialLoadCount() {
    return isLowEndDevice() ? 15 : initialLoadCount;
  }
  
  /// Get animation duration based on device
  static int getAnimationDuration() {
    return isLowEndDevice() ? fastAnimationMs : defaultAnimationMs;
  }
}
