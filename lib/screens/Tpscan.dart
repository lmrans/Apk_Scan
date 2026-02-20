import 'package:flutter/material.dart';
import 'login_admin_page.dart'; // Sesuaikan dengan nama file Anda
import 'scan_page.dart';

class Tpscan extends StatefulWidget {
  const Tpscan({super.key});

  @override
  State<Tpscan> createState() => _TpscanState();
}

class _TpscanState extends State<Tpscan> with TickerProviderStateMixin {
  bool _isPressed = false;

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Animasi Denyut (Pulse) untuk background tombol
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Animasi Fade dan Bounce untuk petunjuk (hint)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Background putih bersih sesuai gambar
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // 1. HEADER (Logo dan Teks minimalis sesuai gambar)
            _buildHeaderAsli(),

            const Spacer(),

            // 2. TOMBOL SCAN DENGAN ANIMASI
            _buildAnimatedScanButton(),

            const SizedBox(height: 40),

            // 3. PETUNJUK ANIMASI
            _buildAnimatedHint(),

            const Spacer(),

            // 4. FOOTER (Administrator Access)
            _buildAdminLinkAsli(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET EXTRACTS
  // ===========================================================================

  Widget _buildHeaderAsli() {
    return Column(
      children: [
        Image.asset(
          'assets/logo_bps.png', 
          width: 60,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.analytics, size: 60, color: Color(0xFF001FBF)),
        ),
        const SizedBox(height: 16),
        const Text(
          'E-INVENTORY BPS MAMUJU',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedScanButton() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Efek Pulse (Lingkaran Berdenyut)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 200 * (1 + (_pulseController.value * 0.5)),
                height: 200 * (1 + (_pulseController.value * 0.5)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF60A5FA).withOpacity(0.25 * (1 - _pulseController.value)),
                ),
              );
            },
          ),

          // Tombol Scan Interaktif (Biru solid)
          GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: _handleScanAction,
            child: AnimatedScale(
              scale: _isPressed ? 0.90 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: Container(
                width: 195,
                height: 195,
                decoration: BoxDecoration(
                  color: const Color(0xFF001FBF), 
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF001FBF).withOpacity(0.35),
                      blurRadius: 35,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 72,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'SCAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHint() {
    return FadeTransition(
      opacity: _fadeController,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_bounceAnimation.value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                // Mengembalikan icon panah ke atas yang sempat hilang di kode Anda
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.black26,
                  size: 28,
                ),
                SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminLinkAsli() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      // MENGGUNAKAN TextButton.icon UNTUK MENAMBAHKAN ICON
      child: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginAdminPage()),
          );
        },
        icon: const Icon(
          Icons.admin_panel_settings_rounded, // Icon admin minimalis
          color: Colors.black26, 
          size: 16, // Ukuran disesuaikan agar sejajar dengan font
        ),
        label: const Text(
          'Administrator Access',
          style: TextStyle(
            color: Colors.black26,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _handleScanAction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );

    if (result != null) {
      print("Hasil Scan: $result");
    }
  }
}