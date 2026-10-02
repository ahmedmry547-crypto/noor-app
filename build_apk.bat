@echo off
cd /d "%~dp0"
if exist _gen rmdir /s /q _gen
if exist android rmdir /s /q android
call dart tool\fetch_assets.dart || exit /b 1
call flutter create --platforms=android --org com.ayatquran --project-name ayat_quran _gen || exit /b 1
xcopy /E /I /Y _gen\android android >nul
rmdir /s /q _gen
call dart tool\prepare.dart || exit /b 1
call flutter pub get || exit /b 1
call flutter build apk --release || exit /b 1
echo.
echo APK ready: build\app\outputs\flutter-apk\app-release.apk
pause
