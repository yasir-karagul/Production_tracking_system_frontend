import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

const String _channelName = 'com.maiaporselen.MaiaUTS/downloads';
const String _xlsxMimeType =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
const String _xlsMimeType = 'application/vnd.ms-excel';

class ExportedExcelFile {
  const ExportedExcelFile({
    required this.openTarget,
    required this.fileName,
    required this.mimeType,
  });

  final String openTarget;
  final String fileName;
  final String mimeType;

  bool get isContentUri => openTarget.startsWith('content://');
}

class ExcelExportStorage {
  ExcelExportStorage._();

  static const MethodChannel _channel = MethodChannel(_channelName);

  static Future<ExportedExcelFile> saveToDownloads({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final normalizedFileName = _ensureExcelFileName(fileName);
    final mimeType = _excelMimeTypeForFile(normalizedFileName);

    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMapMethod<String, dynamic>(
          'saveExcelToDownloads',
          {
            'fileName': normalizedFileName,
            'bytes': bytes,
            'mimeType': mimeType,
          },
        );
        final target = result?['uri'] as String?;
        if (target != null && target.isNotEmpty) {
          return ExportedExcelFile(
            openTarget: target,
            fileName: normalizedFileName,
            mimeType: mimeType,
          );
        }
      } on MissingPluginException {
        // Falls back to file-based storage on unsupported runtimes.
      } on PlatformException catch (e) {
        throw FileSystemException(
          e.message ?? 'Android MediaStore kayıt hatası',
        );
      }
    }

    final downloadsDir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final file = File('${downloadsDir.path}/$normalizedFileName');
    await file.writeAsBytes(bytes, flush: true);
    return ExportedExcelFile(
      openTarget: file.path,
      fileName: normalizedFileName,
      mimeType: mimeType,
    );
  }

  static Future<String?> open(ExportedExcelFile exportedFile) async {
    if (Platform.isAndroid && exportedFile.isContentUri) {
      try {
        final opened = await _channel.invokeMethod<bool>(
              'openExportedFile',
              {
                'target': exportedFile.openTarget,
                'mimeType': exportedFile.mimeType,
              },
            ) ??
            false;
        return opened
            ? null
            : 'Dosya acilamadi. Lutfen Downloads klasorunden manuel olarak acin.';
      } on PlatformException catch (e) {
        final message = e.message ?? 'Dosya acilamadi';
        return '$message. Lutfen Downloads klasorunden manuel olarak acin.';
      }
    }

    final result = await OpenFilex.open(exportedFile.openTarget);
    if (result.type == ResultType.done) return null;
    final message =
        result.message.isNotEmpty ? result.message : 'Dosya acilamadi';
    return '$message. Lutfen Downloads klasorunden manuel olarak acin.';
  }

  static String _ensureExcelFileName(String fileName) {
    final trimmed = fileName.trim();
    final lower = trimmed.toLowerCase();
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) {
      return trimmed;
    }
    return '$trimmed.xlsx';
  }

  static String _excelMimeTypeForFile(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.xls')) {
      return _xlsMimeType;
    }
    return _xlsxMimeType;
  }
}
