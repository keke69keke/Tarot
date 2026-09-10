# Reglas de ProGuard/R8 para kotlinx.serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keep,includedescriptorclasses class com.arcana.tarot.**$$serializer { *; }
-keepclassmembers class com.arcana.tarot.** {
    *** Companion;
}
-keepclasseswithmembers class com.arcana.tarot.** {
    kotlinx.serialization.KSerializer serializer(...);
}
