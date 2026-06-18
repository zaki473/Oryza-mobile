import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sensor_data.dart';
import '../models/log_entry.dart';

class FirebaseService {
  static final _db = FirebaseDatabase.instance;
  static final _auth = FirebaseAuth.instance; 

  // Fungsi login menggunakan Firebase Auth
  static Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }
  
  static Stream<SensorData> get latestDataStream =>
      _db.ref('iot/latest').onValue.map((e) {
        final data = e.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null) return SensorData.empty();
        return SensorData.fromMap(Map<String, dynamic>.from(data));
      });

  static Stream<int> get controlStream =>
      _db.ref('iot/control/pintu_air').onValue.map((e) =>
          (e.snapshot.value as int?) ?? 0);

  static Stream<String?> get siklusStream =>
      _db.ref('iot/siklus/tanggal_tanam').onValue.map((e) =>
          e.snapshot.value as String?);

  static Stream<List<LogEntry>> get recentLogsStream =>
      _db.ref('iot/logs').orderByKey().limitToLast(6).onValue.map((e) {
        final data = e.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null) return [];
        return data.values
            .map((v) => LogEntry.fromMap(Map<String, dynamic>.from(v)))
            .toList()
            .reversed
            .toList();
      });

  static Stream<List<LogEntry>> get allLogsStream =>
      _db.ref('iot/logs').orderByKey().limitToLast(500).onValue.map((e) {
        final data = e.snapshot.value as Map<dynamic, dynamic>?;
        if (data == null) return [];
        return data.values
            .map((v) => LogEntry.fromMap(Map<String, dynamic>.from(v)))
            .toList()
            .reversed
            .toList();
      });

  static Future<void> setControlPintuAir(int value) =>
      _db.ref('iot/control/pintu_air').set(value);

  static Future<void> mulaiTanamBaru() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return _db.ref('iot/siklus/tanggal_tanam').set(today);
  }

  static Future<void> resetSiklusTanam() =>
      _db.ref('iot/siklus/tanggal_tanam').remove();
}