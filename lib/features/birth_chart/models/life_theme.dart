/// SPRINT-002 — Recurring life theme from chart synthesis.
library;

class LifeTheme {
  const LifeTheme({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final String body;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
      };

  factory LifeTheme.fromJson(Map<String, dynamic> json) {
    return LifeTheme(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}
