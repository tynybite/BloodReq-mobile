/// API Configuration for BloodReq Mobile App
/// Communication happens via Next.js API routes, NOT directly to Supabase
class ApiConfig {
  // Base URL - Points to your Next.js admin panel API
  // In development: http://localhost:3000/api
  // In production: https://your-domain.com/api
  static const String baseUrl = 'https://bloodreq.vercel.app/api';

  // static const String baseUrl = 'http://192.168.1.5:3000/api';

  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
}

/// API Endpoints for BloodReq Mobile App
class ApiEndpoints {
  // Auth Endpoints
  static const String signUp = '/auth/signup';
  static const String signUpPhone = '/auth/signup/phone';
  static const String signIn = '/auth/signin';
  static const String signInPhone = '/auth/signin/phone';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String oauth = '/auth/oauth';
  static const String refresh = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String signOut = '/auth/signout';

  // Profile Endpoints
  static const String profile = '/profile';
  static const String profileLocation = '/profile/location';
  static const String profileAvatar = '/profile/avatar';
  static const String profileAvailability = '/profile/availability';

  // Blood Request Endpoints
  static const String bloodRequests = '/blood-requests';
  static String bloodRequestDetail(String id) => '/blood-requests/$id';
  static String bloodRequestComplete(String id) =>
      '/blood-requests/$id/complete';
  static String bloodRequestDonate(String id) => '/blood-requests/$id/donate';

  // Blood Donation Endpoints
  static const String bloodDonations = '/blood-donations';
  static String donationMarkDonated(String id) =>
      '/blood-donations/$id/mark-donated';
  static String donationConfirm(String id) => '/blood-donations/$id/confirm';

  // Fundraiser Endpoints
  static const String fundraisers = '/fundraisers';
  static const String myFundraisers = '/fundraisers/my';
  static String fundraiserDetail(String id) => '/fundraisers/$id';
  static String fundraiserDonate(String id) => '/fundraisers/$id/donate';

  // Donation (Financial) Endpoints
  static const String donations = '/donations';
  static String donationDetail(String id) => '/donations/$id';

  // Location Endpoints
  static const String countries = '/locations/countries';
  static const String cities = '/locations/cities';
  static const String areas = '/locations/areas';
  static const String reverseGeocode = '/locations/reverse-geocode';

  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String notificationPreferences = '/notifications/preferences';
  static const String registerDevice = '/notifications/register';

  // Leaderboard Endpoints
  static const String leaderboard = '/leaderboard';

  // Config Endpoints
  static const String config = '/config';

  // Upload Endpoints
  static const String uploadImage = '/upload/image';
  static const String uploadDocument = '/upload/document';

  // Payment Endpoints
  static const String initiatePayment = '/payments/initiate';
  static const String verifyPayment = '/payments/verify';
}

/// App Constants
class AppConstants {
  // App Info
  static const String appName = 'BloodReq';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingKey = 'onboarding_complete';
  static const String notificationTokenKey = 'notification_token';

  // Default Values
  static const int defaultRadius = 50; // km
  static const int requestsPerPage = 20;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxDocumentSize = 10 * 1024 * 1024; // 10MB

  // Blood Groups
  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Urgency Levels
  static const List<String> urgencyLevels = ['critical', 'urgent', 'planned'];

  // Distance Options (km)
  static const List<int> distanceOptions = [5, 10, 25, 50, 100];

  // Badge Tiers
  static const Map<String, int> badgeTiers = {
    'bronze': 5,
    'silver': 15,
    'gold': 30,
    'platinum': 31,
  };
}

/// OneSignal Configuration (for push notifications)
class OneSignalConfig {
  static const String appId = '07aee5d5-8adf-40a3-95d0-1922cde3d23a';
}

/// Google Maps/Places Configuration
class GoogleMapsConfig {
  // Replace with your Google Places API key
  // Get one from: https://console.cloud.google.com/apis/credentials
  // Enable: Places API, Maps SDK for Android, Maps SDK for iOS
  static const String apiKey =
      'AIzaSyB08ZH4Hmd_Vuv7SclutgBiv40i16BASCA'; // Leave empty to disable hospital search suggestions
}
