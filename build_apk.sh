#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
rm -rf _gen android
# 1) Embed the full Quran (offline) + font into the app assets
dart tool/fetch_assets.dart
# 2) Generate the Android project and patch it
flutter create --platforms=android --org com.ayatquran --project-name ayat_quran _gen
mv _gen/android android
rm -rf _gen
dart tool/prepare.dart
# 3) Build
flutter pub get
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/Ayat-Quran.apk || true
echo ""
echo "APK ready: build/app/outputs/flutter-apk/app-release.apk"
