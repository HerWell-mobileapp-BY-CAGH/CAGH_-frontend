import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/consult_hub_components.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

void main() {
  group('User Consultation Hub - Upcoming Chat Icon Tests', () {
    final futureDate = DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10);
    final upcomingAppointment = Appointment(
      appointmentId: 'apt-101',
      userId: 'user-001',
      midwifeId: 'midwife-999',
      midwifeName: 'Sarah Jenkins',
      date: futureDate,
      startTime: '10:00',
      endTime: '11:00',
      appointmentType: 'VIRTUAL_VOICE',
      status: AppointmentStatus.confirmed,
    );

    final pendingAppointment = Appointment(
      appointmentId: 'apt-102',
      userId: 'user-001',
      midwifeId: 'midwife-999',
      midwifeName: 'Sarah Jenkins',
      date: futureDate,
      startTime: '14:00',
      endTime: '15:00',
      appointmentType: 'VIRTUAL_VOICE',
      status: AppointmentStatus.pending,
    );

    testWidgets('Upcoming consultation card displays message icon and triggers onChat callback when tapped', (WidgetTester tester) async {
      bool chatTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return buildAppointmentCard(
                  context,
                  upcomingAppointment,
                  onCardTap: () {},
                  onJoinCall: () {},
                  onReschedule: () {},
                  onCancel: () {},
                  onViewDetails: () {},
                  onChat: () {
                    chatTapped = true;
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the chat icon button
      final chatIconFinder = find.byIcon(Icons.chat_bubble_outline_rounded);
      expect(chatIconFinder, findsOneWidget);

      // Tap the chat icon button
      await tester.tap(chatIconFinder);
      await tester.pump();

      // Verify callback triggered
      expect(chatTapped, isTrue);
    });

    testWidgets('Pending consultation card does NOT display message chat icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return buildAppointmentCard(
                  context,
                  pendingAppointment,
                  onCardTap: () {},
                  onJoinCall: () {},
                  onReschedule: () {},
                  onCancel: () {},
                  onViewDetails: () {},
                  onChat: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure chat icon is not displayed for pending status
      final chatIconFinder = find.byIcon(Icons.chat_bubble_outline_rounded);
      expect(chatIconFinder, findsNothing);
    });
  });
}
