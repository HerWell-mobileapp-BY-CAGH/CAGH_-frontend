import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/features/learning/presentation/screens/learning_center_screen.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

void main() {
  group('LearningCenterScreen Redesign Tests', () {
    testWidgets('Renders User side LearningCenterScreen with hero banner and module cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: LearningCenterScreen(isMidwife: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify User Hero Banner header
      expect(find.text('CERTIFIED HEALTH GUIDES'), findsOneWidget);
      expect(find.text('Empower Your Maternal Health'), findsOneWidget);

      // Verify Category Chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Nutrition & Growth'), findsOneWidget);
      expect(find.text('Prevention & Safety'), findsOneWidget);

      // Verify Search TextField
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Renders Midwife side LearningCenterScreen with professional clinical header', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: LearningCenterScreen(isMidwife: true),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Midwife Hero Banner header
      expect(find.text('CLINICAL LEARNING HUB'), findsOneWidget);
      expect(find.text('Midwife Knowledge & Clinical Hub'), findsOneWidget);
      expect(find.text('Clinical Reference'), findsAtLeastNWidgets(1));
    });

    testWidgets('Filtering by search query displays matching module or empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: LearningCenterScreen(isMidwife: false),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Type non-matching search string
      await tester.enterText(find.byType(TextField), 'NonExistentTopicQuery123');
      await tester.pumpAndSettle();

      expect(find.text('No learning modules found'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);

      // Tap Reset Filters
      await tester.tap(find.text('Reset Filters'));
      await tester.pumpAndSettle();

      expect(find.text('No learning modules found'), findsNothing);
    });
  });
}
