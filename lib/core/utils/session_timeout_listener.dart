import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poultry_accounting/core/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionTimeoutListener extends ConsumerStatefulWidget {
  final Widget child;

  const SessionTimeoutListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<SessionTimeoutListener> createState() => _SessionTimeoutListenerState();
}

class _SessionTimeoutListenerState extends ConsumerState<SessionTimeoutListener> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resetTimer() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt('session_timeout_minutes') ?? 10;
    _timer = Timer(Duration(minutes: minutes), _handleTimeout);
  }

  void _handleTimeout() {
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    if (isAuthenticated) {
      ref.read(authProvider.notifier).logout();
      
      // Optionally show a dialog or snackbar
      // But since we are likely at the root, we might need a global navigator key
      // or just let the app redirect to login via auth listener in main/home.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerUp: (_) => _resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
