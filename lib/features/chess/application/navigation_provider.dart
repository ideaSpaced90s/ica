import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'var_notifier.dart';

// Provides the current active mobile tab index.
final mobileNavIndexProvider = NotifierProvider<VarNotifier<int>, int>(() => VarNotifier(() => 0));

// Registry of page-specific back button overrides, keyed by tab/page index.
// Handlers return true if they handled the back event (preventing index 0 navigation),
// or false if they want the shell to execute default navigation to Dashboard.
final backButtonOverridesProvider = NotifierProvider<VarNotifier<Map<int, Future<bool> Function()>>, Map<int, Future<bool> Function()>>(() => VarNotifier(() => {}));
