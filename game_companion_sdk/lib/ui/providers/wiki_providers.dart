import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sdk/models/wiki_item.dart';

final wikiItemsProvider = FutureProvider<List<WikiItem>>((ref) async {
  final List<WikiItem> allItems = [];

  try {
    final vehiclesStr = await rootBundle.loadString('assets/data/gtav_vehicles.json');
    final vehiclesJson = json.decode(vehiclesStr) as List<dynamic>;
    allItems.addAll(vehiclesJson.map((e) => WikiItem.fromJson(e as Map<String, dynamic>)));
  } catch (e) {
    // File not found or error parsing
  }

  try {
    final weaponsStr = await rootBundle.loadString('assets/data/gtav_weapons.json');
    final weaponsJson = json.decode(weaponsStr) as List<dynamic>;
    allItems.addAll(weaponsJson.map((e) => WikiItem.fromJson(e as Map<String, dynamic>)));
  } catch (e) {
    // File not found or error parsing
  }

  return allItems;
});
