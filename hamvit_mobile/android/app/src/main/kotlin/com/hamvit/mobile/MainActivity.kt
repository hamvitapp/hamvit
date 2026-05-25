package com.hamvit.mobile

import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterFragmentActivity

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
	}
}

