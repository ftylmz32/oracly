/// OR-001 — Theme Foundation: corner radius and stroke tokens.
library;

import 'package:flutter/material.dart';

/// Corner radius tokens for cards, sheets, and controls.
abstract final class AppRadius {
  AppRadius._();

  static const double xsValue = 8;
  static const double smValue = 12;
  static const double mdValue = 16;
  static const double lgValue = 20;
  static const double xlValue = 28;
  static const double glassValue = 32;
  static const double xxlValue = 36;
  static const double pillValue = 999;

  static const BorderRadius xs = BorderRadius.all(Radius.circular(xsValue));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(smValue));
  static const BorderRadius md = BorderRadius.all(Radius.circular(mdValue));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(lgValue));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(xlValue));
  static const BorderRadius glass = BorderRadius.all(Radius.circular(glassValue));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(xxlValue));
  static const BorderRadius round =
      BorderRadius.all(Radius.circular(pillValue));
}

/// Border width tokens — avoids raw stroke values in widgets.
abstract final class AppBorderWidth {
  AppBorderWidth._();

  static const double hairline = 0.5;
  static const double thin = 1;
  static const double gold = 1.5;
  static const double emphasis = 2;
}
