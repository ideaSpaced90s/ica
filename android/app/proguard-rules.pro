# Prevent R8 from optimizing or obfuscating Firebase App Check internals incorrectly
-keep class com.google.firebase.appcheck.internal.** { *; }
