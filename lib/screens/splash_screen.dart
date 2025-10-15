import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Fade animasyon controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Scale animasyon controller  
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Animasyonları tanımla
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // Animasyonları başlat
    _startAnimations();
  }

  void _startAnimations() async {
    // Logo animasyonları
    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    
    // 5 saniye bekle ve ana ekrana geç
    await Future.delayed(const Duration(milliseconds: 5000));
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/map');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Ana içerik alanı
            Expanded(
              flex: 8,
              child: AnimatedBuilder(
                animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // NNY Üniversitesi Logosu
                          Center(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    'assets/icons/nny_university_logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback logo yüklenemezse
                                      return Image.asset(
                                        'assets/icons/nny_logo.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          // Her ikisi de yüklenemezse varsayılan simge
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF1e3a5f),
                                                  Color(0xFF3252a8),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'NNY',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Alt metin
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Column(
                                children: [
                                  const Text(
                                    'Kayseri Millet Bahçesi',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3252a8),
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Navigasyon Rehberi',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF1e3a5f),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF3252a8),
                                          Color(0xFF1e3a5f),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF3252a8).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      '✨ Nuh Naci Yazgan Üniversitesi ile\nGeleceğinizi Şekillendirin ✨',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        height: 1.4,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Alt kısım - Copyright
            Expanded(
              flex: 2,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Center(
                      child: Text(
                        'Her hakkı saklıdır. © 2025',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// NNY logosundaki dağları çizmek için custom painter
class MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Türkuaz renkli dağlar (NNY logosuna uygun)
    final mountainPaint = Paint()
      ..color = const Color(0xFF00bcd4)
      ..style = PaintingStyle.fill;

    // Ana dağ silüeti
    final mountainPath = Path()
      ..moveTo(5, size.height - 2)
      ..lineTo(size.width * 0.25, size.height * 0.3)
      ..lineTo(size.width * 0.4, size.height * 0.6)
      ..lineTo(size.width * 0.6, size.height * 0.2)
      ..lineTo(size.width * 0.75, size.height * 0.5)
      ..lineTo(size.width - 5, size.height - 2)
      ..close();

    canvas.drawPath(mountainPath, mountainPaint);

    // İkinci katman dağlar (daha açık)
    final secondPaint = Paint()
      ..color = const Color(0xFF4dd0e1)
      ..style = PaintingStyle.fill;

    final secondPath = Path()
      ..moveTo(10, size.height - 2)
      ..lineTo(size.width * 0.3, size.height * 0.4)
      ..lineTo(size.width * 0.5, size.height * 0.7)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width - 10, size.height - 2)
      ..close();

    canvas.drawPath(secondPath, secondPaint);

    // Alt çizgi (NNY logosundaki gibi)
    final linePaint = Paint()
      ..color = const Color(0xFF1e3a5f)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(5, size.height - 1),
      Offset(size.width - 5, size.height - 1),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Çember etrafında yazı yazmak için custom painter
class CircularTextPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    
    // Üst kısım - "NUH NACİ YAZGAN ÜNİVERSİTESİ"
    _drawTextOnCircle(
      canvas, 
      'NUH NACİ YAZGAN ÜNİVERSİTESİ', 
      center, 
      radius, 
      -math.pi / 2, 
      Colors.white70,
      10,
    );
    
    // Alt kısım - "KAYSERİ"
    _drawTextOnCircle(
      canvas, 
      'KAYSERİ', 
      center, 
      radius, 
      math.pi / 2, 
      Colors.white70,
      12,
    );
  }

  void _drawTextOnCircle(Canvas canvas, String text, Offset center, double radius, 
      double startAngle, Color color, double fontSize) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < text.length; i++) {
      textPainter.text = TextSpan(
        text: text[i],
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();

      final angle = startAngle + (i * 0.25);
      final x = center.dx + radius * math.cos(angle) - textPainter.width / 2;
      final y = center.dy + radius * math.sin(angle) - textPainter.height / 2;

      canvas.save();
      canvas.translate(x + textPainter.width / 2, y + textPainter.height / 2);
      canvas.rotate(angle + math.pi / 2);
      canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}