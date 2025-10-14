import 'dart:io';
import 'package:archive/archive_io.dart';

Future<void> main() async {
  final apkPath = 'build/app/outputs/flutter-apk/app-release.apk';
  final extractDir = 'apk_extract';

  print('🔍 Checking Flutter app for 16KB page size support...\n');

  final apkFile = File(apkPath);
  if (!await apkFile.exists()) {
    print('❌ APK not found at $apkPath');
    print('➡️ Please build your release APK first using:');
    print('   flutter build apk --release --target-platform android-arm64\n');
    return;
  }

  // حذف أي مجلد قديم من محاولة سابقة
  final extractDirectory = Directory(extractDir);
  if (await extractDirectory.exists()) {
    await extractDirectory.delete(recursive: true);
  }

  print('📦 Extracting APK (using Dart)...');
  await extractApk(apkPath, extractDir);

  // ابحث عن ملفات .so
  final libDir = Directory('$extractDir/lib');
  if (!await libDir.exists()) {
    print('⚠️ No native libraries folder found inside the APK.');
    return;
  }

  final soFiles = libDir
      .listSync(recursive: true)
      .where((e) => e.path.endsWith('.so'))
      .toList();

  if (soFiles.isEmpty) {
    print('⚠️ No .so files found in APK.');
    return;
  }

  print('🧩 Found ${soFiles.length} native libraries:');
  for (var file in soFiles) {
    print(' - ${file.path}');
  }

  print('\n🔎 Checking each for 16KB page size support...\n');

  for (var file in soFiles) {
    final f = File(file.path);
    final bytes = await f.readAsBytes();

    // تحقق بدائي بناءً على توقيع Flutter الحديثة
    final has16KBFlag = bytes.contains('page_size_16k'.codeUnits);

    if (has16KBFlag) {
      print('✅ ${file.path.split('/').last}: 16KB page size supported.');
    } else {
      print('⚠️ ${file.path.split('/').last}: 16KB page size NOT detected.');
    }
  }

  // تنظيف الملفات بعد الفحص
  await extractDirectory.delete(recursive: true);
  print('\n🧹 Cleaned up temporary files.');
  print('\n✅ Done!');
}

Future<void> extractApk(String apkPath, String extractDir) async {
  final file = File(apkPath);
  final bytes = await file.readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  for (final entry in archive) {
    final filename = '$extractDir/${entry.name}';
    if (entry.isFile) {
      final outFile = File(filename);
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(entry.content as List<int>);
    } else {
      await Directory(filename).create(recursive: true);
    }
  }
}
