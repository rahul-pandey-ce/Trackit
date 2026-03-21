class StudySession {
  final String date; // YYYY-MM-DD
  final int seconds;
  final int targetMinutes;

  StudySession({
    required this.date,
    required this.seconds,
    required this.targetMinutes,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'seconds': seconds,
    'targetMinutes': targetMinutes,
  };

  factory StudySession.fromJson(Map<dynamic, dynamic> json) {
    return StudySession(
      date: json['date'] ?? '',
      seconds: json['seconds'] ?? 0,
      targetMinutes: json['targetMinutes'] ?? 30,
    );
  }
}
