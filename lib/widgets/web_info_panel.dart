import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WebInfoPanel extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  
  const WebInfoPanel({
    super.key,
    this.isMobile = false,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12.0 : isTablet ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NNY Logo
            Center(
              child: Image.asset(
                'assets/icons/nny_logo.png',
                height: isMobile ? 60 : isTablet ? 80 : 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.school, size: 120);
                },
              ),
            ),
            
            SizedBox(height: isMobile ? 12 : isTablet ? 18 : 24),
            
            // Üniversite adı
            Text(
              'NUH NACI YAZGAN ÜNİVERSİTESİ',
              style: TextStyle(
                fontSize: isMobile ? 14 : isTablet ? 16 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isMobile ? 4 : 8),
            
            Text(
              'Bilgisayar Programcılığı',
              style: TextStyle(
                fontSize: isMobile ? 12 : isTablet ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isMobile ? 16 : isTablet ? 24 : 32),
            
            // Proje bilgileri
            Text(
              isMobile ? 'KAYSERI MİLLET BAHÇESİ\nHARİTA UYGULAMASI' : 'KAYSERI MİLLET BAHÇESİ\nİNTERAKTİF HARİTA',
              style: TextStyle(
                fontSize: isMobile ? 16 : isTablet ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isMobile ? 12 : isTablet ? 18 : 24),
            
            // Geliştirici bilgileri
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geliştiren',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Erol IŞILDAK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Bilgisayar Programcılığı Öğrencisi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Teknik bilgiler - Mobile'da gizle
            if (!isMobile) ...[
              Container(
                padding: EdgeInsets.all(isTablet ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teknolojiler',
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: isTablet ? 8 : 12),
                    const _TechItem(icon: Icons.phone_android, text: 'Flutter Framework'),
                    const _TechItem(icon: Icons.map, text: 'Google Maps API'),
                    const _TechItem(icon: Icons.directions, text: 'Google Directions API'),
                    const _TechItem(icon: Icons.location_on, text: 'GPS Navigasyon'),
                    const _TechItem(icon: Icons.wb_sunny, text: 'Gerçek Zamanlı Konum'),
                  ],
                ),
              ),
              
              SizedBox(height: isTablet ? 18 : 24),
            ],
            
            // Özellikler - Mobile'da kompakt
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : isTablet ? 14 : 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Özellikler',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : isTablet ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : isTablet ? 8 : 12),
                  const _FeatureItem('19 İlgi Noktası (POI)'),
                  if (!isMobile) ...[
                    const _FeatureItem('Sesli Navigasyon'),
                    const _FeatureItem('Gerçek Zamanlı Konum Takibi'),
                    const _FeatureItem('WC ve Giriş Kapıları'),
                    const _FeatureItem('Üniversite Kampüsü'),
                  ],
                  const _FeatureItem('Yürüyüş Rotaları'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Mobil uygulama indirme
            const Text(
              'Mobil Uygulamayı İndir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Mobil Uygulama - Tek Kurulum Sayfası
            _DownloadCard(
              title: 'Mobil Uygulama',
              subtitle: 'Android & iOS - Tek Tıkla Kurulum',
              icon: Icons.smartphone,
              color: Colors.purple,
              onTap: () => _launchURL('https://eisildak.github.io/millet_bahcesi_map/ios_install.html'),
            ),
            
            const SizedBox(height: 32),
            
            // İletişim bilgileri
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'İletişim',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ContactItem(
                    icon: Icons.email,
                    text: 'erol.isildak@hotmail.com',
                    onTap: () => _launchURL('mailto:erol.isildak@hotmail.com'),
                  ),
                  _ContactItem(
                    icon: Icons.phone,
                    text: '+90 553 572 77 76',
                    onTap: () => _launchURL('tel:+905535727776'),
                  ),
                  _ContactItem(
                    icon: Icons.business,
                    text: 'LinkedIn Profili',
                    onTap: () => _launchURL('https://www.linkedin.com/in/erol-isildak-softwaretester/'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Footer
            const Divider(),
            const SizedBox(height: 16),
            
            const Center(
              child: Text(
                '© 2024 Nuh Naci Yazgan Üniversitesi\nBilgisayar Programcılığı',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }
}

class _TechItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TechItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DownloadCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.download, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}