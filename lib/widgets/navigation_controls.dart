import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/map_service.dart';

class NavigationControls extends StatelessWidget {
  const NavigationControls({super.key});

  static const Color _brand = Color(0xFF3252a8);

  static String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  /// Navigasyonu sonlandıran düğme (Durdur / Bitir): belirgin olsun diye
  /// kırmızı çerçeveli.
  Widget _endButton(
    BuildContext context,
    MapService mapService, {
    required String label,
    required IconData icon,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _stop(context, mapService),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red[700],
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.red[700]!, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Konum takibi durdurulmaz: navigasyon bitince de mavi nokta canlı kalır.
  void _stop(BuildContext context, MapService mapService) {
    mapService.stopNavigation();
  }

  Widget _buildProgress(BuildContext context, MapService mapService) {
    if (mapService.hasArrived) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.flag, color: Colors.green[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hedefe ulaştınız',
                style: TextStyle(
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _endButton(
              context,
              mapService,
              label: 'Bitir',
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      );
    }

    final int percent = (mapService.routeProgress * 100).round();
    final next = mapService.nextStep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (next != null) ...[
          Row(
            children: [
              Icon(next.icon, color: _brand, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  next.isArrival
                      ? '${_formatDistance(mapService.distanceToNextStepMeters)} sonra hedefinize ulaşırsınız'
                      : '${_formatDistance(mapService.distanceToNextStepMeters)} sonra ${next.instructionLowerFirst}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: mapService.routeProgress,
            minHeight: 8,
            backgroundColor: _brand.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(_brand),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '%$percent tamamlandı',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const Spacer(),
            Text(
              '${_formatDistance(mapService.routeRemainingMeters)} kaldı'
              ' · ~${mapService.routeRemainingMinutes} dk',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        if (mapService.isFallbackRoute) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Yürüme rotası alınamadı, kuş uçuşu mesafe gösteriliyor',
                  style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapService>(
      builder: (context, mapService, child) {
        if (!mapService.isNavigating) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Navigasyon başlığı
                Row(
                  children: [
                    const Icon(
                      Icons.directions_walk,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Yürüyerek',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            mapService.selectedPoi?.name ?? 'Hedefe',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Hedefe varınca yalnızca alttaki "Bitir" kalır.
                    if (!mapService.hasArrived)
                      _endButton(
                        context,
                        mapService,
                        label: 'Durdur',
                        icon: Icons.stop_circle_outlined,
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // İlerleme çubuğu + kalan mesafe/süre
                _buildProgress(context, mapService),

                const SizedBox(height: 12),

                // Navigasyon butonları
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigasyon talimatları
                          _showNavigationInstructions(context, mapService);
                        },
                        icon: const Icon(Icons.list),
                        label: const Text('Talimatlar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3252a8),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Hedefe odaklan
                          if (mapService.selectedPoi != null) {
                            mapService.selectPOI(mapService.selectedPoi!);
                          }
                        },
                        icon: const Icon(Icons.center_focus_strong),
                        label: const Text('Hedefe Git'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3252a8),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNavigationInstructions(
    BuildContext context,
    MapService mapService,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                const Icon(Icons.directions, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${mapService.selectedPoi?.name ?? 'Hedefe'} Yol Tarifi',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Yol tarifi adımları (örnek)
            // Uzun rotalarda taşmasın diye kaydırılabilir liste.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _buildNavigationSteps(context, mapService),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tamam butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Tamam'),
              ),
            ),

            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNavigationSteps(
    BuildContext context,
    MapService mapService,
  ) {
    final steps = mapService.routeSteps;
    if (steps.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Rota adımları hazırlanıyor...'),
        ),
      ];
    }
    final next = mapService.nextStep;
    return steps.map((step) {
      final bool isNext = identical(step, next);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isNext ? _brand : _brand.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                step.icon,
                color: isNext ? Colors.white : _brand,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.instruction,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (!step.isArrival && step.distanceMeters > 0)
                    Text(
                      'ardından ${_formatDistance(step.distanceMeters)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
