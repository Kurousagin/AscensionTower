import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tower_ascension/widgets/event_toast.dart';
import 'game_engine.dart';

class SaveService {
  static const String _boxName = 'tower_saves';

  static Future<void> saveGame(GameEngine engine, String slot) async {
    final box = Hive.box(_boxName);
    final jsonStr = jsonEncode(engine.toJson());
    await box.put('game_save_$slot', jsonStr);
  }

  static Future<bool> loadGame(GameEngine engine, String slot) async {
    final box = Hive.box(_boxName);
    final jsonStr = box.get('game_save_$slot') as String?;
    if (jsonStr == null) return false;
try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      engine.loadFromJson(json);
      engine.migrateOldSave(engine.citadel);
      // Limpa toasts e filas de eventos do save anterior
      ToastController().clear();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasSave(String slot) async {
    final box = Hive.box(_boxName);
    return box.containsKey('game_save_$slot');
  }

  static Future<void> deleteSave(String slot) async {
    final box = Hive.box(_boxName);
    await box.delete('game_save_$slot');
  }

  static List<String> listSlots() {
    final box = Hive.box(_boxName);
    return box.keys
        .where((k) => k.toString().startsWith('game_save_'))
        .map((k) => k.toString().replaceFirst('game_save_', ''))
        .toList();
  }
}
