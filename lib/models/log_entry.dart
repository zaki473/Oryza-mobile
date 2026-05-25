class LogEntry {
  final String? createdAt;
  final int soil;
  final double water;
  final String pir;

  const LogEntry({this.createdAt, required this.soil, required this.water, required this.pir});

  factory LogEntry.fromMap(Map<String, dynamic> map) => LogEntry(
        createdAt: map['created_at']?.toString(),
        soil:  (map['soil']  as num?)?.toInt()    ?? 0,
        water: (map['water'] as num?)?.toDouble() ?? 0.0,
        pir:   (map['pir']   as String?)          ?? 'Aman',
      );

  bool get isBahaya => pir.toLowerCase() == 'bahaya';

  bool isInPeriod(String filter) {
    if (filter == 'semua') return true;
    if (createdAt == null) return false;
    final d = DateTime.tryParse(createdAt!.replaceFirst(' ', 'T'));
    if (d == null) return false;
    final now = DateTime.now();
    switch (filter) {
      case 'hari':
        return d.day == now.day && d.month == now.month && d.year == now.year;
      case 'minggu':
        final start = now.subtract(Duration(days: now.weekday - 1));
        return d.isAfter(DateTime(start.year, start.month, start.day));
      case 'bulan':
        return d.month == now.month && d.year == now.year;
      case 'tahun':
        return d.year == now.year;
      default:
        return true;
    }
  }
}