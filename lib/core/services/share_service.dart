import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ShareService {
  static const String _appName = 'Graffiniti';
  static const String _appUrl = 'https://graffiniti.app';

  /// Share profile with other apps
  static Future<void> shareProfile({
    required String displayName,
    required String userId,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      final String shareText = '''
🎨 Check out $displayName on $_appName!

${bio != null && bio.isNotEmpty ? '$bio\n\n' : ''}Artist ID: $userId

Discover amazing AR graffiti art and join the street art revolution!

Download $_appName: $_appUrl
''';

      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        // Try to share with image
        final imageFile = await _downloadImage(profileImageUrl, 'profile_$userId');
        if (imageFile != null) {
          await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: shareText,
            subject: '$displayName\'s $_appName Profile',
          );
          return;
        }
      }

      // Fallback to text-only share
      await Share.share(
        shareText,
        subject: '$displayName\'s $_appName Profile',
      );
    } catch (e) {
      debugPrint('Error sharing profile: $e');
      // Fallback to simple text share
      await Share.share('Check out $_appName - The AR Graffiti Revolution! $_appUrl');
    }
  }

  /// Share graffiti artwork
  static Future<void> shareGraffiti({
    required String title,
    required String artistName,
    String? location,
    String? imageUrl,
    String? graffitiId,
  }) async {
    try {
      final String shareText = '''
🎯 Amazing AR graffiti by $artistName!

"$title"
${location != null ? '📍 $location\n' : ''}
Created with $_appName - Transform reality with AR art!

${graffitiId != null ? 'View in AR: $_appUrl/graffiti/$graffitiId\n' : ''}
Download $_appName: $_appUrl
''';

      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Try to share with image
        final imageFile = await _downloadImage(imageUrl, 'graffiti_${graffitiId ?? 'shared'}');
        if (imageFile != null) {
          await Share.shareXFiles(
            [XFile(imageFile.path)],
            text: shareText,
            subject: '$title by $artistName',
          );
          return;
        }
      }

      // Fallback to text-only share
      await Share.share(
        shareText,
        subject: '$title by $artistName',
      );
    } catch (e) {
      debugPrint('Error sharing graffiti: $e');
      await Share.share('Check out this amazing AR graffiti on $_appName! $_appUrl');
    }
  }

  /// Share app with friends
  static Future<void> shareApp() async {
    try {
      const String shareText = '''
🎨 Join me on $_appName!

Transform the world with augmented reality art. Create, share, and discover digital graffiti in real locations.

✨ Features:
• Create AR graffiti with your camera
• Discover art around you
• Join artist communities
• Share your creations

Download now: $_appUrl
''';

      await Share.share(
        shareText,
        subject: 'Join me on $_appName - AR Graffiti Revolution!',
      );
    } catch (e) {
      debugPrint('Error sharing app: $e');
      await Share.share('Check out $_appName - The AR Graffiti Revolution! $_appUrl');
    }
  }

  /// Share media file (photo/video)
  static Future<void> shareMediaFile({
    required String filePath,
    String? caption,
    String? subject,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: caption ?? 'Created with $_appName - AR Graffiti Revolution! $_appUrl',
        subject: subject ?? 'My $_appName Creation',
      );
    } catch (e) {
      debugPrint('Error sharing media file: $e');
      // Fallback to text share
      await Share.share(caption ?? 'Check out my creation on $_appName! $_appUrl');
    }
  }

  /// Share community
  static Future<void> shareCommunity({
    required String communityName,
    required String communityId,
    String? description,
    int? memberCount,
  }) async {
    try {
      final String shareText = '''
🌟 Join "$communityName" on $_appName!

${description != null ? '$description\n\n' : ''}${memberCount != null ? '👥 $memberCount members\n\n' : ''}Connect with fellow street artists and discover amazing AR graffiti!

Join now: $_appUrl/community/$communityId
Download $_appName: $_appUrl
''';

      await Share.share(
        shareText,
        subject: 'Join $communityName on $_appName',
      );
    } catch (e) {
      debugPrint('Error sharing community: $e');
      await Share.share('Join amazing artist communities on $_appName! $_appUrl');
    }
  }

  /// Share location/spot
  static Future<void> shareLocation({
    required String locationName,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      final String shareText = '''
📍 Amazing graffiti spot: $locationName

${description != null ? '$description\n\n' : ''}Coordinates: $latitude, $longitude

Discover AR graffiti at this location with $_appName!

Download $_appName: $_appUrl
''';

      await Share.share(
        shareText,
        subject: 'Check out this graffiti spot!',
      );
    } catch (e) {
      debugPrint('Error sharing location: $e');
      await Share.share('Check out this amazing graffiti spot on $_appName! $_appUrl');
    }
  }

  /// Download image from URL for sharing
  static Future<File?> _downloadImage(String imageUrl, String fileName) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName.jpg');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      debugPrint('Error downloading image for sharing: $e');
    }
    return null;
  }

  /// Share with specific apps
  static Future<void> shareToInstagram({
    required String filePath,
    String? caption,
  }) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: '${caption ?? 'Created with $_appName'} #graffiniti #arart #streetart',
      );
    } catch (e) {
      debugPrint('Error sharing to Instagram: $e');
      await shareMediaFile(filePath: filePath, caption: caption);
    }
  }

  /// Share to Twitter/X
  static Future<void> shareToTwitter({
    String? text,
    String? filePath,
  }) async {
    try {
      final twitterText = '${text ?? 'Check out my AR graffiti!'} #graffiniti #arart #streetart $_appUrl';

      if (filePath != null) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: twitterText,
        );
      } else {
        await Share.share(twitterText);
      }
    } catch (e) {
      debugPrint('Error sharing to Twitter: $e');
      if (filePath != null) {
        await shareMediaFile(filePath: filePath, caption: text);
      } else {
        await Share.share(text ?? 'Check out $_appName! $_appUrl');
      }
    }
  }

  /// Get share statistics (for analytics)
  static Map<String, dynamic> getShareAnalytics() {
    return {
      'app_name': _appName,
      'app_url': _appUrl,
      'share_timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.isIOS ? 'iOS' : 'Android',
    };
  }
}
