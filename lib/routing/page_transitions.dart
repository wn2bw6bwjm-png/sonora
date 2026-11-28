import 'package:flutter/material.dart';

/// Custom page route with shared axis transition
class SharedAxisPageRoute<T> extends PageRoute<T> {
  final Widget child;
  final SharedAxisTransitionType transitionType;
  final Duration duration;

  SharedAxisPageRoute({
    required this.child,
    this.transitionType = SharedAxisTransitionType.horizontal,
    this.duration = const Duration(milliseconds: 350),
    super.settings,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return child;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );

    Widget transitionWidget;

    switch (transitionType) {
      case SharedAxisTransitionType.horizontal:
        transitionWidget = SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
        break;
      case SharedAxisTransitionType.vertical:
        transitionWidget = SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
        break;
      case SharedAxisTransitionType.scaled:
        transitionWidget = ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(opacity: curvedAnimation, child: child),
        );
        break;
    }

    // Add fade for secondary animation (exiting page)
    final fadeOut = FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInOutCubic,
        ),
      ),
      child: transitionWidget,
    );

    return fadeOut;
  }
}

enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

/// Hero dialog route for fullscreen player
class HeroDialogRoute<T> extends PageRoute<T> {
  final Widget child;
  final Duration duration;

  HeroDialogRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    super.settings,
  });

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.5);

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return child;
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: curvedAnimation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}

/// Navigation helper for shared axis transitions
class AppNavigation {
  static Future<T?> push<T>(BuildContext context, Widget page, {SharedAxisTransitionType type = SharedAxisTransitionType.horizontal}) {
    return Navigator.push(
      context,
      SharedAxisPageRoute<T>(child: page, transitionType: type),
    );
  }

  static Future<T?> pushReplacement<T, TO>(BuildContext context, Widget page, {SharedAxisTransitionType type = SharedAxisTransitionType.horizontal}) {
    return Navigator.pushReplacement(
      context,
      SharedAxisPageRoute<T>(child: page, transitionType: type),
    );
  }

  static Future<T?> pushHeroDialog<T>(BuildContext context, Widget page) {
    return Navigator.push(
      context,
      HeroDialogRoute<T>(child: page),
    );
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }
}