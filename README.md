# آيات القرآن | Ayat Quran (Flutter)

## البناء
- GitHub Actions: Actions > Build APK > Run workflow (الـ workflow لم يتغير).
- محليًا: `./build_apk.sh` (Mac/Linux) أو `build_apk.bat` (Windows).

أثناء البناء يسحب `tool/fetch_assets.dart` نص القرآن الكامل (6236 آية، مع التجويد وأرقام الصفحات والأجزاء)
وخط المصحف ويضمّنهم داخل الـ APK، فيعمل القرآن بدون إنترنت من أول تشغيل.
