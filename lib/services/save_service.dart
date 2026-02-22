import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'game_engine.dart';

class SaveService {
  static const String _boxName = 'tower_saves';
  static const String _saveKey = 'game_save';
  static const String _settingsKey = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Future<void> saveGame(GameEngine engine) async {
    final box = Hive.box(_boxName);
    final jsonStr = jsonEncode(engine.toJson());
    await box.put(_saveKey, jsonStr);
  }

  static Future<bool> loadGame(GameEngine engine) async {
    final box = Hive.box(_boxName);
    final jsonStr = box.get(_saveKey) as String?;
    if (jsonStr == null) return false;
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      engine.loadFromJson(json);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasSave() async {
    final box = Hive.box(_boxName);
    return box.containsKey(_saveKey);
  }

  static Future<void> deleteSave() async {
    final box = Hive.box(_boxName);
    await box.delete(_saveKey);
  }

  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_boxName);
    final settings = box.get(_settingsKey, defaultValue: '{}') as String;
    final map = jsonDecode(settings) as Map<String, dynamic>;
    map[key] = value;
    await box.put(_settingsKey, jsonEncode(map));
  }

  static Future<dynamic> getSetting(String key) async {
    final box = Hive.box(_boxName);
    final settings = box.get(_settingsKey, defaultValue: '{}') as String;
    final map = jsonDecode(settings) as Map<String, dynamic>;
    return map[key];
  }
}
