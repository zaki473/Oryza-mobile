import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

class SiklusWidget extends StatelessWidget {
  final int hariKe;
  final String? tanggalTanam;
  final VoidCallback onMulaiTanam;
  final VoidCallback onReset;

  const SiklusWidget({
    super.key,
    required this.hariKe,
    required this.tanggalTanam,
    required this.onMulaiTanam,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final belumMulai = tanggalTanam == null;

    String faseLabel; Color faseColor;
    if (belumMulai)         { faseLabel = 'Belum Mulai';       faseColor = Colors.grey; }
    else if (hariKe <= 120) { faseLabel = '🌱 Vegetatif';      faseColor = Colors.green; }
    else if (hariKe <= 150) { faseLabel = '⚠️ Pengeringan';    faseColor = Colors.orange; }
    else                    { faseLabel = '🌾 Siap Panen!';    faseColor = Colors.red; }

    String estimasiPanen = '-';
    if (tanggalTanam != null) {
      final tgl = DateTime.tryParse(tanggalTanam!);
      if (tgl != null) {
        estimasiPanen = DateFormat('d MMMM yyyy', 'id_ID')
            .format(tgl.add(const Duration(days: 180)));
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.calendar_today, size: 15, color: Colors.grey.shade500),
                  const SizedBox(width: 7),
                  Text('Siklus Tanam Padi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800)),
                ]),
                const SizedBox(height: 3),
                Text(
                  belumMulai ? 'Belum ada siklus aktif (Hari 0)' : 'Hari ke-$hariKe | Panen: $estimasiPanen',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: faseColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: faseColor.withValues(alpha: 0.3)),
              ),
              child: Text(faseLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                      color: HSLColor.fromColor(faseColor).withLightness(0.3).toColor())),
            ),
          ]),

          const SizedBox(height: 18),

          // Progress bar berlapis
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(children: [
              Container(height: 10, color: Colors.grey.shade100),
              if (!belumMulai)
                FractionallySizedBox(
                  widthFactor: (hariKe.clamp(0, 120) / 180),
                  child: Container(height: 10, color: AppTheme.brand500),
                ),
              if (!belumMulai && hariKe > 120)
                FractionallySizedBox(
                  widthFactor: (hariKe.clamp(0, 150) / 180),
                  child: Container(height: 10, color: Colors.amber.shade400),
                ),
              if (!belumMulai && hariKe > 150)
                FractionallySizedBox(
                  widthFactor: (hariKe.clamp(0, 180) / 180),
                  child: Container(height: 10, color: Colors.red.shade400),
                ),
            ]),
          ),

          const SizedBox(height: 10),

          // Timeline labels
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _lbl('Mulai\nH1',         !belumMulai && hariKe >= 1,   false),
            _lbl('Vegetatif\n& Gen.', !belumMulai && hariKe >= 20,  false),
            _lbl('Stop Irigasi\nH120',!belumMulai && hariKe >= 120, true),
            _lbl('Panen\nH180',       !belumMulai && hariKe >= 180, false),
          ]),

          // Alert pengeringan
          if (!belumMulai && hariKe >= 120 && hariKe <= 150) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade100)),
              child: Row(children: [
                const Text('🌊', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Fase pengeringan! Pastikan saluran pembuangan air terbuka.',
                  style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w500),
                )),
              ]),
            ),
          ],

          const SizedBox(height: 16),

          // Buttons
          Row(children: [
            if (belumMulai)
              Expanded(child: _btn('Mulai Tanam Baru', AppTheme.brand500, Colors.white, onMulaiTanam))
            else ...[
              Expanded(child: _btn('Tanam Baru', AppTheme.brand500, Colors.white, onMulaiTanam)),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: 13, color: Colors.red),
                label: const Text('Reset', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  Widget _lbl(String text, bool active, bool warn) => Flexible(
    child: Text(text,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold,
          color: active ? (warn ? Colors.orange.shade800 : AppTheme.brand900) : Colors.grey.shade400)),
  );

  Widget _btn(String label, Color bg, Color fg, VoidCallback onTap) =>
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg, foregroundColor: fg, elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
}