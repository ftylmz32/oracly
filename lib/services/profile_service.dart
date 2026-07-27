import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _nameKey = "profile_name";
  static const String _jobKey = "profile_job";
  static const String _interestsKey = "profile_interests";
  static const String _goalsKey = "profile_goals";


  Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _nameKey,
      name,
    );
  }


  Future<void> saveJob(String job) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _jobKey,
      job,
    );
  }


  Future<void> saveInterests(List<String> interests) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _interestsKey,
      interests,
    );
  }


  Future<void> saveGoals(List<String> goals) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _goalsKey,
      goals,
    );
  }


  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "name": prefs.getString(_nameKey) ?? "",
      "job": prefs.getString(_jobKey) ?? "",
      "interests":
          prefs.getStringList(_interestsKey) ?? [],
      "goals":
          prefs.getStringList(_goalsKey) ?? [],
    };
  }


  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_nameKey);
    await prefs.remove(_jobKey);
    await prefs.remove(_interestsKey);
    await prefs.remove(_goalsKey);
  }
}