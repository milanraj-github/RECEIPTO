import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipto/core/widgets/shell_layout.dart';
import 'package:receipto/features/auth/presentation/screens/splash_screen.dart';
import 'package:receipto/features/auth/presentation/screens/login_screen.dart';
import 'package:receipto/features/auth/presentation/screens/signup_screen.dart';
import 'package:receipto/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:receipto/features/scan/presentation/screens/scan_screen.dart';
import 'package:receipto/features/receipts/presentation/screens/receipts_screen.dart';
import 'package:receipto/features/receipts/presentation/screens/receipt_details_screen.dart';
import 'package:receipto/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:receipto/features/profile/presentation/screens/profile_screen.dart';
import 'package:receipto/features/receipts/presentation/screens/recycle_bin_screen.dart';
import 'package:receipto/features/warranty/presentation/screens/warranty_details_screen.dart';
import 'package:receipto/features/warranty/presentation/screens/warranty_tracker_screen.dart';
import 'package:receipto/features/warranty/presentation/screens/upcoming_warranties_screen.dart';
import 'package:receipto/features/notifications/presentation/screens/notification_screen.dart';
import 'package:receipto/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:receipto/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:receipto/core/services/firebase_auth_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _dashboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'dashboardTab');
final GlobalKey<NavigatorState> _scanNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'scanTab');
final GlobalKey<NavigatorState> _receiptsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'receiptsTab');
final GlobalKey<NavigatorState> _analyticsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'analyticsTab');
final GlobalKey<NavigatorState> _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profileTab');

// Custom dynamic fade transition page builder
CustomTransitionPage<T> buildPageWithFadeTransition<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

// Custom slide-up transition page builder for details screen
CustomTransitionPage<T> buildPageWithSlideTransition<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 0.08); // Subtle slide-up
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    redirect: (context, state) {
      final user = authService.currentUser;
      final matched = state.matchedLocation;
      
      final isLoggingIn = matched == '/login' || matched == '/signup' || matched == '/splash';

      if (user == null) {
        // If not logged in and trying to access protected routes, redirect to login
        if (!isLoggingIn) {
          return '/login';
        }
      } else {
        // If logged in and on auth pages, redirect to dashboard
        if (isLoggingIn) {
          return '/dashboard';
        }
      }
      return null;
    },
    routes: <RouteBase>[
      // Splash Route with Fade transition
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => buildPageWithFadeTransition(
          state: state,
          child: const SplashScreen(),
        ),
      ),
      


      
      // Login Route with Fade transition
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => buildPageWithFadeTransition(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      
      // Signup Route with Fade transition
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => buildPageWithFadeTransition(
          state: state,
          child: const SignupScreen(),
        ),
      ),

      // Notifications Center Route
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const NotificationScreen(),
        ),
      ),

      // Premium Warranty Tracker Route
      GoRoute(
        path: '/warranties',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const WarrantyTrackerScreen(),
        ),
      ),

      // Upcoming Warranty Reminders Route
      GoRoute(
        path: '/warranties/upcoming',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final idsString = state.uri.queryParameters['ids'] ?? '';
          final ids = idsString.split(',').where((id) => id.isNotEmpty).toList();
          return buildPageWithSlideTransition(
            state: state,
            child: UpcomingWarrantiesScreen(warrantyIds: ids),
          );
        },
      ),

      // AI Warranty Assistant Route
      GoRoute(
        path: '/ai-assistant',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => buildPageWithSlideTransition(
          state: state,
          child: const AIAssistantScreen(),
        ),
      ),
      
      // Persistent Tab bar navigation shell
      StatefulShellRoute.indexedStack(
        builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
          return ShellLayout(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          // Tab 0: Dashboard
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) => buildPageWithFadeTransition(
                  state: state,
                  child: const DashboardScreen(),
                ),
              ),
            ],
          ),
          
          // Tab 1: Receipts List & Details
          StatefulShellBranch(
            navigatorKey: _receiptsNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/receipts',
                pageBuilder: (context, state) => buildPageWithFadeTransition(
                  state: state,
                  child: const ReceiptsScreen(),
                ),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'details/:id',
                    parentNavigatorKey: _rootNavigatorKey, // Overlay shell navigation bar on detail push
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return buildPageWithSlideTransition(
                        state: state,
                        child: ReceiptDetailsScreen(receiptId: id),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'warranty/:warrantyId',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final warrantyId = state.pathParameters['warrantyId'] ?? '';
                      return buildPageWithSlideTransition(
                        state: state,
                        child: WarrantyDetailsScreen(warrantyId: warrantyId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Tab 2: Scan (Center)
          StatefulShellBranch(
            navigatorKey: _scanNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/scan',
                pageBuilder: (context, state) => buildPageWithFadeTransition(
                  state: state,
                  child: const ScanScreen(),
                ),
              ),
            ],
          ),
          
          // Tab 3: Analytics
          StatefulShellBranch(
            navigatorKey: _analyticsNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/analytics',
                pageBuilder: (context, state) => buildPageWithFadeTransition(
                  state: state,
                  child: const AnalyticsScreen(),
                ),
              ),
            ],
          ),
          
          // Tab 4: Profile
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => buildPageWithFadeTransition(
                  state: state,
                  child: const ProfileScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'recycle-bin',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => buildPageWithSlideTransition(
                      state: state,
                      child: const RecycleBinScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'notification-settings',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => buildPageWithSlideTransition(
                      state: state,
                      child: const NotificationSettingsScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
