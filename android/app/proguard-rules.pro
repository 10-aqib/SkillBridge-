# SkillBridge Android API 35 Release ProGuard / R8 Hardening Rules
# Preserves Flutter engine bindings, Hive models, Firebase SDKs, and Crashlytics stack traces.

# Retain line numbers for Firebase Crashlytics reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Preserve Flutter engine JNI bridges
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.**

# Preserve Hive offline storage & Hive-Flutter adapters
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-keep class io.github.v7lin.** { *; }
-dontwarn io.github.v7lin.**

# Preserve Firebase Authentication & Cloud Firestore models
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Preserve Riverpod generator metadata and JSON serialization annotations
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
