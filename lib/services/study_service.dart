import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class StudyService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // 🎯 TARGETS
  Future<void> setDailyTarget(String uid, int minutes) async {
    await _db.child("users/$uid/dailyTarget").set(minutes);
  }

  Stream<int> dailyTargetStream(String uid) {
    return _db.child("users/$uid/dailyTarget").onValue.map(
          (event) => (event.snapshot.value ?? 30) as int,
    );
  }

  // 📝 SESSIONS
  Future<void> saveSession(String uid, int seconds, int currentTarget) async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final ref = _db.child("history/$uid/$date");
    
    final snap = await ref.get();
    int existingSeconds = 0;
    if (snap.exists) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      existingSeconds = data['seconds'] ?? 0;
    }

    await ref.set({
      'date': date,
      'seconds': existingSeconds + seconds,
      'targetMinutes': currentTarget,
    });
  }

  // 📊 STATS
  Stream<Map<String, int>> getWeeklyStatsUpdates(String uid) {
    return _db.child("history/$uid").onValue.map((event) {
      final Map<String, int> stats = {};
      if (event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final sessionData = Map<dynamic, dynamic>.from(value as Map);
          stats[key.toString()] = (sessionData['seconds'] ?? 0) as int;
        });
      }
      return stats;
    });
  }

  // Old methods kept for compatibility or removed if not needed
  Future<void> addMinutes(String uid, int minutes) async {
    final ref = _db.child("users/$uid/totalMinutes");
    final snap = await ref.get();
    final current = (snap.value ?? 0) as int;
    await ref.set(current + minutes);
  }

  Stream<int> totalMinutesStream(String uid) {
    return _db.child("users/$uid/totalMinutes").onValue.map(
          (event) => (event.snapshot.value ?? 0) as int,
    );
  }
}