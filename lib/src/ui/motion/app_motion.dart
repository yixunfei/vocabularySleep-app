import 'package:flutter/animation.dart';

class AppEasing {
  AppEasing._();

  static const Curve snappy = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve gentle = Curves.easeInOutQuad;
  static const Curve bounce = Curves.elasticOut;
  static const Curve quickBounce = Curves.easeOutBack;
  static const Curve physicsBased = Curves.fastOutSlowIn;
  static const Curve reveal = Curves.easeOutQuart;
  static const Curve conceal = Curves.easeInQuart;
  static const Curve inhale = Curves.easeInOutSine;
  static const Curve hold = Curves.easeInOutQuad;
  static const Curve exhale = Curves.easeInOutSine;
  static const Curve rest = Curves.easeOutQuad;
}

class AppDurations {
  AppDurations._();

  static const Duration instant = Duration(milliseconds: 80);
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration expand = Duration(milliseconds: 350);
  static const Duration pageTransition = Duration(milliseconds: 400);
  static const Duration emphasize = Duration(milliseconds: 450);
  static const Duration celebrate = Duration(milliseconds: 800);
  static const Duration slowPulse = Duration(milliseconds: 1500);
  static const Duration loop = Duration(milliseconds: 1000);
  static const Duration ambient = Duration(milliseconds: 5000);
  static const Duration strike = Duration(milliseconds: 700);
  static const Duration drop = Duration(milliseconds: 600);
  static const Duration shake = Duration(milliseconds: 500);
  static const Duration drag = Duration.zero;
  static const Duration fling = Duration(milliseconds: 400);
  static const Duration scale = Duration.zero;
}
