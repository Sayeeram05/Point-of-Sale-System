import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:owner_ap/main.dart';

void main() {
  testWidgets('WOFL Shop Admin app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WOFLShopAdminApp());

    // Verify that our app loads with the welcome message.
    expect(find.text('Welcome to WOFL Shop Admin'), findsOneWidget);
    
    // Verify navigation items are present
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
  });
}
