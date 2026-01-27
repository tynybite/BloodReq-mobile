import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Utility class for handling avatar images that can be either
/// Base64 data URIs or network URLs.
class AvatarUtils {
  /// Returns an appropriate ImageProvider based on the avatar URL format.
  ///
  /// - If the URL is a Base64 data URI (starts with 'data:'), returns a MemoryImage
  /// - If the URL is a network URL, returns a CachedNetworkImageProvider
  /// - If the URL is null or empty, returns null
  static ImageProvider? getImageProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }

    // Check if it's a Base64 data URI
    if (avatarUrl.startsWith('data:')) {
      try {
        // Extract the base64 part after the comma
        final base64Data = avatarUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        return MemoryImage(Uint8List.fromList(bytes));
      } catch (e) {
        debugPrint('Error decoding Base64 avatar: $e');
        return null;
      }
    }

    // Otherwise, treat as network URL
    return CachedNetworkImageProvider(avatarUrl);
  }

  /// Checks if the avatar URL is valid (not null and not empty)
  static bool hasAvatar(String? avatarUrl) {
    return avatarUrl != null && avatarUrl.isNotEmpty;
  }
}
