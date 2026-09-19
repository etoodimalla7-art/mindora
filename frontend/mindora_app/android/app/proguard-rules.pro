# Flutter's own engine classes must never be obfuscated/stripped.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Play Core split-install classes referenced by Flutter's deferred-
# components support even when this app doesn't use deferred
# components — R8 warns without these if they're missing from the
# classpath; keeping them (when present) avoids a build failure.
-dontwarn com.google.android.play.core.**
