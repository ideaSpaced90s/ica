import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/models/assignment_state.dart';

class AssignmentRepository {
  static const _fileName = 'assignment_settings.json';

  Future<AssignmentState> loadAssignment() async {
    final file = await _getFile();
    if (!await file.exists()) {
      return AssignmentState(lastResetDate: DateTime.now().subtract(const Duration(days: 1)));
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return AssignmentState(lastResetDate: DateTime.now().subtract(const Duration(days: 1)));
      }

      final decoded = jsonDecode(raw);
      return AssignmentState.fromJson(Map<String, dynamic>.from(decoded));
    } catch (e) {
      return AssignmentState(lastResetDate: DateTime.now().subtract(const Duration(days: 1)));
    }
  }

  Future<void> saveAssignment(AssignmentState state) async {
    final file = await _getFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(state.toJson()), flush: true);
  }

  Future<File> _getFile() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return File(p.join(supportDirectory.path, _fileName));
  }
}
