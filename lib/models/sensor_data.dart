class SensorData {
  final int soil;
  final double water;
  final String pir;
  final String mode;

  const SensorData({
    required this.soil,
    required this.water,
    required this.pir,
    required this.mode,
  });

  factory SensorData.empty() =>
      const SensorData(soil: 0, water: 0.0, pir: 'Aman', mode: 'Otomatis');

  factory SensorData.fromMap(Map<String, dynamic> map) => SensorData(
        soil:  (map['soil']  as num?)?.toInt()    ?? 0,
        water: (map['water'] as num?)?.toDouble() ?? 0.0,
        pir:   (map['pir']   as String?)          ?? 'Aman',
        mode:  (map['mode']  as String?)          ?? 'Otomatis',
      );

  bool get isBahaya => pir.toLowerCase() == 'bahaya';
}