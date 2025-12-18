
# Keep TensorFlow Lite GPU delegate classes
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Keep ML Kit face detection internal classes
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
