
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get navigator => navigatorKey.currentState!;

  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigator.pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> navigateToReplace(String routeName, {Object? arguments}) {
    return navigator.pushReplacementNamed(routeName, arguments: arguments);
  }

  Future<dynamic> navigateToAndClearStack(String routeName, {Object? arguments}) {
    return navigator.pushNamedAndRemoveUntil(
      routeName, 
      (Route<dynamic> route) => false, 
      arguments: arguments
    );
  }

  void goBack({dynamic result}) {
    return navigator.pop(result);
  }

  bool canGoBack() {
    return navigator.canPop();
  }
}

final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService();
});
