import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../screens/login_screen.dart';
import '../services/firebase_service.dart';
import '../models/sensor_data.dart';
import '../models/log_entry.dart';
import '../widgets/stat_card.dart';
import '../widgets/siklus_widget.dart';
import 'log_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0;
  SensorData _data = SensorData.empty();
  int _ctrl = 0;
  String? _tanggalTanam;

  final List<FlSpot> _soilPts = [];
  final List<FlSpot> _waterPts = [];
  double _chartX = 0;

  StreamSubscription? _dataSub;
  StreamSubscription? _controlSub;
  StreamSubscription? _siklusSub;

  final _dummy = [
    {},
    {'soil': 62, 'water': 14.2, 'pir': 'Aman', 'mode': 'Otomatis'},
    {'soil': 78, 'water': 8.5, 'pir': 'Aman', 'mode': 'Irigasi'},
    {'soil': 0, 'water': 0.0, 'pir': 'Aman', 'mode': 'Offline'},
  ];

  final _lahanInfo = [
    {
      'nama': 'Sawah 1',
      'blok': 'Blok A',
      'status': 'Aktif',
      'color': AppTheme.brand500,
    },
    {
      'nama': 'Sawah 2',
      'blok': 'Blok B',
      'status': 'Standby',
      'color': Colors.orange,
    },
    {
      'nama': 'Sawah 3',
      'blok': 'Blok C',
      'status': 'Irigasi',
      'color': Colors.blue,
    },
    {
      'nama': 'Sawah 4',
      'blok': 'Blok D',
      'status': 'Offline',
      'color': Colors.grey,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    _dataSub = FirebaseService.latestDataStream.listen((d) {
      if (!mounted) return;
      setState(() {
        _data = d;
        if (_soilPts.length >= 15) {
          _soilPts.removeAt(0);
          _waterPts.removeAt(0);
        }
        _soilPts.add(FlSpot(_chartX, d.soil.toDouble()));
        _waterPts.add(FlSpot(_chartX, d.water));
        _chartX++;
      });
    });

    _controlSub = FirebaseService.controlStream.listen((v) {
      if (mounted) setState(() => _ctrl = v);
    });

    _siklusSub = FirebaseService.siklusStream.listen((v) {
      if (mounted) setState(() => _tanggalTanam = v);
    });
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _controlSub?.cancel();
    _siklusSub?.cancel();
    super.dispose();
  }

  int get _hariKe {
    if (_tanggalTanam == null) return 0;
    final tgl = DateTime.tryParse(_tanggalTanam!);
    return tgl == null ? 0 : DateTime.now().difference(tgl).inDays + 1;
  }

  SensorData get _display {
    if (_tab == 0) return _data;
    final d = _dummy[_tab];
    return SensorData(
      soil: d['soil'] as int,
      water: (d['water'] as num).toDouble(),
      pir: d['pir'] as String,
      mode: d['mode'] as String,
    );
  }

  Future<void> _setPintuAir(int value) async {
    try {
      await FirebaseService.setControlPintuAir(value);
    } catch (e) {
      debugPrint('Gagal set kontrol pintu air: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah mode irigasi: $e')),
      );
    }
  }

  void _doMulaiTanam() async {
    await FirebaseService.mulaiTanamBaru();
  }

  void _doReset() async {
    await FirebaseService.resetSiklusTanam();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGray,
      body: Column(
        children: [
          _navbar(),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.brand900,
              onRefresh: () async => setState(() {}),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const SizedBox(height: 20),
                    _lahanTabs(),
                    const SizedBox(height: 16),
                    if (_tab != 0) _dummyBanner(),
                    SiklusWidget(
                      hariKe: _hariKe,
                      tanggalTanam: _tanggalTanam,
                      onMulaiTanam: _doMulaiTanam,
                      onReset: _doReset,
                    ),
                    const SizedBox(height: 16),
                    _statCards(),
                    const SizedBox(height: 16),
                    _charts(),
                    const SizedBox(height: 16),
                    _recentLogs(),
                    const SizedBox(height: 16),
                    _viewAllBtn(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NAVBAR ──────────────────────────────────────────────────────────────
  Widget _navbar() => Container(
    color: Colors.white,
    child: SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFf1f5f9))),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.brand900,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🌾', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'SmartOryza',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.brand900,
              ),
            ),
            const Spacer(),
            
            GestureDetector(
              onTap: () async {
                final konfirmasi = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Keluar Aplikasi?'),
                    content: const Text('Apakah Anda yakin ingin keluar dari akun SmartOryza?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (konfirmasi == true) {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return; // Menggunakan mounted dari State untuk menghindari async gap error
                  
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 14,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Monitoring Lahan Padi',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade900,
        ),
      ),
      Text(
        'Sistem Otomasi Irigasi & Pengusir Hama',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      ),
    ],
  );

  // ── TABS LAHAN ───────────────────────────────────────────────────────────
  Widget _lahanTabs() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'PILIH LAHAN',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(4, (i) {
            final lahan = _lahanInfo[i];
            final active = _tab == i;
            return GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: active ? AppTheme.brand900 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? AppTheme.brand900 : Colors.grey.shade200,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppTheme.brand900.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 9,
                      color: active ? Colors.white60 : lahan['color'] as Color,
                    ),
                    const SizedBox(width: 9),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lahan['nama'] as String,
                          style: TextStyle(
                            color: active ? Colors.white : Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${lahan['blok']} — ${lahan['status']}',
                          style: TextStyle(
                            color: active ? Colors.white60 : Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    ],
  );

  // ── DUMMY BANNER ─────────────────────────────────────────────────────────
  Widget _dummyBanner() => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.amber.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.amber.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: Colors.amber.shade700, size: 17),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            'Data lahan ini belum terhubung ke perangkat. Menampilkan data simulasi.',
            style: TextStyle(
              color: Colors.amber.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  // ── STAT CARDS ───────────────────────────────────────────────────────────
  Widget _statCards() {
    final d = _display;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Kelembapan Tanah',
                value: '${d.soil}%',
                icon: Icons.water_drop_outlined,
                iconColor: Colors.blue,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: d.soil / 100,
                        backgroundColor: Colors.blue.shade50,
                        color: d.soil < 20 ? Colors.orange : Colors.blue,
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'Level Air',
                value: '${d.water.toStringAsFixed(1)} cm',
                icon: Icons.waves_outlined,
                iconColor: Colors.teal,
                subtitle: 'Pintu Irigasi',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _hamaCard(d)),
            const SizedBox(width: 12),
            Expanded(child: _irrigationCard()),
          ],
        ),
        const SizedBox(height: 12),
        _systemCard(d),
      ],
    );
  }

  Widget _hamaCard(SensorData d) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: d.isBahaya ? Colors.red.shade100 : Colors.grey.shade100,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATUS HAMA',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: d.isBahaya ? Colors.red : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              d.isBahaya ? 'BAHAYA' : 'AMAN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: d.isBahaya ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: d.isBahaya ? Colors.red.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            d.isBahaya ? '🤖 Scarecrow: Aktif' : '🤖 Scarecrow: Standby',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: d.isBahaya ? Colors.red.shade700 : Colors.grey.shade500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _irrigationCard() {
    final isManual = _ctrl != 0;
    final isTerbuka = _ctrl == 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column( // <--- SUDAH DIPERBAIKI (Titik "." sebelum child dihilangkan)
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IRIGASI',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isManual ? Colors.blue.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  isManual ? 'MANUAL' : 'OTOMATIS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isManual ? Colors.blue.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTerbuka ? 'TERBUKA' : 'TERTUTUP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isTerbuka ? Colors.blue.shade700 : Colors.grey.shade700,
            ),
          ),
          if (_tab == 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Auto', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                SizedBox(
                  height: 24,
                  child: Switch.adaptive(
                    value: isManual,
                    onChanged: (v) => _setPintuAir(v ? 2 : 0),
                    activeTrackColor: Colors.blue.withValues(alpha: 0.5),
                    activeThumbColor: Colors.blue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                Text('Manual', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
            ),
            if (isManual) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _miniBtn('BUKA', Colors.blue, () => _setPintuAir(1)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _miniBtn('TUTUP', Colors.red, () => _setPintuAir(2)),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _miniBtn(String label, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );

  Widget _systemCard(SensorData d) {
    final isManual = _ctrl != 0;
    final fase = _hariKe > 150
        ? '🌾 Siap Panen'
        : _hariKe > 120
            ? '⚠️ Pengeringan'
            : _tanggalTanam != null
                ? '🌱 Vegetatif'
                : 'Belum Tanam';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isManual ? Colors.blueGrey.shade800 : AppTheme.brand900,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Sistem',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isManual ? 'MANUAL' : 'OTOMATIS',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.microchip,
                    color: Colors.white54,
                    size: 12,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _tab == 0 ? 'ESP32 Aktif' : 'Tidak Terhubung',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  fase,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tanggalTanam != null ? 'Hari ke-$_hariKe' : 'Hari 0',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── CHARTS ───────────────────────────────────────────────────────────────
  Widget _charts() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grafik Real-Time',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          'Update otomatis tiap 1 detik',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 18),
        _chartRow(
          'Kelembapan Tanah (%)',
          Colors.blue,
          _soilPts,
          100,
          interval: 25,
        ),
        const SizedBox(height: 18),
        _chartRow(
          'Level Air (cm)',
          Colors.teal,
          _waterPts,
          400,
          interval: 50,
          isWaterChart: true,
        ),
      ],
    ),
  );

  Widget _chartRow(
    String label,
    Color color,
    List<FlSpot> pts,
    double maxY, {
    double? interval,
    bool isWaterChart = false,
  }) {
    final spots = pts.isEmpty ? [const FlSpot(0, 0)] : pts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.circle, color: color, size: 9),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRect(
          child: SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (v) {
                    if (isWaterChart) {
                      final val = v.toInt();
                      if (val != 0 &&
                          val != 50 &&
                          val != 100 &&
                          val != 200 &&
                          val != 300 &&
                          val != 400) {
                        return const FlLine(
                          color: Colors.transparent,
                          strokeWidth: 0,
                        );
                      }
                    }
                    return FlLine(color: Colors.grey.shade100, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: interval,
                      getTitlesWidget: (v, _) {
                        final val = v.toInt();
                        if (isWaterChart) {
                          if (val == 0 ||
                              val == 50 ||
                              val == 100 ||
                              val == 200 ||
                              val == 300 ||
                              val == 400) {
                            return Text(
                              val.toString(),
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        return Text(
                          val.toString(),
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.07),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── RECENT LOGS ──────────────────────────────────────────────────────────
  Widget _recentLogs() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktivitas Terbaru',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<LogEntry>>(
          stream: FirebaseService.recentLogsStream,
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada riwayat aktivitas...',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              );
            }
            return Column(
              children: snap.data!.map((log) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: log.isBahaya ? Colors.red.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(
                      color: log.isBahaya ? Colors.red : Colors.green,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.createdAt ?? 'Baru saja',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tanah: ${log.soil}% | Air: ${log.water.toStringAsFixed(1)}cm',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // <--- SUDAH DIPERBAIKI (Menggunakan log.status / fallback string kosong aman jika field kosong)
                    Text(
                      log.isBahaya ? 'Hama Terdeteksi' : 'Kondisi Stabil',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: log.isBahaya ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            );
          },
        ),
      ],
    ),
  );

  // ── VIEW ALL BUTTON ───────────────────────────────────────────────────────
  Widget _viewAllBtn() => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogScreen()),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.brand900,
        side: BorderSide(color: Colors.grey.shade200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Lihat Semua Riwayat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    ),
  );
}