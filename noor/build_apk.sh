#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
rm -rf _gen android
flutter create --platforms=android --org com.noor --project-name noor _gen
mv _gen/android android
rm -rf _gen
dart tool/prepare.dart
flutter pub get
flutter build apk --release
echo ""
echo "APK ready: build/app/outputs/flutter-apk/app-release.apk"
