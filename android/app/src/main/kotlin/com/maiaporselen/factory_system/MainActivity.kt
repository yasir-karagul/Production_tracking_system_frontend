package com.maiaporselen.MaiaUTS

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL_NAME = "com.maiaporselen.MaiaUTS/downloads"
        private const val EXCEL_MIME_TYPE_XLSX =
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        private const val EXCEL_MIME_TYPE_XLS = "application/vnd.ms-excel"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveExcelToDownloads" -> {
                        val fileName = call.argument<String>("fileName")
                        val bytes = call.argument<ByteArray>("bytes")
                        if (fileName.isNullOrBlank() || bytes == null || bytes.isEmpty()) {
                            result.error(
                                "INVALID_ARGS",
                                "fileName and bytes are required",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        val mimeType =
                            call.argument<String>("mimeType") ?: mimeTypeForFileName(fileName)

                        try {
                            val target = saveExcelToDownloads(fileName, bytes, mimeType)
                            if (target == null) {
                                result.error("SAVE_FAILED", "File could not be saved", null)
                            } else {
                                result.success(mapOf("uri" to target))
                            }
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }

                    "openExportedFile" -> {
                        val target = call.argument<String>("target")
                        val mimeType =
                            call.argument<String>("mimeType") ?: EXCEL_MIME_TYPE_XLSX
                        if (target.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "target is required", null)
                            return@setMethodCallHandler
                        }

                        try {
                            result.success(openExportedFile(target, mimeType))
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun saveExcelToDownloads(fileName: String, bytes: ByteArray, mimeType: String): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: return null

            try {
                resolver.openOutputStream(uri)?.use { output ->
                    output.write(bytes)
                    output.flush()
                } ?: return null

                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                return uri.toString()
            } catch (e: Exception) {
                resolver.delete(uri, null, null)
                throw e
            }
        }

        val fallbackDir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: filesDir
        if (!fallbackDir.exists()) {
            fallbackDir.mkdirs()
        }
        val file = File(fallbackDir, fileName)
        file.outputStream().use { it.write(bytes) }
        return file.absolutePath
    }

    private fun openExportedFile(target: String, mimeType: String): Boolean {
        val uri = toOpenableUri(target) ?: return false

        val mimeCandidates = linkedSetOf<String>().apply {
            if (mimeType.isNotBlank()) add(mimeType)
            add(mimeTypeForTarget(target))
            add(EXCEL_MIME_TYPE_XLSX)
            add(EXCEL_MIME_TYPE_XLS)
            add("application/octet-stream")
            add("*/*")
        }

        for (candidate in mimeCandidates) {
            if (tryOpenUri(uri, candidate)) {
                return true
            }
        }
        return false
    }

    private fun tryOpenUri(uri: Uri, mimeType: String): Boolean {
        val viewIntent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            clipData = ClipData.newRawUri("excel", uri)
        }

        val chooser = Intent.createChooser(viewIntent, "Dosyayi ac").apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            clipData = ClipData.newRawUri("excel", uri)
        }

        return try {
            startActivity(chooser)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: SecurityException) {
            false
        }
    }

    private fun toOpenableUri(target: String): Uri? {
        if (target.startsWith("content://")) {
            return Uri.parse(target)
        }

        val file = if (target.startsWith("file://")) {
            val parsedPath = Uri.parse(target).path ?: return null
            File(parsedPath)
        } else {
            File(target)
        }
        if (!file.exists()) return null

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file,
            )
        } else {
            Uri.fromFile(file)
        }
    }

    private fun mimeTypeForTarget(target: String): String {
        return mimeTypeForFileName(target.substringAfterLast('/'))
    }

    private fun mimeTypeForFileName(fileName: String): String {
        return if (fileName.lowercase().endsWith(".xls")) {
            EXCEL_MIME_TYPE_XLS
        } else {
            EXCEL_MIME_TYPE_XLSX
        }
    }
}
