# Google ML Kit Text Recognition
# Keep ML Kit classes to prevent R8 from removing them
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }

# Ignore warnings for optional language-specific recognizers that aren't included
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep Google ML Kit Commons
-keep class com.google_mlkit_commons.** { *; }

# Keep text recognition classes
-keep class com.google_mlkit_text_recognition.** { *; }

