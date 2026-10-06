package com.wordjourney.app

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.speech.tts.TextToSpeech
import android.speech.tts.Voice
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import android.os.SystemClock
import android.util.Log
import android.content.pm.ApplicationInfo

/** Offline feedback, bounded concurrency and no network speech fallback. */
class PersonalMedia(private val context: Context) {
    private val pool = SoundPool.Builder().setMaxStreams(2).setAudioAttributes(
        AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()).build()
    private val samples = mutableMapOf<String, Int>()
    private val ready = mutableSetOf<Int>()
    private val streams = mutableListOf<Int>()
    private val audioWorker = Executors.newSingleThreadExecutor { r -> Thread(r, "word-journey-audio") }
    private val profileAudio = context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
    private val audioQueue = BoundedAudioQueue(audioWorker, { SystemClock.uptimeMillis() }, object : BoundedAudioQueue.Player {
        override fun play(name: String, volume: Float) {
            val started = SystemClock.elapsedRealtimeNanos()
            try {
                val id = synchronized(samples) { samples[name] }
                if (id != null && synchronized(ready) { ready.contains(id) }) {
                    while (streams.size >= 2) pool.stop(streams.removeAt(0))
                    val stream = pool.play(id, volume, volume, 1, 0, 1f)
                    if (stream != 0) streams.add(stream)
                }
            } catch (_: Exception) { /* Optional feedback never interrupts play. */ }
            if (profileAudio) Log.i("WJSound", "workerMicros=${(SystemClock.elapsedRealtimeNanos() - started) / 1000}")
        }
        override fun stop() { streams.forEach { pool.stop(it) }; streams.clear() }
    })
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var ttsFailed = false
    private val voiceWaiters = mutableListOf<MethodChannel.Result>()
    init {
        pool.setOnLoadCompleteListener { _, id, status -> if (status == 0) synchronized(ready) { ready.add(id) } }
        tts = TextToSpeech(context) { status ->
            ttsReady = status == TextToSpeech.SUCCESS; ttsFailed = !ttsReady
            voiceWaiters.toList().forEach { it.success(voices()) }; voiceWaiters.clear()
        }
    }
    private fun offline(): List<Voice> = if (ttsReady) tts?.voices?.filter { it.locale.language == "en" && !it.isNetworkConnectionRequired }?.sortedBy { it.name } ?: emptyList() else emptyList()
    private fun voices() = offline().map { mapOf("id" to it.name, "label" to "${it.locale.toLanguageTag()} · ${it.name}") }
    fun handle(call: MethodCall, result: MethodChannel.Result): Boolean {
        when (call.method) {
            "preloadSounds" -> {
                audioWorker.execute {
                    try {
                        for (name in listOf("select", "correct", "wrong", "combo", "milestone", "finish")) {
                            val file = File(context.cacheDir, "feedback-$name.wav")
                            context.assets.open("flutter_assets/assets/audio/$name.wav").use { input -> file.outputStream().use { input.copyTo(it) } }
                            val id = pool.load(file.absolutePath, 1)
                            synchronized(samples) { samples[name] = id }
                        }
                    } catch (_: Exception) { /* Optional audio never affects the reducer. */ }
                }
                result.success(true)
            }
            "playSound" -> {
                val name = call.argument<String>("name") ?: ""
                val volume = (call.argument<Double>("volume") ?: 0.0).coerceIn(0.0, 1.0).toFloat()
                audioQueue.submit(name, volume)
                result.success(null)
            }
            "stopSounds" -> { audioQueue.stop(); result.success(null) }
            "voices" -> { if (ttsReady || ttsFailed) result.success(voices()) else voiceWaiters.add(result) }
            "speak" -> {
                val available = offline()
                val requested = call.argument<String>("voice")
                val voice = if (requested == null) available.firstOrNull() else available.firstOrNull { it.name == requested }
                if (voice == null) result.error("offline_voice", "На устройстве нет выбранного офлайн-голоса английского.", null)
                else {
                    tts!!.voice = voice
                    val status = tts!!.speak(call.argument<String>("text") ?: "", TextToSpeech.QUEUE_FLUSH, null, "personal-word")
                    if (status == TextToSpeech.ERROR) result.error("tts", "Не удалось произнести слово.", null) else result.success(true)
                }
            }
            "stopSpeech" -> { tts?.stop(); result.success(null) }
            else -> return false
        }
        return true
    }
    fun pause() { audioQueue.stop(); tts?.stop() }
    fun close() {
        if (audioQueue.close { pool.release() }) audioWorker.shutdown()
        tts?.stop(); tts?.shutdown()
        voiceWaiters.forEach { it.success(emptyList<Any>()) }; voiceWaiters.clear()
    }
}
