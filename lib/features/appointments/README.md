# Appointments Module

## Overview
Manages scheduled healthcare services, midwife recurring availability, time slot generation, booking, rescheduling, and status lifecycle.

## Layers
- `data/`: Appointment models, Availability & TimeSlot serializers, remote data sources.
- `domain/`: Appointment entities, availability business rules, repository interfaces.
- `presentation/`: Booking calendar screens, slot selectors, status badges.
