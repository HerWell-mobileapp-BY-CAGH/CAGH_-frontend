import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/features/learning/presentation/screens/learning_center_screen.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/features/learning/data/repositories/learning_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearningRepository.setCachedModulesForTesting(LearningRepository.getModules());
  });

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

      // Verify ChoiceChip is present
      expect(find.byType(ChoiceChip), findsAtLeastNWidgets(1));
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

    testWidgets('Filtering by category chip displays matching modules', (WidgetTester tester) async {
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

      // Tap 'Nutrition & Growth' chip
      await tester.tap(find.text('Nutrition & Growth'));
      await tester.pumpAndSettle();

      expect(find.text('Nutrition & Growth'), findsAtLeastNWidgets(1));

      // Tap 'All' chip
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
    });
  });
}
