import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/models/lifetime_xp_state.dart';

class LifetimeXpRepository {
  static const _fileName = 'lifetime_xp_settings.json';

  Future<LifetimeXpState> loadLifetimeXp() async {
    final file = await _getFile();
    if (!await file.exists()) {
      return const LifetimeXpState();
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const LifetimeXpState();
      }

      final decoded = jsonDecode(raw);
      return LifetimeXpState.fromJson(Map<String, dynamic>.from(decoded));
    } catch (e) {
      return const LifetimeXpState();
    }
  }

  Future<void> saveLifetimeXp(LifetimeXpState state) async {
    final file = await _getFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(state.toJson()), flush: true);
  }

  Future<File> _getFile() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return File(p.join(supportDirectory.path, _fileName));
  }
}
