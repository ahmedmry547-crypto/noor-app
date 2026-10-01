Noor V3 - build fix + complete Quran audio/adhkar update

IMPORTANT:
The GitHub Actions build was failing because the project used geolocator ^12.0.0 while the current Flutter toolchain is compiling against an API signature that did not match the project call. This update changes geolocator to ^14.0.3.

Upload/replace these files at the ROOT of the GitHub repository (same level as build_apk.sh and .github):
- pubspec.yaml
- lib/features/azkar/azkar_data.dart
- lib/features/quran/quran_screen.dart
- lib/features/quran/audio_screen.dart
- lib/features/quran/audio_downloads.dart
- lib/features/quran/mp3quran_service.dart

Do NOT upload this ZIP as a ZIP inside the repository.
Do NOT put these files under the old /noor folder if the GitHub workflow is at repository root. The workflow runs: bash build_apk.sh from the repository root.

After commit to main, GitHub Actions should rebuild automatically.
