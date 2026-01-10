# Cloudinary Setup Instructions

This guide will help you configure Cloudinary for image uploads in the Graffiniti app.

## Step 1: Create a Cloudinary Account

1. Go to [https://cloudinary.com](https://cloudinary.com)
2. Sign up for a free account
3. Verify your email address

## Step 2: Get Your Cloud Name

1. Login to your Cloudinary dashboard at [https://cloudinary.com/console](https://cloudinary.com/console)
2. On the dashboard, you'll see your **Cloud name** in the top section
3. Copy this cloud name (e.g., `dntncz9no`)

## Step 3: Create an Unsigned Upload Preset

1. In your Cloudinary console, go to **Settings** → **Upload**
2. Scroll down to **Upload presets** section
3. Click **Add upload preset**
4. Configure the preset:
   - **Upload preset name**: `graffiniti_uploads`
   - **Signing Mode**: Select **Unsigned**
   - **Use filename or externally defined Public ID**: Check this if you want to control file names
   - **Folder**: Set to `graffiniti` (optional, for organization)
   - **Access Mode**: Upload
   - **Resource Type**: Auto
   - **Allowed formats**: `jpg,jpeg,png,webp`
   - **Transformation**: Add any default transformations you want (optional)

5. Click **Save**

## Step 4: Update the Configuration

1. Open `lib/core/config/cloudinary_config.dart`
2. Update the following values:
   ```dart
   static const String cloudName = 'your_cloud_name_here'; // Replace with your actual cloud name
   static const String uploadPreset = 'graffiniti_uploads'; // Or your custom preset name
   ```

## Step 5: Test the Upload

1. Run the app
2. Go to Profile → Edit Profile
3. Try to upload a profile picture or banner image
4. Check your Cloudinary media library to see if the upload was successful

## Troubleshooting

### Upload Fails with 400 Bad Request
- Verify your cloud name is correct
- Ensure the upload preset exists and is set to "Unsigned"
- Check that the preset name in the config matches exactly

### Upload Fails with Timeout
- Check your internet connection
- Try with a smaller image file
- The app has 60-second timeout for uploads

### Images Don't Display
- Verify the returned URL from Cloudinary is accessible
- Check browser network tab for failed image requests
- Ensure images are set to public access in Cloudinary

## Optional: Configure Folders

For better organization, you can set up folder structure in your upload preset:
- Profile images: `profile_images/`
- Banner images: `banner_images/`
- Graffiti images: `graffiti_images/`

## Security Notes

- The current setup uses unsigned uploads for simplicity
- For production, consider implementing signed uploads for better security
- Monitor your Cloudinary usage to stay within free tier limits
- Consider setting up webhook notifications for upload events

## Free Tier Limits

Cloudinary free tier includes:
- 25 GB storage
- 25 GB bandwidth per month
- Up to 1,000 transformations per month

Monitor your usage in the Cloudinary console to avoid overages.