import 'dart:io';

/// Adds required permissions + Arabic app name to the generated Android manifest.
void main() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  var s = f.readAsStringSync();
  if (!s.contains('ACCESS_FINE_LOCATION')) {
    s = s.replaceFirstMapped(
      RegExp(r'<manifest[^>]*>'),
      (m) => '${m[0]}\n'
          '    <uses-permission android:name="android.permission.INTERNET"/>\n'
          '    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>\n'
          '    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>',
    );
  }
  s = s.replaceFirst('android:label="noor"', 'android:label="نور"');
  f.writeAsStringSync(s);
  stdout.writeln('Manifest patched.');
}
