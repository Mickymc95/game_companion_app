import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/models/wiki_item.dart';
import 'package:game_companion_sdk/ui/widgets/wiki_item_thumbnail.dart';

void main() {
  testWidgets('WikiItemThumbnail renders correct icon and badge for vehicle', (WidgetTester tester) async {
    final vehicleItem = WikiItem(
      id: 'v_adder',
      title: 'Adder',
      category: 'Vehicles',
      stats: {'Speed': 0.86},
      description: 'Supercar',
      thumbnailUrl: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WikiItemThumbnail(item: vehicleItem),
        ),
      ),
    );

    // Speed icon should be displayed for Adder (Supercar)
    expect(find.byIcon(Icons.speed), findsWidgets);
  });

  testWidgets('WikiItemThumbnail renders correct icon and badge for weapon', (WidgetTester tester) async {
    final weaponItem = WikiItem(
      id: 'w_carbine_rifle',
      title: 'Carbine Rifle',
      category: 'Weapons',
      stats: {'Damage': 0.7},
      description: 'Assault Rifle',
      thumbnailUrl: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WikiItemThumbnail(item: weaponItem),
        ),
      ),
    );

    // Track changes icon should be displayed for Carbine Rifle
    expect(find.byIcon(Icons.track_changes), findsWidgets);
  });
}

