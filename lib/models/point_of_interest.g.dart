// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_of_interest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PointOfInterest _$PointOfInterestFromJson(Map<String, dynamic> json) =>
    PointOfInterest(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$PointOfInterestToJson(PointOfInterest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'category': instance.category,
      'imageUrl': instance.imageUrl,
      'isActive': instance.isActive,
    };
