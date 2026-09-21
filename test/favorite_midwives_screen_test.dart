import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/features/profile/presentation/favorite_midwives_screen.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

void main() {
  group('FavoriteMidwivesScreen Tests', () {
    testWidgets('Renders FavoriteMidwivesScreen cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FavoriteMidwivesScreen(),
        ),
      );

      // Verify loading or empty state widget
      expect(find.byType(FavoriteMidwivesScreen), findsOneWidget);
    });
  });
}
