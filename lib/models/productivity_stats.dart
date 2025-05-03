class ProductivityStats {
  final double completionRate;
  final String mostProductiveDay;
  final String mostProductiveTime;
  final Map<String, int> categoryStats;
  final int streak;

  ProductivityStats({
    required this.completionRate,
    required this.mostProductiveDay,
    required this.mostProductiveTime,
    required this.categoryStats,
    required this.streak,
  });

  factory ProductivityStats.fromMap(Map<String, dynamic> map) {
    return ProductivityStats(
      completionRate: map['completionRate'] ?? 0.0,
      mostProductiveDay: map['mostProductiveDay'] ?? 'Unknown',
      mostProductiveTime: map['mostProductiveTime'] ?? 'Unknown',
      categoryStats: Map<String, int>.from(map['categoryStats'] ?? {}),
      streak: map['streak'] ?? 0,
    );
  }
}