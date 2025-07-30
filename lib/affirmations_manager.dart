import 'package:shared_preferences/shared_preferences.dart';

class AffirmationsManager {
  static const _prefsKey = 'user_affirmations';

  List<String> _affirmations = [];

  List<String> get affirmations => _affirmations;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _affirmations = prefs.getStringList(_prefsKey) ?? [];
  }

  Future<void> add(String affirmation) async {
    _affirmations.add(affirmation);
    await _save();
  }

  Future<void> delete(int index) async {
    _affirmations.removeAt(index);
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _affirmations);
  }
}
