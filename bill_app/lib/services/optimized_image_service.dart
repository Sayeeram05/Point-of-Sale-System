import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'api_service.dart';

class OptimizedImageService {
  static final CustomCacheManager _cacheManager = CustomCacheManager();

  /// Normalise any image URL so it always uses [ApiService.baseUrl].
  /// The server may return an absolute URL whose host differs from what
  /// the client can reach (e.g. `http://localhost:8000/media/…` vs
  /// `http://10.0.2.2:8000/media/…`).  We extract just the path and
  /// prepend the configured base URL.
  static String _resolveUrl(String imageUrl, {String? baseUrl}) {
    final String base = baseUrl ?? ApiService.baseUrl;
    if (imageUrl.startsWith('http')) {
      final uri = Uri.tryParse(imageUrl);
      if (uri != null) {
        // Use only the path portion, rebuild with configured base
        return '$base${uri.path}';
      }
    }
    // Relative path – just prepend base
    return '$base$imageUrl';
  }

  static Widget optimizedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Widget? placeholder,
    Widget? errorWidget,
    String? baseUrl,
    int? memCacheWidth,
    int? memCacheHeight,
  }) {
    final String fullUrl = _resolveUrl(imageUrl, baseUrl: baseUrl);

    return SizedBox(
      width: width,
      height: height,
      child: CachedNetworkImage(
        imageUrl: fullUrl,
        cacheManager: _cacheManager,
        fit: fit,
        memCacheWidth:
            memCacheWidth ?? (width != null ? (width * 2).toInt() : null),
        memCacheHeight:
            memCacheHeight ?? (height != null ? (height * 2).toInt() : null),
        placeholder: (context, url) =>
            placeholder ?? const _DefaultPlaceholder(),
        errorWidget: (context, url, error) {
          // Evict the failed entry so the next rebuild retries from network
          _cacheManager.removeFile(fullUrl);
          return errorWidget ?? const _DefaultErrorWidget();
        },
        fadeInDuration: const Duration(milliseconds: 100),
        fadeOutDuration: const Duration(milliseconds: 50),
        useOldImageOnUrlChange: true,
      ),
    );
  }

  static Future<void> preloadImage(String imageUrl) async {
    final String fullUrl = _resolveUrl(imageUrl);
    try {
      await _cacheManager.getSingleFile(fullUrl);
    } catch (e) {
      // Silently handle preload errors
    }
  }

  /// Preload a batch of image URLs concurrently with controlled parallelism.
  /// Uses up to [concurrency] simultaneous downloads (default 6).
  static Future<void> preloadImages(
    List<String> imageUrls, {
    int concurrency = 6,
  }) async {
    if (imageUrls.isEmpty) return;

    // Deduplicate URLs
    final unique = imageUrls.toSet().toList();

    // Process in batches of [concurrency]
    for (int i = 0; i < unique.length; i += concurrency) {
      final batch = unique.skip(i).take(concurrency);
      await Future.wait(
        batch.map((url) => preloadImage(url)),
        eagerError: false,
      );
    }
  }

  static Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  /// Remove a single cached image (e.g. after the server updates it).
  static Future<void> evictImage(String imageUrl) async {
    final String fullUrl = _resolveUrl(imageUrl);
    await _cacheManager.removeFile(fullUrl);
  }
}

class CustomCacheManager extends CacheManager {
  CustomCacheManager._()
    : super(
        Config(
          _key,
          stalePeriod: const Duration(days: 1), // Keep images for 1 day
          maxNrOfCacheObjects: 500, // Enough for all product images
          repo: JsonCacheInfoRepository(databaseName: _key),
          fileService: HttpFileService(),
        ),
      );

  static const String _key = 'bill_app_image_cache';

  static final CustomCacheManager _instance = CustomCacheManager._();

  factory CustomCacheManager() {
    return _instance;
  }
}

/// Const placeholder widget for cached images — avoids per-call allocations.
class _DefaultPlaceholder extends StatelessWidget {
  const _DefaultPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF5F5F5), // Colors.grey[100]
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
        ),
      ),
    );
  }
}

/// Const error widget for cached images.
class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFEEEEEE), // Colors.grey[200]
      child: Center(
        child: Icon(Icons.fastfood_rounded, color: Color(0xFF9E9E9E), size: 24),
      ),
    );
  }
}
