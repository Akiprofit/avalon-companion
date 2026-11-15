package com.avalon.companion

import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID

/**
 * Hosts the Flutter UI and exposes the platform text-to-speech engine.
 *
 * The app speaks narration lines and nothing else. No text is logged, stored or
 * sent anywhere: [TextToSpeech] synthesises on the device.
 */
class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "com.avalon.companion/tts"

        /** The Royal Chronicler's default: British English. */
        const val DEFAULT_LOCALE = "en-GB"
    }

    private var channel: MethodChannel? = null
    private var engine: TextToSpeech? = null
    private var ready = false
    private var pendingInit: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methodChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel = methodChannel
        methodChannel.setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> initEngine(result)
            "speak" -> speak(call, result)
            "stop" -> {
                engine?.stop()
                result.success(true)
            }
            "isLanguageAvailable" -> {
                val locale = call.argument<String>("locale") ?: DEFAULT_LOCALE
                result.success(hasVoiceFor(locale))
            }
            else -> result.notImplemented()
        }
    }

    private fun initEngine(result: MethodChannel.Result) {
        if (ready) {
            result.success(true)
            return
        }
        if (engine != null) {
            // A previous init is still in flight; the newest caller waits too.
            pendingInit = result
            return
        }

        // The OnInit callback can fire before the constructor returns, so the
        // pending result has to be stored first.
        pendingInit = result
        engine = TextToSpeech(applicationContext) { status ->
            ready = status == TextToSpeech.SUCCESS
            val pending = pendingInit
            pendingInit = null
            pending?.success(ready)
        }
        engine?.setOnUtteranceProgressListener(
            object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) = Unit

                override fun onDone(utteranceId: String?) {
                    notifyDart("onDone", utteranceId)
                }

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) {
                    notifyDart("onError", utteranceId)
                }

                override fun onStop(utteranceId: String?, interrupted: Boolean) {
                    notifyDart("onStop", utteranceId)
                }
            },
        )
    }

    private fun speak(call: MethodCall, result: MethodChannel.Result) {
        val text = call.argument<String>("text")
        val locale = call.argument<String>("locale") ?: DEFAULT_LOCALE
        val rate = call.argument<Double>("rate") ?: 1.0
        val volume = call.argument<Double>("volume") ?: 1.0
        val pitch = call.argument<Double>("pitch") ?: 1.0
        val engine = engine

        if (!ready || engine == null || text.isNullOrBlank()) {
            result.success(false)
            return
        }

        // Pick the installed voice first: setting a voice can reset rate and
        // pitch on some engines, so they are applied afterwards.
        val voice = selectVoice(locale)
        if (voice != null) {
            engine.voice = voice
        } else {
            // No installed voice in this language: ask the engine to fall back
            // to its default for the language rather than going silent.
            engine.language = Locale.forLanguageTag(locale)
        }
        // 0.5 is normal speed on Android; the app's 0.5..1.5 maps onto it.
        engine.setSpeechRate((rate * 0.5).toFloat().coerceIn(0.1f, 1.0f))
        engine.setPitch(pitch.toFloat().coerceIn(0.1f, 2.0f))

        val utteranceId = UUID.randomUUID().toString()
        val params = Bundle().apply {
            putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId)
            putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume.toFloat().coerceIn(0f, 1f))
        }
        val queued = engine.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
        result.success(queued == TextToSpeech.SUCCESS)
    }

    /**
     * Whether any installed voice can speak [tag]. The engine's own language
     * check is tried first; when it says no, any voice in the same language is
     * accepted so a missing regional variant does not silence narration.
     */
    private fun hasVoiceFor(tag: String): Boolean {
        val engine = engine ?: return false
        return try {
            val status = engine.isLanguageAvailable(Locale.forLanguageTag(tag))
            status >= TextToSpeech.LANG_AVAILABLE || selectVoice(tag) != null
        } catch (_: Exception) {
            false
        }
    }

    /**
     * The best installed voice for a BCP-47 [tag].
     *
     * Ranking, highest first: same country, high quality, any country set.
     * On-device (offline) voices are preferred so the narrator keeps the same
     * identity and never needs a network. Returns null when the engine exposes
     * no voice list or nothing matches the language.
     */
    private fun selectVoice(tag: String): Voice? {
        val engine = engine ?: return null
        val wanted = Locale.forLanguageTag(tag)
        val voices =
            try {
                engine.voices?.filter {
                    it.locale.language.equals(wanted.language, ignoreCase = true)
                }
            } catch (_: Exception) {
                null
            }
        if (voices.isNullOrEmpty()) return null

        // Prefer voices that can speak right now: installed on the device and
        // not requiring a network. Google's engine advertises absent voices as
        // "notInstalled" but still lists them.
        val usable =
            voices.filter { voice ->
                !voice.isNetworkConnectionRequired &&
                    voice.features.none { it.equals("notInstalled", ignoreCase = true) }
            }
        val pool = usable.ifEmpty { voices }
        return pool.maxByOrNull { voice ->
            var score = 0
            if (voice.locale.country.equals(wanted.country, ignoreCase = true)) score += 8
            if (voice.quality >= Voice.QUALITY_HIGH) score += 4
            if (voice.locale.country.isNotEmpty()) score += 1
            score
        }
    }

    private fun notifyDart(method: String, utteranceId: String?) {
        val channel = channel ?: return
        runOnUiThread { channel.invokeMethod(method, utteranceId) }
    }

    override fun onDestroy() {
        engine?.stop()
        engine?.shutdown()
        engine = null
        ready = false
        channel?.setMethodCallHandler(null)
        channel = null
        super.onDestroy()
    }
}
