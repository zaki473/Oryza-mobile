import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart'; // Sesuaikan dengan path login screen kamu

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Mengatur durasi animasi kemunculan logo & teks (1.5 detik)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    // Memulai animasi komponen visual
    _animationController.forward();

    // Menahan splash screen selama 3.5 detik, lalu pindah ke halaman Login
    Timer(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Gradasi mewah: Emerald Green gelap ke warna yang lebih dalam hampir hitam
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF064E3B), // Deep Emerald
              Color(0xFF022C22), // Ultra Dark Emerald
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Aksen Dekorasi Latar Belakang Elegan (Lingkaran abstrak tipis)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.015),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.03), width: 2),
                ),
              ),
            ),
            
            // Konten Utama dengan Animasi Fade-In
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Wadah Logo dengan Border Emas Tipis yang Mewah
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4), // Soft Gold border
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: const Text(
                      '🌾',
                      style: TextStyle(fontSize: 54),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Nama Aplikasi menggunakan Font Serif Eksklusif
                  Text(
                    'SmartOryza',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFEF3C7), // Amber / Warm White mewah
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Tagline Pendukung dengan font minimalis modern
                  Text(
                    'PREMIUM AGRI-AUTOMATION SYSTEM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981), // Emerald Mint cerah untuk kontras kontemporer
                      letterSpacing: 3.5,
                    ),
                  ),
                ],
              ),
            ),

            // Indikator Loading Minimalis di bagian bawah layar
            Positioned(
              bottom: 60,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 40,
                  height: 2,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    color: const Color(0xFFF59E0B), // Aksen progress bar berwarna emas
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}