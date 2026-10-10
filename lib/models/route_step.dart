import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Yürüme rotasının tek bir adımı (ör. "Sola dönün", ardından 120 m).
class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.icon,
    required this.location,
    this.isArrival = false,
  });

  /// Türkçe talimat, ör. "Sola dönün".
  final String instruction;

  /// Bu manevradan sonra yürünecek mesafe (bir sonraki adıma kadar).
  final double distanceMeters;

  final IconData icon;

  /// Manevranın yapılacağı nokta.
  final LatLng location;

  final bool isArrival;

  /// "120 m sonra sola dönün" gibi cümlelerde kullanmak için küçük harfle
  /// başlayan hali (Türkçe I/İ kuralına uygun).
  String get instructionLowerFirst {
    if (instruction.isEmpty) return instruction;
    final String first = instruction[0];
    final String lower = switch (first) {
      'I' => 'ı',
      'İ' => 'i',
      _ => first.toLowerCase(),
    };
    return lower + instruction.substring(1);
  }
}

/// OSRM manevra bilgisini (type + modifier) Türkçe talimata ve ikona çevirir.
/// OSRM talimat metni üretmez; sadece manevra türünü verir.
class OsrmInstructions {
  OsrmInstructions._();

  static String _turnPhrase(String? modifier) {
    switch (modifier) {
      case 'left':
        return 'Sola dönün';
      case 'right':
        return 'Sağa dönün';
      case 'slight left':
        return 'Hafif sola dönün';
      case 'slight right':
        return 'Hafif sağa dönün';
      case 'sharp left':
        return 'Keskin sola dönün';
      case 'sharp right':
        return 'Keskin sağa dönün';
      case 'uturn':
        return 'Geri dönün';
      default:
        return 'Düz devam edin';
    }
  }

  static IconData _turnIcon(String? modifier) {
    switch (modifier) {
      case 'left':
        return Icons.turn_left;
      case 'right':
        return Icons.turn_right;
      case 'slight left':
        return Icons.turn_slight_left;
      case 'slight right':
        return Icons.turn_slight_right;
      case 'sharp left':
        return Icons.turn_sharp_left;
      case 'sharp right':
        return Icons.turn_sharp_right;
      case 'uturn':
        return Icons.u_turn_left;
      default:
        return Icons.straight;
    }
  }

  /// [type]/[modifier]: OSRM `maneuver` alanları. [name]: yol/patika adı.
  static ({String text, IconData icon, bool isArrival}) describe({
    required String type,
    String? modifier,
    String? name,
    int? exit,
  }) {
    final String suffix = (name != null && name.trim().isNotEmpty)
        ? ' ($name)'
        : '';
    switch (type) {
      case 'depart':
        return (
          text: 'Yürümeye başlayın$suffix',
          icon: Icons.directions_walk,
          isArrival: false,
        );
      case 'arrive':
        final String side = switch (modifier) {
          'left' || 'slight left' || 'sharp left' => ', hedef solunuzda',
          'right' || 'slight right' || 'sharp right' => ', hedef sağınızda',
          _ => '',
        };
        return (
          text: 'Hedefinize ulaştınız$side',
          icon: Icons.flag,
          isArrival: true,
        );
      case 'roundabout':
      case 'rotary':
      case 'roundabout turn':
        final String exitText = exit != null
            ? '$exit. çıkıştan'
            : 'uygun çıkıştan';
        return (
          text: 'Döner kavşaktan $exitText çıkın$suffix',
          icon: Icons.roundabout_left,
          isArrival: false,
        );
      case 'fork':
        final bool left = modifier?.contains('left') ?? false;
        return (
          text: 'Yol ayrımında ${left ? 'soldan' : 'sağdan'} devam edin$suffix',
          icon: left ? Icons.fork_left : Icons.fork_right,
          isArrival: false,
        );
      default: // turn, end of road, continue, new name, merge, ...
        return (
          text: '${_turnPhrase(modifier)}$suffix',
          icon: _turnIcon(modifier),
          isArrival: false,
        );
    }
  }
}
