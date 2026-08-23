# CAGH Frontend App — HerWell Mobile Application

Frontend mobile application for CAGH Adolescent Girls Healthcare (HerWell). Built to interface with the CAGH Backend API to provide seamless healthcare access, telehealth consultations, and educational resources for adolescent girls.

## Architecture & Core Modules

The application is structured into modular feature-based domains:

*   **Authentication & Onboarding** — Multi-factor registration (Email/Phone), OTP verification flows, and user profile creation (Patients, Midwives).
*   **Common & Localization** — Multi-language support (English & Amharic), reusable UI components, and global state management.
*   **Appointments** — UI flows for booking, scheduling, and managing healthcare appointments.
*   **Consultations** — Telehealth video/audio consultation interfaces and medical record viewing.
*   **Real-time Chat** — Real-time messaging interfaces leveraging WebSockets for instant communication between users and providers.
*   **AI Assistant** — Interactive chat interface for AI-driven adolescent health guidance and Q&A.
*   **Learning Center** — Categorized feeds for health articles, educational videos, and resources.
*   **Notifications** — In-app notification center and push notification handling.
*   **Reviews & Feedback** — Interfaces for rating healthcare providers and submitting feedback.

## Technology Stack

| Component | Technology |
| :--- | :--- |
| **Framework** | React Native / Expo (or Flutter) *(Update accordingly)* |
| **Language** | TypeScript (or Dart) *(Update accordingly)* |
| **State Management** | Redux Toolkit / Zustand (or Provider/Riverpod) *(Update accordingly)* |
| **Navigation** | React Navigation (or GoRouter) |
| **API Client** | Axios / RTK Query (or Dio) |
| **Real-time** | Socket.io-client / WebSocket |
| **Styling** | TailwindCSS / Styled Components |

## Getting Started

### 1. Prerequisites

*   [Node.js](https://nodejs.org/) (v18+)
*   [Yarn](https://yarnpkg.com/) or npm
*   [Expo CLI](https://docs.expo.dev/) (if using Expo) or React Native CLI
*   Android Studio / Xcode for emulators

### 2. Environment Setup

Create a `.env` file in the root directory based on `.env.example`:

```bash
cp .env.example .env
```

*Ensure the `API_BASE_URL` points to your running backend (e.g., `http://localhost:8000/api` or network IP).*

### 3. Install Dependencies

```bash
yarn install
# or
npm install
```

### 4. Run the Application

Start the development server:

```bash
yarn start
# or
npx expo start
```

Press `a` to run on Android emulator or `i` to run on iOS simulator.

### 5. Build for Production

**Android:**
```bash
cd android && ./gradlew assembleRelease
```

**iOS:**
```bash
cd ios && pod install && xcodebuild -workspace HerWell.xcworkspace -scheme HerWell -configuration Release
```

## Testing

Run the automated test suite:

```bash
yarn test
# or
npm run test
```

To run end-to-end tests (if configured with Detox or Maestro):

```bash
yarn test:e2e
```
