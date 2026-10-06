package com.wordjourney.app

import android.app.Activity
import android.content.Intent
import java.io.ByteArrayOutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var media: PersonalMedia? = null
    private var pending: MethodChannel.Result? = null
    private var exportText: String? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        media = try { PersonalMedia(this) } catch (_: Exception) { null }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.wordjourney.app/personal").setMethodCallHandler { call, result ->
            when (call.method) {
                "exportBackup", "importBackup" -> {
                    if (pending != null) { result.error("busy", "File picker already open", null); return@setMethodCallHandler }
                    val exporting = call.method == "exportBackup"
                    exportText = if (exporting) call.argument<String>("text") else null
                    if (exporting && (exportText == null || exportText!!.length > 8 * 1024 * 1024)) { result.error("size", "Invalid backup size", null); return@setMethodCallHandler }
                    pending = result
                    val intent = Intent(if (exporting) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/json"
                        if (exporting) putExtra(Intent.EXTRA_TITLE, "word-journey-backup.json")
                    }
                    try { startActivityForResult(intent, if (exporting) 501 else 502) }
                    catch (e: Exception) { pending = null; exportText = null; result.error("picker", e.message, null) }
                }
                else -> if (media?.handle(call, result) != true) result.notImplemented()
            }
        }
    }
    override fun onPause() { media?.pause(); super.onPause() }
    override fun onDestroy() { media?.close(); media = null; super.onDestroy() }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != 501 && requestCode != 502) return
        val result = pending ?: return
        pending = null
        val text = exportText; exportText = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) { result.success(null); return }
        Thread {
            try {
                val value: Any = if (requestCode == 501) {
                    val stream = contentResolver.openOutputStream(uri, "wt") ?: throw IllegalStateException("No output stream")
                    stream.use { it.write(text!!.toByteArray(Charsets.UTF_8)) }
                    true
                } else {
                    val stream = contentResolver.openInputStream(uri) ?: throw IllegalStateException("No input stream")
                    stream.use {
                        val output = ByteArrayOutputStream(); val buffer = ByteArray(8192)
                        while (true) { val size = it.read(buffer); if (size < 0) break; output.write(buffer, 0, size); if (output.size() > 8 * 1024 * 1024) throw IllegalArgumentException("Backup too large") }
                        output.toString("UTF-8")
                    }
                }
                runOnUiThread { result.success(value) }
            } catch (e: Exception) { runOnUiThread { result.error("io", e.message, null) } }
        }.start()
    }
}
