import 'dart:io';

void main(List<String> args) async {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ Error: pubspec.yaml not found in current directory.');
    exit(1);
  }

  final content = pubspecFile.readAsStringSync();
  final versionRegex = RegExp(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)', multiLine: true);
  final match = versionRegex.firstMatch(content);

  if (match == null) {
    print('❌ Error: Could not find valid version line (e.g. version: 1.0.0+1) in pubspec.yaml');
    exit(1);
  }

  int major = int.parse(match.group(1)!);
  int minor = int.parse(match.group(2)!);
  int patch = int.parse(match.group(3)!);
  int build = int.parse(match.group(4)!);

  final oldVersion = '$major.$minor.$patch+$build';

  // Determine increment mode:
  // default: bump patch and build (e.g. 1.0.0+1 -> 1.0.1+2)
  // --build-only: only bump build (e.g. 1.0.0+1 -> 1.0.0+2)
  // --minor: bump minor (e.g. 1.0.0+1 -> 1.1.0+2)
  // --major: bump major (e.g. 1.0.0+1 -> 2.0.0+2)
  final buildOnly = args.contains('--build-only');
  final isMinor = args.contains('--minor');
  final isMajor = args.contains('--major');

  build += 1;
  if (isMajor) {
    major += 1;
    minor = 0;
    patch = 0;
  } else if (isMinor) {
    minor += 1;
    patch = 0;
  } else if (!buildOnly) {
    patch += 1;
  }

  final newVersion = '$major.$minor.$patch+$build';

  final updatedContent = content.replaceFirst(
    versionRegex,
    'version: $newVersion',
  );

  pubspecFile.writeAsStringSync(updatedContent);

  print('========================================');
  print('📦 Version bumped in pubspec.yaml:');
  print('   Previous: $oldVersion');
  print('   New:      $newVersion');
  print('========================================');

  // Check if build flag is present or default to building
  final noBuild = args.contains('--no-build');
  if (noBuild) {
    print('⏭️  Skipping build (--no-build flag set).');
    return;
  }

  print('\n🚀 Building release APK with Flutter...\n');

  final env = Map<String, String>.from(Platform.environment);
  // Ensure D: drive is used for Gradle cache and temp files to protect C: drive space
  if (Directory(r'D:\.gradle').existsSync() || Directory(r'D:\').existsSync()) {
    env['GRADLE_USER_HOME'] = r'D:\.gradle';
  }
  if (Directory(r'D:\Temp').existsSync()) {
    env['TEMP'] = r'D:\Temp';
    env['TMP'] = r'D:\Temp';
  }

  final flutterCmd = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final flutterArgs = ['build', 'apk', '--release'];

  for (final arg in args) {
    if (arg.startsWith('--split-') ||
        arg.startsWith('--obfuscate') ||
        arg.startsWith('--target') ||
        arg.startsWith('--dart-define')) {
      flutterArgs.add(arg);
    }
  }

  final process = await Process.start(
    flutterCmd,
    flutterArgs,
    environment: env,
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;
  if (exitCode == 0) {
    print('\n========================================');
    print('✅ Build successful for version $newVersion!');
    final apkFile = File('build/app/outputs/flutter-apk/app-release.apk');
    if (apkFile.existsSync()) {
      final sizeMb = (apkFile.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
      print('📦 APK: ${apkFile.path} ($sizeMb MB)');
    }
    print('========================================\n');
  } else {
    print('\n❌ Build failed with exit code $exitCode');
    exit(exitCode);
  }
}
