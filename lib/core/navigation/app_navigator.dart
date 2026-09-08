import 'package:flutter/material.dart';

/// A global navigator key so [AuthProvider] can unwind any pushed route
/// (e.g. a zone's device-detail screen) back to the app root when a 401
/// forces a logout, otherwise the pushed route would keep rendering over
/// a session that no longer exists.
class AppNavigator {
  const AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static void popToRoot() {
    key.currentState?.popUntil((route) => route.isFirst);
  }
}
