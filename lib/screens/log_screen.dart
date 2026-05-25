import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/log_entry.dart';
import '../services/firebase_service.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});
  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  String _filter = 'semua';
  int _page = 0;
  static const _perPage = 15;
  List<LogEntry> _all = [];

  final _filters = [
    {'key': 'hari',   'label': 'Hari Ini'},
    {'key': 'minggu', 'label': 'Minggu'},
    {'key': 'bulan',  'label': 'Bulan'},
    {'key': 'tahun',  'label': 'Tahun'},
    {'key': 'semua',  'label': 'Semua'},
  ];

  List<LogEntry> get _filtered => _all.where((e) => e.isInPeriod(_filter)).toList();
  int get _totalPages => (_filtered.length / _perPage).ceil().clamp(1, 99999);
  List<LogEntry> get _pageItems {
    final start = _page * _perPage;
    final end = (start + _perPage).clamp(0, _filtered.length);
    return start >= _filtered.length ? [] : _filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log Aktivitas',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brand900)),
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: StreamBuilder<List<LogEntry>>(
        stream: FirebaseService.allLogsStream,
        builder: (context, snap) {
          if (snap.hasData) _all = snap.data!;
          if (snap.connectionState == ConnectionState.waiting && _all.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(children: [
            // Filter bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final active = _filter == f['key'];
                    return GestureDetector(
                      onTap: () => setState(() { _filter = f['key']!; _page = 0; }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? AppTheme.brand900 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: active ? AppTheme.brand900 : Colors.grey.shade200),
                        ),
                        child: Text(f['label']!,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: active ? Colors.white : Colors.grey.shade700)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Divider(color: Colors.grey.shade100, height: 1),

            // List
            Expanded(
              child: _filtered.isEmpty
                  ? Center(child: Text('Tidak ada data.', style: TextStyle(color: Colors.grey.shade400)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pageItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _row(_pageItems[i], _page * _perPage + i + 1),
                    ),
            ),

            // Pagination
            if (_filtered.isNotEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Text(
                    '${_page * _perPage + 1}–${(_page * _perPage + _pageItems.length)} dari ${_filtered.length}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  _pgBtn(Icons.chevron_left, _page > 0, () => setState(() => _page--)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.brand900, borderRadius: BorderRadius.circular(8)),
                    child: Text('${_page + 1}/$_totalPages',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  _pgBtn(Icons.chevron_right, _page < _totalPages - 1, () => setState(() => _page++)),
                ]),
              ),
          ]);
        },
      ),
    );
  }

  Widget _row(LogEntry log, int num) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: log.isBahaya ? Colors.red.shade100 : Colors.grey.shade100),
    ),
    child: Row(children: [
      Text('$num', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(log.createdAt ?? '—',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ),
      _chip('💧${log.soil}%', Colors.blue),
      const SizedBox(width: 5),
      _chip('🌊${log.water.toStringAsFixed(1)}cm', Colors.teal),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: log.isBahaya ? Colors.red.shade100 : Colors.green.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(log.isBahaya ? 'Bahaya' : 'Aman',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                color: log.isBahaya ? Colors.red.shade700 : Colors.green.shade700)),
      ),
    ]),
  );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
  );

  Widget _pgBtn(IconData icon, bool enabled, VoidCallback onTap) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Icon(icon, size: 18, color: enabled ? Colors.grey.shade700 : Colors.grey.shade300),
    ),
  );
}