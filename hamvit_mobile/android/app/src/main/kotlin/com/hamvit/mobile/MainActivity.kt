package com.hamvit.mobile

import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import android.content.ContentValues
import android.os.Build
import android.provider.MediaStore
import android.content.Context
import java.io.IOException
import android.net.Uri
import android.util.Log

class MainActivity : FlutterFragmentActivity() {
	private val privacyChannel = "hamvit/privacy_protection"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, privacyChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"setSecure" -> {
						val enabled = call.argument<Boolean>("enabled") ?: false
						runOnUiThread {
							if (enabled) {
								window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
							} else {
								window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
							}
						}
						result.success(null)
					}

					else -> result.notImplemented()
				}
			}

		// Channel to save PDF bytes into Downloads via MediaStore
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hamvit/pdf_saver")
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"savePdfToDownloads" -> {
						val fileName = call.argument<String>("fileName") ?: "report.pdf"
						val bytes = call.argument<ByteArray>("bytes")
						val openAfter = call.argument<Boolean>("open") ?: false
						Log.d("HamvitPdfSaver", "savePdfToDownloads called: fileName=$fileName open=$openAfter bytes=${bytes?.size}")
						if (bytes == null) {
							result.error("NO_BYTES", "No PDF bytes provided", null)
							Log.e("HamvitPdfSaver", "No bytes provided in method call")
							return@setMethodCallHandler
						}
						try {
							val uri = savePdfToDownloads(this, fileName, bytes)
							Log.d("HamvitPdfSaver", "Saved PDF to $uri")
							if (openAfter && uri != null) {
								val intent = android.content.Intent(android.content.Intent.ACTION_VIEW).apply {
									setDataAndType(uri, "application/pdf")
									addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION)
									addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
								}
								startActivity(intent)
							}
							result.success(uri?.toString())
						} catch (e: Exception) {
							Log.e("HamvitPdfSaver", "Failed to save PDF: ${e.message}", e)
							result.error("SAVE_ERROR", e.message, null)
						}
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun savePdfToDownloads(context: Context, fileName: String, bytes: ByteArray): Uri? {
		val resolver = context.contentResolver
		val contentValues = ContentValues().apply {
			put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
			put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
				put(MediaStore.MediaColumns.RELATIVE_PATH, "Download/")
			}
		}

		val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
		} else {
			MediaStore.Files.getContentUri("external")
		}

		var uri: Uri? = null
		try {
			uri = resolver.insert(collection, contentValues)
			if (uri == null) throw IOException("Failed to create new MediaStore record.")
			resolver.openOutputStream(uri)?.use { out ->
				out.write(bytes)
				out.flush()
			}
			return uri
		} catch (e: Exception) {
			// cleanup if insertion created a stub
			if (uri != null) resolver.delete(uri, null, null)
			throw e
		}
	}
}

