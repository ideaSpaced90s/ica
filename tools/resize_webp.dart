// tools/resize_webp.dart
//
// One-off asset optimisation script.
// Resizes three oversized WebP chess-piece folders and two large GM persona PNGs.
//
// Usage (from project root):
//   dart run tools/resize_webp.dart
//
// Requires: `image: ^4.x` in dev_dependencies (already present in pubspec.yaml).

// ignore_for_file: avoid_print  // CLI tool — print is intentional

import 'dart:io';
import 'package:image/image.dart' as img;

// ── Configuration ─────────────────────────────────────────────────────────────

/// Target pixel size for chess piece WebPs (square, power-of-two).
const int kPieceTargetPx = 256;

/// Target pixel size for GM portrait images (square).
const int kPortraitTargetPx = 512;

// Note: WebPEncoder().encode() uses lossless WebP; quality is controlled by resolution.

/// Folders to process for chess pieces (relative to project root).
const List<String> kPieceFolders = [
  'assets/pieces/diamonds-webP',
  'assets/pieces/energy-webP',
  'assets/pieces/lightening-webP',
];

/// Individual portrait PNGs to convert → WebP and resize.
/// These have already been processed (converted to .webp and deleted).
/// Add new .png paths here if future portraits need conversion.
const List<String> kPortraitPngs = [];

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
}

String _pct(int before, int after) {
  final pct = ((before - after) / before * 100).toStringAsFixed(1);
  return '-$pct%';
}

/// Resize [src] so it fits within [maxPx]×[maxPx], preserving aspect ratio.
img.Image _resizeFit(img.Image src, int maxPx) {
  if (src.width <= maxPx && src.height <= maxPx) return src; // already small enough
  final scale = maxPx / (src.width > src.height ? src.width : src.height);
  final w = (src.width * scale).round();
  final h = (src.height * scale).round();
  return img.copyResize(src, width: w, height: h, interpolation: img.Interpolation.cubic);
}

// ── Main ──────────────────────────────────────────────────────────────────────

void main() {
  print('');
  print('═══════════════════════════════════════════════════════════════');
  print('  WebP Asset Downsize Script');
  print('  Target piece size : ${kPieceTargetPx}px  |  Portrait: ${kPortraitTargetPx}px');
  print('  WebP encoding     : lossless (size reduction is resolution-driven)');
  print('═══════════════════════════════════════════════════════════════');
  print('');

  int totalBefore = 0;
  int totalAfter = 0;
  int fileCount = 0;

  // ── 1. Piece WebP folders ──────────────────────────────────────────────────
  for (final folderPath in kPieceFolders) {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) {
      print('⚠  Folder not found, skipping: $folderPath');
      continue;
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.webp'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    print('📁  $folderPath  (${files.length} files)');

    int folderBefore = 0;
    int folderAfter = 0;

    for (final file in files) {
      final sizeBefore = file.lengthSync();
      folderBefore += sizeBefore;

      // Decode
      final bytes = file.readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        print('   ✗  ${file.uri.pathSegments.last}  — could not decode, skipping');
        folderAfter += sizeBefore;
        continue;
      }

      // Resize
      final resized = _resizeFit(decoded, kPieceTargetPx);

      // Re-encode as WebP
      final encoded = img.WebPEncoder().encode(resized);

      // Write back
      file.writeAsBytesSync(encoded);
      final sizeAfter = file.lengthSync();
      folderAfter += sizeAfter;

      print('   ✓  ${file.uri.pathSegments.last.padRight(30)}'
          '  ${_formatBytes(sizeBefore).padLeft(9)} → ${_formatBytes(sizeAfter).padLeft(9)}'
          '  (${_pct(sizeBefore, sizeAfter)})');
    }

    print('   ── Folder total: ${_formatBytes(folderBefore)} → ${_formatBytes(folderAfter)}'
        '  saved ${_formatBytes(folderBefore - folderAfter)}');
    print('');

    totalBefore += folderBefore;
    totalAfter += folderAfter;
    fileCount += files.length;
  }

  // ── 2. GM Portrait PNGs → WebP ────────────────────────────────────────────
  print('🖼   GM Portrait PNGs (resize + convert to WebP)');
  for (final pngPath in kPortraitPngs) {
    final pngFile = File(pngPath);
    if (!pngFile.existsSync()) {
      print('   ⚠  Not found, skipping: $pngPath');
      continue;
    }

    final sizeBefore = pngFile.lengthSync();
    totalBefore += sizeBefore;

    // Decode PNG
    final bytes = pngFile.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      print('   ✗  ${pngFile.uri.pathSegments.last}  — could not decode, skipping');
      totalAfter += sizeBefore;
      continue;
    }

    // Resize to portrait target
    final resized = _resizeFit(decoded, kPortraitTargetPx);

    // Encode as WebP
    final encoded = img.WebPEncoder().encode(resized);

    // Write as .webp alongside original, then delete the .png
    final webpPath = pngPath.replaceAll('.png', '.webp');
    final webpFile = File(webpPath);
    webpFile.writeAsBytesSync(encoded);
    pngFile.deleteSync();

    final sizeAfter = webpFile.lengthSync();
    totalAfter += sizeAfter;
    fileCount++;

    print('   ✓  ${pngFile.uri.pathSegments.last.padRight(30)}'
        '  ${_formatBytes(sizeBefore).padLeft(9)} → ${_formatBytes(sizeAfter).padLeft(9)}'
        '  (${_pct(sizeBefore, sizeAfter)})  [PNG→WebP]');
  }

  print('');

  // ── 3. Summary ────────────────────────────────────────────────────────────
  print('═══════════════════════════════════════════════════════════════');
  print('  SUMMARY');
  print('  Files processed : $fileCount');
  print('  Before total    : ${_formatBytes(totalBefore)}');
  print('  After total     : ${_formatBytes(totalAfter)}');
  print('  Saved           : ${_formatBytes(totalBefore - totalAfter)}'
      '  (${_pct(totalBefore, totalAfter)})');
  print('═══════════════════════════════════════════════════════════════');
  print('');

  // ── 4. Remind to update Dart source if any portrait PNGs were converted ────
  final converted = kPortraitPngs.where((p) => !File(p).existsSync()).toList();
  if (converted.isNotEmpty) {
    print('⚠  IMPORTANT: The following files were converted .png → .webp.');
    print('   Update any Dart AssetImage references to match:');
    for (final p in converted) {
      final name = p.split('/').last;
      print('     $name  →  ${name.replaceAll('.png', '.webp')}');
    }
    print('');
  }
}
