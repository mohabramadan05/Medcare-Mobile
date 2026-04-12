import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/services/biometric_service.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/appointments')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/shop')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/home'); break;
      case 1: context.go('/appointments'); break;
      case 2: context.go('/chat'); break;
      case 3: context.go('/shop'); break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);
    final l = AppLocalizations.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 0.8)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => _onTap(context, i),
          backgroundColor: AppTheme.surface,
          elevation: 0,
          animationDuration: const Duration(milliseconds: 300),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: l.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month_rounded),
              label: l.navAppointments,
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: const Icon(Icons.chat_bubble_rounded),
              label: l.navChat,
            ),
            NavigationDestination(
              icon: const Icon(Icons.shopping_bag_outlined),
              selectedIcon: const Icon(Icons.shopping_bag_rounded),
              label: l.navShop,
            ),
          ],
        ),
      ),
    );
  }
}

// Biometric toggle widget — used in home screen AppBar
class BiometricToggleButton extends StatefulWidget {
  const BiometricToggleButton({super.key});

  @override
  State<BiometricToggleButton> createState() => _BiometricToggleButtonState();
}

class _BiometricToggleButtonState extends State<BiometricToggleButton> {
  bool _available = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final available = await BiometricService.isAvailable();
    final enabled = available && await BiometricService.hasCredentials();
    if (mounted) setState(() { _available = available; _enabled = enabled; });
  }

  Future<void> _onTap() async {
    if (!_available) return;
    // Capture context-dependent objects BEFORE any await to avoid
    // "use_build_context_synchronously" / _dependents assertion errors.
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (_enabled) {
      // ── Disable flow ──────────────────────────────────────
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l.biometricTitle),
          content: Text(l.enableBiometricDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.disableBiometric),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await BiometricService.clearCredentials();
        await _refresh();
        messenger.showSnackBar(
          SnackBar(content: Text(l.biometricDisabled)),
        );
      }
    } else {
      // ── Enable flow — no dialog, straight to biometric scan ──
      try {
        final authenticated =
            await BiometricService.authenticate(l.biometricReason);
        if (!authenticated) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l.biometricFailed),
              backgroundColor: AppTheme.error,
            ),
          );
          return;
        }
        final refreshToken =
            Supabase.instance.client.auth.currentSession?.refreshToken;
        if (refreshToken == null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(l.biometricFailed),
              backgroundColor: AppTheme.error,
            ),
          );
          return;
        }
        await BiometricService.saveRefreshToken(refreshToken);
        await _refresh();
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.biometricEnabled),
            backgroundColor: AppTheme.healthGreen,
          ),
        );
      } catch (_) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.biometricFailed),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    return IconButton(
      tooltip: AppLocalizations.of(context).biometricTitle,
      onPressed: _onTap,
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _enabled ? Icons.fingerprint : Icons.fingerprint,
          color: _enabled ? Colors.greenAccent : Colors.white.withValues(alpha: 0.6),
          size: 18,
        ),
      ),
    );
  }
}

// Language toggle widget — used in home screen AppBar
class LangToggleButton extends ConsumerWidget {
  const LangToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';

    return GestureDetector(
      onTap: () {
        ref.read(localeProvider.notifier).state =
            isAr ? const Locale('en') : const Locale('ar');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Text(
          isAr ? 'EN' : 'ع',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
