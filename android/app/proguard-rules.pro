# Manten las anotaciones de los modelos
#-keepclassmembers class * {
#    @com.google.gson.annotations.SerializedName <fields>; }

# Manten las clases de modelo que tienen anotaciones
#-keep class * {
#    @com.google.gson.annotations.SerializedName <fields>; }

# Configuraciones para evitar problemas con librerías populares -keep class androidx.lifecycle.** { *; } -keep class androidx.fragment.app.** { *; } -keep class androidx.recyclerview.widget.** { *; } -keep class androidx.appcompat.widget.** { *; }

# Mantén todas las actividades (esto es solo un ejemplo, puedes ajustarlo según tus necesidades) -keep class * extends android.app.Activity ```
    # ProGuard rules to preserve specific classes and methods
    -keep class com.example.** { *; }
    -keep class androidx.** { *; }
    -keepattributes Signature
    -keepattributes *Annotation*
