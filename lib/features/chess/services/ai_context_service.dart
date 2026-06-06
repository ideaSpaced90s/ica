import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/position_context.dart';

class AiContextService {
  PositionContext? _lastContext;
  PositionContext? get lastContext => _lastContext;

  void setLastContext(PositionContext context) {
    _lastContext = context;
  }
}

final aiContextServiceProvider = Provider((ref) => AiContextService());
