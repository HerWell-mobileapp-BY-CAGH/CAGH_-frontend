# Virtual Consultation Module

## Overview
Enables remote healthcare consultations via Voice Sessions (and Video Sessions in future releases). Includes session management & real-time call status tracking.

## Layers
- `data/`: VoiceSession & VideoSession models/webRTC signaling endpoints.
- `domain/`: Call state machine & session quality tracking.
- `presentation/`: Voice call UI, call controls, session timer overlay.
