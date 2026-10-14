import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/map_poi.dart';

final poiProvider = FutureProvider<List<MapPointOfInterest>>((ref) async {
  final String jsonString = await rootBundle.loadString('assets/data/gtav_map_pois.json');
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((json) => MapPointOfInterest.fromJson(json)).toList();
});
