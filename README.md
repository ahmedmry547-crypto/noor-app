# نور - تطبيق إسلامي (Flutter)

## البناء
1. ثبّت Flutter (https://docs.flutter.dev/get-started/install) وAndroid Studio.
2. افتح الترمينال داخل هذا المجلد:
   - Windows: `build_apk.bat`
   - Mac/Linux: `./build_apk.sh`
3. الـ APK هيطلع في: `build/app/outputs/flutter-apk/app-release.apk`

## بدون تثبيت Flutter
ارفع المجلد على GitHub ثم Actions > Build APK > Run workflow، وحمّل الملف من Artifacts.

## ملاحظة
القرآن يتحمّل من Quran.com API أول مرة لكل سورة ثم يُحفظ على الجهاز.
