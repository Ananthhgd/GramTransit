import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/app/gramtransit_app.dart';

void main() {
  runApp(const ProviderScope(child: GramTransitApp()));
}
