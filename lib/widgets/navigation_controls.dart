import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/map_service.dart';

class NavigationControls extends StatelessWidget {
  const NavigationControls({super.key});

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
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
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
                    TextButton(
                      onPressed: () {
                        mapService.stopNavigation();
                      },
                      child: const Text('Durdur'),
                    ),
                  ],
                ),

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

  void _showNavigationInstructions(BuildContext context, MapService mapService) {
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
            ..._buildNavigationSteps(context, mapService),

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

  List<Widget> _buildNavigationSteps(BuildContext context, MapService mapService) {
    // Gerçek uygulamada bu adımlar Google Directions API'den gelecek
    final steps = [
      {
        'instruction': 'Mevcut konumunuzdan başlayın',
        'distance': '0 m',
        'icon': Icons.my_location,
      },
      {
        'instruction': 'Ana yoldan güneye doğru yürüyün',
        'distance': '150 m',
        'icon': Icons.straight,
      },
      {
        'instruction': 'Sola dönün ve yeşil alana girin',
        'distance': '75 m',
        'icon': Icons.turn_left,
      },
      {
        'instruction': '${mapService.selectedPoi?.name ?? 'Hedefiniz'} sağ tarafınızda',
        'distance': '25 m',
        'icon': Icons.place,
      },
    ];

    return steps.map((step) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                step['icon'] as IconData,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['instruction'] as String,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    step['distance'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
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