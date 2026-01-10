class CloudinaryConfig {
  // Cloudinary credentials
  // IMPORTANT: Update these with your actual Cloudinary credentials
  // 1. Go to https://cloudinary.com/console
  // 2. Copy your cloud name from the dashboard
  // 3. Create an unsigned upload preset:
  //    - Go to Settings > Upload > Add upload preset
  //    - Set Signing Mode to "Unsigned"
  //    - Set Upload preset name to "graffiniti_uploads"
  //    - Configure folder structure and transformations as needed
  //    - Save the preset
  static const String cloudName = 'dntncz9no'; // Replace with your cloud name
  static const String uploadPreset = 'unsigned_preset'; // Replace with your upload preset name
  static const String apiKey = '163553321267567'; // Optional: Replace with actual API key for signed uploads
  static const String apiSecret = 'H1LqwBGnE5abgOxDirRxETDUvH4'; // Optional: Replace with actual API secret for signed uploads

  // Upload URL
  static const String uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  // Folders for different image types
  static const String profileImagesFolder = 'profile_images';
  static const String bannerImagesFolder = 'banner_images';
  static const String graffitiImagesFolder = 'graffiti_images';

  // Timeouts
  static const Duration uploadTimeout = Duration(seconds: 30);
  static const Duration downloadTimeout = Duration(seconds: 15);

  // Image optimization settings
  static const int profileImageSize = 300;
  static const int bannerImageWidth = 800;
  static const int bannerImageHeight = 200;
  static const String profileImageQuality = '80';
  static const String bannerImageQuality = '80';
  static const String defaultImageQuality = 'auto';
  static const String defaultImageFormat = 'auto';

  // Maximum file sizes (in bytes)
  static const int maxProfileImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxBannerImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxGraffitiImageSize = 15 * 1024 * 1024; // 15MB

  // Supported image formats
  static const List<String> supportedFormats = ['jpg', 'jpeg', 'png', 'webp'];

  // Default images
  static const String defaultProfileImage = 'https://res.cloudinary.com/$cloudName/image/upload/v1/defaults/default_profile.jpg';
  static const String defaultBannerImage = 'https://res.cloudinary.com/$cloudName/image/upload/v1/defaults/default_banner.jpg';
}
