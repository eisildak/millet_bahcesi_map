import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/map_service.dart';
import '../models/point_of_interest.dart';

class SearchWidget extends StatefulWidget {
  final VoidCallback onClose;

  const SearchWidget({
    super.key,
    required this.onClose,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Otomatik odaklan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapService>(
      builder: (context, mapService, child) {
        return Card(
          elevation: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Arama input alanı
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'İlgi noktalarında ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              mapService.searchPOIs('');
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    mapService.searchPOIs(value);
                  },
                ),
              ),

              // Arama sonuçları
              if (mapService.filteredPois.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: mapService.filteredPois.length,
                    itemBuilder: (context, index) {
                      final poi = mapService.filteredPois[index];
                      return _buildPOIListItem(context, poi, mapService);
                    },
                  ),
                ),

              // Sonuç bulunamadı mesajı
              if (mapService.filteredPois.isEmpty && _searchController.text.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sonuç bulunamadı',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

              // Kategori filtreleri
              if (_searchController.text.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kategoriler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _buildCategoryChips(context, mapService),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPOIListItem(BuildContext context, PointOfInterest poi, MapService mapService) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getCategoryColor(poi.category),
        child: Icon(
          _getCategoryIcon(poi.category),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        poi.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${poi.category} • ${poi.description}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.directions),
      onTap: () {
        mapService.selectPOI(poi);
        widget.onClose();
      },
    );
  }

  List<Widget> _buildCategoryChips(BuildContext context, MapService mapService) {
    final categories = mapService.pois
        .map((poi) => poi.category)
        .toSet()
        .toList();

    return categories.map((category) {
      return FilterChip(
        label: Text(category),
        avatar: Icon(
          _getCategoryIcon(category),
          size: 18,
          color: _getCategoryColor(category),
        ),
        onSelected: (selected) {
          if (selected) {
            mapService.searchPOIs(category);
            _searchController.text = category;
          }
        },
        backgroundColor: Colors.grey[100],
        selectedColor: _getCategoryColor(category).withOpacity(0.2),
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    // Tüm kategoriler için mavi renk
    switch (category.toLowerCase()) {
      case 'wc':
        return const Color(0xFF3252a8);
      case 'kapı':
        return const Color(0xFF3252a8);
      case 'üniversite':
        return const Color(0xFF3252a8);
      default:
        return const Color(0xFF3252a8);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wc':
        return Icons.wc;
      case 'kapı':
        return Icons.login;
      case 'üniversite':
        return Icons.school;
      default:
        return Icons.location_on;
    }
  }
}