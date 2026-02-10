import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/main_shell.dart';
import '../../features/blood_requests/screens/blood_requests_screen.dart';
import '../../features/blood_requests/screens/create_request_screen.dart';
import '../../features/fundraisers/screens/create_fundraiser_screen.dart';
import '../../features/blood_requests/screens/request_detail_screen.dart';
import '../../features/blood_requests/screens/my_requests_screen.dart';
import '../../features/blood_requests/screens/my_donations_screen.dart';
import '../../features/fundraisers/screens/fundraisers_screen.dart';
import '../../features/fundraisers/screens/fundraiser_detail_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/verification/screens/verification_screen.dart';
import '../../features/legal/screens/terms_of_service_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/support/screens/support_home_screen.dart';
import '../../features/support/screens/create_ticket_screen.dart';
import '../../features/support/screens/ticket_chat_screen.dart';

class RouterService {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoading =
          authProvider.status == AuthStatus.initial ||
          authProvider.status == AuthStatus.loading;

      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/otp-verification';

      // Still loading, show splash
      if (isLoading && state.matchedLocation != '/') {
        return '/';
      }

      // Not authenticated and not on auth route
      if (!isAuthenticated &&
          !isAuthRoute &&
          !isLoading &&
          state.matchedLocation != '/') {
        return '/onboarding';
      }

      // Authenticated but on auth route
      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Splash/Loading
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

      // Auth Routes
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        builder: (context, state) {
          final email = state.extra as String;
          return OtpVerificationScreen(email: email);
        },
      ),

      // Main App Shell with Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/requests',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BloodRequestsScreen()),
          ),
          GoRoute(
            path: '/fundraisers',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FundraisersScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // Standalone Routes (outside shell)
      GoRoute(
        path: '/create-request',
        builder: (context, state) => const CreateRequestScreen(),
      ),
      GoRoute(
        path: '/request/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RequestDetailScreen(requestId: id);
        },
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportHomeScreen(),
      ),
      GoRoute(
        path: '/support/create',
        builder: (context, state) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: '/support/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TicketChatScreen(ticketId: id);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/fundraiser/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FundraiserDetailScreen(fundraiserId: id);
        },
      ),
      GoRoute(
        path: '/my-requests',
        builder: (context, state) => const MyRequestsScreen(),
      ),
      GoRoute(
        path: '/my-donations',
        builder: (context, state) => const MyDonationsScreen(),
      ),
      GoRoute(
        path: '/create-fundraiser',
        builder: (context, state) => const CreateFundraiserScreen(),
      ),
      GoRoute(
        path: '/create-fundraiser',
        builder: (context, state) => const CreateFundraiserScreen(),
      ),
      GoRoute(
        path: '/verify/:requestId',
        builder: (context, state) {
          final requestId = state.pathParameters['requestId']!;
          final isRequestor = state.extra as bool? ?? false;
          return VerificationScreen(
            requestId: requestId,
            isRequestor: isRequestor,
          );
        },
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
}
