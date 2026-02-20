import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'login_admin_page.dart';
import 'scan_page.dart';

class Tpscan extends StatefulWidget {
  const Tpscan({super.key});

  @override
  State<Tpscan> createState() => _TpscanState();
}

class _TpscanState extends State<Tpscan> with TickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  bool loading = true;
  bool mulaiScan = false;
  bool sudahScan = false;
  bool _isPressed = false;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Jika mulaiScan true, tampilkan Kamera, jika false tampilkan UI Modern
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _homeUIModern(),
    );
  }

  Widget _homeUIModern() {
    return Stack(
      children: [
        // Background Decoration
        Center(
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF001FBF).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Header
              Column(
                children: [
                  Image.asset(
                    'assets/logo_bps.png',
                    width: 60,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.analytics,
                      size: 60,
                      color: Color(0xFF001FBF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'E-INVENTORY BPS MAMUJU',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Tombol Scan dengan Animasi Pulse
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 220 * (1 + (_pulseController.value * 0.3)),
                          height: 220 * (1 + (_pulseController.value * 0.3)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF60A5FA,
                            ).withOpacity(0.2 * (1 - _pulseController.value)),
                          ),
                        );
                      },
                    ),
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isPressed = true),
                      onTapUp: (_) => setState(() => _isPressed = false),
                      onTapCancel: () => setState(() => _isPressed = false),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanPage()),
                        );

                        if (result != null) {
                          print("Hasil Scan: $result");

                          // kalau mau simpan ke variable
                          setState(() {
                            sudahScan = true;
                            // misalnya simpan ke controller / variable
                          });
                        }
                      },

                      child: AnimatedScale(
                        scale: _isPressed ? 0.92 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            color: const Color(0xFF001FBF),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF001FBF).withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Colors.white,
                                size: 70,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'SCAN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Animasi Bounce Petunjuk
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_bounceAnimation.value),
                    child: Column(
                      children: const [
                        Text(
                          "Ketuk untuk memindai barang",
                          style: TextStyle(
                            color: Colors.black38,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              // Link Admin Login
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginAdminPage()),
                    );
                  },
                  child: const Text(
                    'Administrator Access',
                    style: TextStyle(
                      color: Colors.black26,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
