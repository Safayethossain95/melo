# Just Audio & ExoPlayer Proguard Keep Rules
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn com.ryanheise.just_audio.**
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**
