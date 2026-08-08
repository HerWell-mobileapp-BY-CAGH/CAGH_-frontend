# Chat System Module

## Overview
Provides direct real-time communication between users and verified midwives using Django Channels WebSockets. Features chat requests, acceptance/rejection flow, text messages, image/PDF attachments, and voice notes.

## Layers
- `data/`: ChatRoom, Message, and Attachment models, WebSocket client manager.
- `domain/`: Chat room state & request acceptance rules.
- `presentation/`: Chat list, message room screen, voice note recorder, file picker.
