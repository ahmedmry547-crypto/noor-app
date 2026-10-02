import 'dart:io';

/// Patches the generated Android project: permissions, app name, background
/// audio service, launcher + notification icons, MainActivity.
void main() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  var s = f.readAsStringSync();

  if (!s.contains('xmlns:tools')) {
    s = s.replaceFirst('<manifest ',
        '<manifest xmlns:tools="http://schemas.android.com/tools" ');
  }
  if (!s.contains('FOREGROUND_SERVICE_MEDIA_PLAYBACK')) {
    s = s.replaceFirstMapped(
      RegExp(r'<manifest[^>]*>'),
      (m) => '${m[0]}\n'
          '    <uses-permission android:name="android.permission.INTERNET"/>\n'
          '    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>\n'
          '    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>\n'
          '    <uses-permission android:name="android.permission.WAKE_LOCK"/>\n'
          '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>\n'
          '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>\n'
          '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
    );
  }
  // App name shown on the phone.
  s = s.replaceFirst(RegExp(r'android:label="[^"]*"'),
      'android:label="آيات القرآن | Ayat Quran"');
  if (!s.contains('usesCleartextTraffic')) {
    s = s.replaceFirst('<application',
        '<application\n        android:usesCleartextTraffic="true"');
  }
  if (!s.contains('com.ryanheise.audioservice.AudioService')) {
    s = s.replaceFirst('</application>', '''
    <service android:name="com.ryanheise.audioservice.AudioService"
        android:foregroundServiceType="mediaPlayback"
        android:exported="true" tools:ignore="Instantiatable">
        <intent-filter>
            <action android:name="android.media.browse.MediaBrowserService" />
        </intent-filter>
    </service>
    <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver"
        android:exported="true" tools:ignore="Instantiatable">
        <intent-filter>
            <action android:name="android.intent.action.MEDIA_BUTTON" />
        </intent-filter>
    </receiver>
</application>''');
  }
  f.writeAsStringSync(s);

  // MainActivity must extend AudioServiceActivity for background audio.
  final srcDir = Directory('android/app/src/main');
  for (final e in srcDir.listSync(recursive: true)) {
    if (e is File && e.path.endsWith('MainActivity.kt')) {
      final pkg = RegExp(r'package\s+([\w.]+)').firstMatch(e.readAsStringSync())![1];
      e.writeAsStringSync('package $pkg\n\n'
          'import com.ryanheise.audioservice.AudioServiceActivity\n\n'
          'class MainActivity : AudioServiceActivity()\n');
      stdout.writeln('MainActivity patched ($pkg).');
    }
  }

  // Copy launcher + notification icons.
  final res = Directory('tool/res');
  for (final e in res.listSync(recursive: true)) {
    if (e is File) {
      final rel = e.path.substring(res.path.length + 1);
      final dest = File('android/app/src/main/res/$rel');
      dest.parent.createSync(recursive: true);
      e.copySync(dest.path);
    }
  }
  // Remove any adaptive-icon XML that would shadow our PNG launcher icon.
  final any = Directory('android/app/src/main/res/mipmap-anydpi-v26');
  if (any.existsSync()) any.deleteSync(recursive: true);

  // Some newest dependencies require compileSdk 37 -> raise it for the app.
  for (final name in ['android/app/build.gradle.kts', 'android/app/build.gradle']) {
    final g = File(name);
    if (!g.existsSync()) continue;
    var t = g.readAsStringSync();
    t = t.replaceAllMapped(
        RegExp(r'compileSdk(Version)?\s*=?\s*flutter\.compileSdkVersion'),
        (m) => 'compileSdk = 37');
    g.writeAsStringSync(t);
  }
  final props = File('android/gradle.properties');
  var ptxt = props.existsSync() ? props.readAsStringSync() : '';
  if (!ptxt.contains('suppressUnsupportedCompileSdk')) {
    if (ptxt.isNotEmpty && !ptxt.endsWith('\n')) ptxt += '\n';
    ptxt += 'android.suppressUnsupportedCompileSdk=37\n';
    props.writeAsStringSync(ptxt);
  }

  stdout.writeln('Android project patched.');
}
