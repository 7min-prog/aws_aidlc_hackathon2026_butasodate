class RecordSummary {
  final int todayCount;
  final int todayPoints;
  final String date;

  RecordSummary({required this.todayCount, required this.todayPoints, required this.date});

  factory RecordSummary.fromJson(Map<String, dynamic> json) => RecordSummary(
        todayCount: json['todayCount'] as int? ?? json['count'] as int? ?? 0,
        todayPoints: json['todayPoints'] as int? ?? json['points'] as int? ?? 0,
        date: json['date'] as String? ?? DateTime.now().toIso8601String().substring(0, 10),
      );

  Map<String, dynamic> toJson() => {
        'todayCount': todayCount,
        'todayPoints': todayPoints,
        'date': date,
      };

  bool get isToday => date == DateTime.now().toIso8601String().substring(0, 10);
}
