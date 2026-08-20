# Flutter WebRTC ProGuard Rules
-keep class org.webrtc.** { *; }
-keep interface org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Flutter CallKit Incoming ProGuard Rules
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-dontwarn com.hiennv.flutter_callkit_incoming.**

# AudioPlayers ProGuard Rules
-keep class xyz.l22.audioplayers.** { *; }
-dontwarn xyz.l22.audioplayers.**

# Firebase ProGuard Rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Flutter Engine ProGuard Rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
