import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/main_shell.dart';
import '../../features/dashboard/screens/home_screen.dart';
import '../../features/appointments/screens/appointments_screen.dart';
import '../../features/appointments/screens/add_appointment_screen.dart';
import '../../features/chat/screens/conversations_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
import '../../features/shop/screens/cart_screen.dart';
import '../../features/baby/screens/babies_list_screen.dart';
import '../../features/baby/screens/add_baby_screen.dart';
import '../../features/baby/screens/baby_detail_screen.dart';
import '../../features/baby/screens/baby_growth_screen.dart';
import '../../features/baby/screens/baby_vaccinations_screen.dart';
import '../../features/baby/screens/baby_routine_screen.dart';
import '../../features/baby/screens/baby_medicines_screen.dart';
import '../../features/baby/screens/baby_alerts_screen.dart';
import '../../features/baby/screens/baby_monitoring_screen.dart';
import '../../features/elder/screens/elder_monitoring_screen.dart';
import '../../features/elder/screens/elders_list_screen.dart';
import '../../features/elder/screens/add_elder_screen.dart';
import '../../features/elder/screens/elder_detail_screen.dart';
import '../../features/elder/screens/elder_vitals_screen.dart';
import '../../features/elder/screens/elder_medications_screen.dart';
import '../../features/elder/screens/elder_health_records_screen.dart';
import '../../features/elder/screens/elder_alerts_screen.dart';
import '../../features/elder/screens/elder_safety_info_screen.dart';
import '../../features/doctor/screens/doctors_list_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final loc = state.matchedLocation;
      final isSplash = loc == '/splash';
      final isAuthRoute = loc == '/login' || loc == '/register';
      if (isSplash) return null;
      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: '/appointments',
              builder: (_, __) => const AppointmentsScreen()),
          GoRoute(
              path: '/appointments/add',
              builder: (_, __) => const AddAppointmentScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const ConversationsScreen()),
          GoRoute(
            path: '/chat/:conversationId',
            builder: (_, state) => ChatScreen(
              conversationId: state.pathParameters['conversationId']!,
              doctorId: state.uri.queryParameters['doctorId'] ?? '',
              doctorName: Uri.decodeComponent(
                  state.uri.queryParameters['doctorName'] ?? 'Doctor'),
            ),
          ),
          GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),
          GoRoute(path: '/shop/cart', builder: (_, __) => const CartScreen()),
          GoRoute(path: '/doctors', builder: (_, __) => const DoctorsListScreen()),
        ],
      ),
      GoRoute(path: '/babies', builder: (_, __) => const BabiesListScreen()),
      GoRoute(path: '/babies/add', builder: (_, __) => const AddBabyScreen()),
      GoRoute(
        path: '/babies/:id',
        builder: (_, state) =>
            BabyDetailScreen(babyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/babies/:id/growth',
        builder: (_, state) =>
            BabyGrowthScreen(babyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/babies/:id/vaccinations',
        builder: (_, state) =>
            BabyVaccinationsScreen(babyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/babies/:id/routine',
        builder: (_, state) =>
            BabyRoutineScreen(babyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/babies/:id/medicines',
        builder: (_, state) =>
            BabyMedicinesScreen(babyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/babies/:id/alerts',
        builder: (_, state) =>
            BabyAlertsScreen(babyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/babies/:id/monitoring',
        builder: (_, state) => BabyMonitoringScreen(
          babyId: state.pathParameters['id']!,
          babyName: Uri.decodeComponent(
              state.uri.queryParameters['name'] ?? 'Baby'),
          patientCode: Uri.decodeComponent(
              state.uri.queryParameters['code'] ?? ''),
        ),
      ),
      GoRoute(path: '/elders', builder: (_, __) => const EldersListScreen()),
      GoRoute(path: '/elders/add', builder: (_, __) => const AddElderScreen()),
      GoRoute(
        path: '/elders/:id',
        builder: (_, state) =>
            ElderDetailScreen(elderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/elders/:id/vitals',
        builder: (_, state) =>
            ElderVitalsScreen(elderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/elders/:id/medications',
        builder: (_, state) =>
            ElderMedicationsScreen(elderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/elders/:id/health-records',
        builder: (_, state) =>
            ElderHealthRecordsScreen(elderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/elders/:id/alerts',
        builder: (_, state) =>
            ElderAlertsScreen(elderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/elders/:id/safety',
        builder: (_, state) =>
            ElderSafetyInfoScreen(elderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/elders/:id/monitoring',
        builder: (_, state) => ElderMonitoringScreen(
          elderId: state.pathParameters['id']!,
          elderName: Uri.decodeComponent(
              state.uri.queryParameters['name'] ?? 'Elder'),
          patientCode: Uri.decodeComponent(
              state.uri.queryParameters['code'] ?? ''),
        ),
      ),
    ],
  );
});
