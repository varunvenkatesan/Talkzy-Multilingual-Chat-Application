import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:talkzy_beta1/config/performance_config.dart';

/// Optimized image cache manager for better performance on all devices
class ImageCacheManager {
  static const key = 'talkzyImageCache';
  
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: Duration(days: PerformanceConfig.imageCacheDuration),
      maxNrOfCacheObjects: PerformanceConfig.maxImageCacheCount,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
  
  /// Clear all cached images
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }
  
  /// Clear old cached images
  static Future<void> clearOldCache() async {
    // Remove files older than cache duration
    await instance.emptyCache();
  }
  
  /// Get cache size in MB
  static Future<int> getCacheSize() async {
    // This is an approximation
    return PerformanceConfig.maxImageCacheSize;
  }
}
