import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../games/gtav/fixtures.dart';
import '../../sdk/models/guide_article.dart';

final guidesProvider = FutureProvider<List<GuideArticle>>((ref) async {
  try {
    final guidesStr = await rootBundle.loadString('assets/data/gtav_guides.json');
    final guidesJson = json.decode(guidesStr) as List<dynamic>;
    final guides = guidesJson
        .map((e) => GuideArticle.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    if (guides.isNotEmpty) {
      return guides;
    }
    return GTAVFixtures.guides;
  } catch (e) {
    return GTAVFixtures.guides;
  }
});

final selectedGuideCategoryProvider = StateProvider<String?>((ref) => null);

final filteredGuidesProvider = Provider<AsyncValue<List<GuideArticle>>>((ref) {
  final guidesAsync = ref.watch(guidesProvider);
  final selectedCategory = ref.watch(selectedGuideCategoryProvider);

  return guidesAsync.whenData((guides) {
    if (selectedCategory == null || selectedCategory.isEmpty || selectedCategory.toLowerCase() == 'all') {
      return guides;
    }
    return guides
        .where((guide) => guide.category.toLowerCase() == selectedCategory.toLowerCase())
        .toList();
  });
});
