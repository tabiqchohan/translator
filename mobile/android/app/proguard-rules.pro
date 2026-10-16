# Flutter Wrapper & Plugins Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google ML Kit Text Recognition ProGuard Rules
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# Speech to text & TTS ProGuard
-dontwarn com.csdcorp.speech_to_text.**
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.tundralabs.fluttertts.**
-keep class com.tundralabs.fluttertts.** { *; }

# File picker & Toast
-dontwarn com.mr.flutter.plugin.filepicker.**
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn io.github.ponnamkarthik.toast.**
-keep class io.github.ponnamkarthik.toast.** { *; }
