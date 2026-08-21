# تحديث إعدادات مشروع Flutter

## الخطوة الأولى: تعديل ملف settings.gradle

المسار: `android\settings.gradle`

قم بتعديل قسم الإضافات (Plugins) ليصبح كالتالي:

```gradle
plugins { 
    id "dev.flutter.flutter-plugin-loader" version "1.0.0" 
    id "com.android.application" version "8.11.0" apply false 
    id "org.jetbrains.kotlin.android" version "2.2.20" apply false 
} 
```

## الخطوة الثانية: تحديث إصدار Gradle

المسار: `android\gradle\wrapper\gradle-wrapper.properties`

قم بتحديث إصدار Gradle إلى:

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-all.zip
```

## الخطوة الثالثة: تعديل إصدار NDK

المسار: `android\app\build.gradle`

قم بتعديل إصدار NDK ليصبح:

```gradle
ndkVersion "28.0.124335108"
```

**ملاحظة مهمة**: يجب تحميل NDK إصدار 28 لاستخدام هذا المسار. للقيام بذلك:
1. افتح Android Studio
2. انتقل إلى SDK Tools
3. اختر "Show Package Details"
4. قم بتحميل الإصدار 28 على الأقل

## الخطوة الرابعة: بناء المشروع

افتح Terminal في مشروعك واكتب الأوامر التالية:

```bash
cd android
./gradlew clean
./gradlew assembleRelease
```

بعد تنفيذ هذه الخطوات، سيتم بناء تطبيقك بنجاح باستخدام الإعدادات الجديدة.