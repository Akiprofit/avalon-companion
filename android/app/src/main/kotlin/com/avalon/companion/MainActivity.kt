package com.avalon.companion

import android.app.Activity
import android.content.Intent
import android.media.MediaPlayer
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale
import java.util.UUID

/**
 * Hosts the Flutter UI and exposes the platform text-to-speech engine.
 *
 * The app speaks narration lines and nothing else. No text is logged, stored or
 * sent anywhere: [TextToSpeech] synthesises on the device.
 *
 * The second channel carries the two behaviours only the activity can provide:
 * the keep-screen-on flag during a live match, and the night ambience loop.
 */
class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "com.avalon.companion/tts"
        const val HOST_CHANNEL = "com.avalon.companion/host"
        const val CLIP_CHANNEL = "com.avalon.companion/clips"
        const val VOICE_CHANNEL = "com.avalon.companion/voices"

        /** Request code for picking a voice zip. */
        const val PICK_ZIP_REQUEST = 4211

        /** Imported voices are unpacked here, next to the app's own storage. */
        const val VOICES_DIR = "voices"

        /** The Royal Chronicler's default: British English. */
        const val DEFAULT_LOCALE = "en-GB"

        /** The bed sits under a voice, so it stays well below it. */
        const val AMBIENT_VOLUME = 0.35f

        /** Recorded narration lives in the Flutter asset bundle. */
        const val CLIP_ROOT = "flutter_assets/"
    }

    private var channel: MethodChannel? = null
    private var engine: TextToSpeech? = null
    private var ready = false
    private var pendingInit: MethodChannel.Result? = null

    private var hostChannel: MethodChannel? = null
    private var ambient: MediaPlayer? = null

    private var clipChannel: MethodChannel? = null
    private var clipPlayer: MediaPlayer? = null

    private var voiceChannel: MethodChannel? = null
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val methodChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel = methodChannel
        methodChannel.setMethodCallHandler { call, result -> handle(call, result) }

        val host = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HOST_CHANNEL)
        hostChannel = host
        host.setMethodCallHandler { call, result ->
            when (call.method) {
                "setKeepAwake" -> {
                    setKeepAwake(call.arguments == true)
                    result.success(true)
                }
                "setAmbient" -> {
                    setAmbient(call.arguments == true)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        val clips = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CLIP_CHANNEL)
        clipChannel = clips
        clips.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAvailable" -> result.success(true)
                "play" -> playClip(call, result)
                "stop" -> {
                    stopClip()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Voice packs: where imported voices live, and the system picker that
        // hands the app a zip. The file is copied into the cache first, so the
        // import works whatever the phone's storage provider is.
        val voices = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOICE_CHANNEL)
        voiceChannel = voices
        voices.setMethodCallHandler { call, result ->
            when (call.method) {
                "directory" -> result.success(voicesDirectory().absolutePath)
                "pickZip" -> pickZip(result)
                else -> result.notImplemented()
            }
        }
    }

    /** `<app files>/voices`: the only place an imported voice is read from. */
    private fun voicesDirectory(): File = File(filesDir, VOICES_DIR).apply { mkdirs() }

    /**
     * Opens the system file browser for a zip.
     *
     * The picker returns a content URI, which is not a path the player can use,
     * so the file is copied into the app cache and that path is handed back.
     * The Dart side deletes the copy once the pack is unpacked.
     */
    private fun pickZip(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.success(null)
            return
        }
        pendingPick = result
        try {
            val intent =
                Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    // Zip mime types are unreliable across providers, so the
                    // picker is opened wide and the archive is validated after.
                    type = "*/*"
                }
            startActivityForResult(intent, PICK_ZIP_REQUEST)
        } catch (_: Exception) {
            pendingPick = null
            result.success(null)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == PICK_ZIP_REQUEST) {
            val pending = pendingPick
            pendingPick = null
            val uri = data?.data
            if (resultCode != Activity.RESULT_OK || uri == null) {
                pending?.success(null)
                return
            }
            pending?.success(copyToCache(uri))
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    /** Copies the chosen document into the cache and returns its absolute path. */
    private fun copyToCache(uri: Uri): String? {
        return try {
            val name = displayName(uri) ?: "voice.zip"
            val safe = name.replace(Regex("[^A-Za-z0-9._-]"), "_").takeLast(80)
            val target = File(cacheDir, "import-${System.currentTimeMillis()}-$safe")
            contentResolver.openInputStream(uri)?.use { input ->
                target.outputStream().use { output -> input.copyTo(output) }
            } ?: return null
            if (target.length() > 0) target.absolutePath else null
        } catch (_: Exception) {
            null
        }
    }

    private fun displayName(uri: Uri): String? {
        return try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (!cursor.moveToFirst()) return null
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index < 0) null else cursor.getString(index)
                }
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Plays one recorded narration line.
     *
     * A bundled line is read straight from the APK's asset bundle; an imported
     * one is an ordinary file in app storage, addressed by its absolute path.
     * Everything is local either way: nothing is streamed or downloaded. The
     * line plays at the pace it was recorded; only the volume is adjustable.
     */
    private fun playClip(call: MethodCall, result: MethodChannel.Result) {
        val asset = call.argument<String>("asset")
        val volume = (call.argument<Double>("volume") ?: 1.0).toFloat().coerceIn(0f, 1f)
        if (asset.isNullOrBlank()) {
            result.success(false)
            return
        }

        runOnUiThread {
            stopClip()
            try {
                val player = MediaPlayer()
                if (asset.startsWith("/")) {
                    player.setDataSource(asset)
                } else {
                    val descriptor = assets.openFd(CLIP_ROOT + asset)
                    player.setDataSource(
                        descriptor.fileDescriptor,
                        descriptor.startOffset,
                        descriptor.length,
                    )
                    descriptor.close()
                }
                player.setVolume(volume, volume)
                player.setOnCompletionListener {
                    releaseClip(player)
                    notifyClips("onDone")
                }
                player.setOnErrorListener { failed, _, _ ->
                    releaseClip(failed)
                    notifyClips("onError")
                    true
                }
                player.prepare()
                player.start()
                clipPlayer = player
                result.success(true)
            } catch (_: Exception) {
                stopClip()
                result.success(false)
            }
        }
    }

    /** Releases the playing line, if any. Main thread only. */
    private fun stopClip() {
        runOnUiThread {
            val player = clipPlayer ?: return@runOnUiThread
            clipPlayer = null
            try {
                if (player.isPlaying) player.stop()
            } catch (_: Exception) {
                // Already finished.
            }
            try {
                player.release()
            } catch (_: Exception) {
                // Already released by the completion listener.
            }
        }
    }

    private fun releaseClip(player: MediaPlayer) {
        if (clipPlayer === player) clipPlayer = null
        try {
            player.release()
        } catch (_: Exception) {
            // Already gone.
        }
    }

    private fun notifyClips(method: String) {
        val channel = clipChannel ?: return
        runOnUiThread { channel.invokeMethod(method, null) }
    }

    /** Window flag, so the table never has to wake the phone mid-quest. */
    private fun setKeepAwake(on: Boolean) {
        runOnUiThread {
            if (on) {
                window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            }
        }
    }

    /** Starts or stops the looping night bed, shipped in `res/raw`. */
    private fun setAmbient(on: Boolean) {
        runOnUiThread {
            try {
                if (on) {
                    val player =
                        ambient
                            ?: MediaPlayer.create(this, R.raw.ambient_night)?.apply {
                                isLooping = true
                                setVolume(AMBIENT_VOLUME, AMBIENT_VOLUME)
                            }
                    ambient = player
                    player?.start()
                } else {
                    ambient?.stop()
                    ambient?.release()
                    ambient = null
                }
            } catch (_: Exception) {
                ambient = null
            }
        }
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
            "voices" -> {
                val locale = call.argument<String>("locale") ?: DEFAULT_LOCALE
                result.success(voicesFor(locale))
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
        val voiceId = call.argument<String>("voiceId")
        val engine = engine

        if (!ready || engine == null || text.isNullOrBlank()) {
            result.success(false)
            return
        }

        // Pick the installed voice first: setting a voice can reset rate and
        // pitch on some engines, so they are applied afterwards.
        val voice = voiceId?.let { exactVoice(it) } ?: selectVoice(locale)
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

    /**
     * The installed, offline voices that can speak [tag], best first.
     *
     * Same usability rule as [selectVoice]: a voice that needs the network or
     * is only advertised is not something the table can rely on, so it is not
     * offered in settings either.
     */
    private fun voicesFor(tag: String): List<Map<String, Any>> {
        val engine = engine ?: return emptyList()
        val wanted = Locale.forLanguageTag(tag)
        return try {
            engine.voices.orEmpty()
                .filter { it.locale.language.equals(wanted.language, ignoreCase = true) }
                .filter { voice ->
                    !voice.isNetworkConnectionRequired &&
                        voice.features.none { it.equals("notInstalled", ignoreCase = true) }
                }
                .sortedWith(
                    compareByDescending<Voice> {
                        it.locale.country.equals(wanted.country, ignoreCase = true)
                    }.thenByDescending { it.quality }
                )
                .map { voice ->
                    mapOf(
                        "id" to voice.name,
                        "name" to voice.name,
                        "locale" to voice.locale.toLanguageTag(),
                        "network" to voice.isNetworkConnectionRequired,
                    )
                }
        } catch (_: Exception) {
            emptyList()
        }
    }

    /** The voice with exactly [name], if the engine still has it installed. */
    private fun exactVoice(name: String): Voice? {
        val engine = engine ?: return null
        return try {
            engine.voices?.firstOrNull { it.name == name }
        } catch (_: Exception) {
            null
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
        ambient?.release()
        ambient = null
        hostChannel?.setMethodCallHandler(null)
        hostChannel = null
        stopClip()
        clipChannel?.setMethodCallHandler(null)
        clipChannel = null
        pendingPick?.success(null)
        pendingPick = null
        voiceChannel?.setMethodCallHandler(null)
        voiceChannel = null
        super.onDestroy()
    }
}
