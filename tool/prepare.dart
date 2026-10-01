import 'dart:io';

/// Adds required permissions, Arabic app name and the supplied launcher icon
/// to the generated Android project.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  var s = manifest.readAsStringSync();
  if (!s.contains('ACCESS_FINE_LOCATION')) {
    s = s.replaceFirstMapped(
      RegExp(r'<manifest[^>]*>'),
      (m) => '${m[0]}\n'
          '    <uses-permission android:name="android.permission.INTERNET"/>\n'
          '    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>\n'
          '    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>',
    );
  }
  s = s.replaceFirst('android:label="noor"', 'android:label="نور القرآن الكريم"');
  manifest.writeAsStringSync(s);

  final source = File('tool/app_icon.png');
  if (!source.existsSync()) {
    throw StateError('tool/app_icon.png is missing');
  }
  const densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  for (final entry in densities.entries) {
    final dir = Directory('android/app/src/main/res/${entry.key}')..createSync(recursive: true);
    final sized = File('tool/app_icon_${entry.value}.png');
    final iconSource = sized.existsSync() ? sized : source;
    iconSource.copySync('${dir.path}/ic_launcher.png');
    iconSource.copySync('${dir.path}/ic_launcher_round.png');
  }

  stdout.writeln('Manifest and launcher icon patched.');
}
