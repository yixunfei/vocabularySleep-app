package com.example.flutter_app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val reminderChannelName = "vocabulary_sleep/reminder"
    private val systemSpeechChannelName = "vocabulary_sleep/system_speech"

    private val reminderHandler = Handler(Looper.getMainLooper())
    private val speechHandler = Handler(Looper.getMainLooper())

    private var reminderRingtone: Ringtone? = null
    private var reminderVibrator: Vibrator? = null
    private var stopReminderRunnable: Runnable? = null
    private var reminderTts: TextToSpeech? = null
    private var reminderTtsReady = false
    private var pendingAnnouncementText: String? = null
    private var pendingAnnouncementLanguageTag: String? = null

    private var speechRecognizer: SpeechRecognizer? = null
    private var pendingSpeechStartResult: MethodChannel.Result? = null
    private var pendingSpeechStopResult: MethodChannel.Result? = null
    private var pendingSpeechLanguageTag: String? = null
    private var speechStopTimeoutRunnable: Runnable? = null
    private var speechTranscript: String = ""
    private var speechLocale: String? = null
    private var speechErrorCode: String? = null
    private var speechListening = false
    private var speechFinalized = false

    companion object {
        private const val speechPermissionRequestCode = 44102
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            reminderChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "playReminder" -> {
                    result.success(playReminder(call.arguments as? Map<*, *>))
                }

                "stopReminder" -> {
                    stopReminder()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            systemSpeechChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    startSpeechRecognition(call.arguments as? Map<*, *>, result)
                }

                "stopListening" -> {
                    stopSpeechRecognition(result)
                }

                "cancelListening" -> {
                    cancelSpeechRecognition()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != speechPermissionRequestCode) {
            return
        }

        val result = pendingSpeechStartResult
        val languageTag = pendingSpeechLanguageTag
        pendingSpeechStartResult = null
        pendingSpeechLanguageTag = null
        if (result == null) {
            return
        }

        val granted =
            grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
        if (!granted) {
            result.success(
                buildSpeechCommandResult(success = false, errorCode = "permission_denied"),
            )
            return
        }

        result.success(startSpeechRecognitionInternal(languageTag))
    }

    override fun onDestroy() {
        stopReminder()
        cancelSpeechRecognition()
        reminderTts?.shutdown()
        reminderTts = null
        super.onDestroy()
    }

    private fun playReminder(arguments: Map<*, *>?): Boolean {
        if (arguments == null) return false

        val haptic = arguments["haptic"] as? Boolean ?: false
        val sound = arguments["sound"] as? Boolean ?: false
        if (!haptic && !sound) {
            stopReminder()
            return false
        }

        val durationMs = ((arguments["durationMs"] as? Number)?.toLong() ?: 0L)
            .coerceIn(1000L, 60000L)
        val customSoundPath = (arguments["customSoundPath"] as? String)?.trim()
        val announcementText = (arguments["announcementText"] as? String)?.trim()
        val announcementLanguageTag =
            (arguments["announcementLanguageTag"] as? String)?.trim()

        stopReminder()

        var handled = false
        if (sound) {
            handled = startReminderTone(customSoundPath) || handled
        }
        if (haptic) {
            handled = startReminderVibration() || handled
        }
        if (!announcementText.isNullOrBlank()) {
            speakAnnouncement(announcementText, announcementLanguageTag)
        }
        scheduleReminderStop(durationMs)
        return handled
    }

    private fun startSpeechRecognition(
        arguments: Map<*, *>?,
        result: MethodChannel.Result,
    ) {
        if (pendingSpeechStopResult != null || pendingSpeechStartResult != null || speechListening) {
            result.success(buildSpeechCommandResult(success = false, errorCode = "busy"))
            return
        }

        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            result.success(buildSpeechCommandResult(success = false, errorCode = "unavailable"))
            return
        }

        val languageTag = readSpeechLanguageTag(arguments)
        if (
            ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            pendingSpeechStartResult = result
            pendingSpeechLanguageTag = languageTag
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                speechPermissionRequestCode,
            )
            return
        }

        result.success(startSpeechRecognitionInternal(languageTag))
    }

    private fun startSpeechRecognitionInternal(languageTag: String?): Map<String, Any?> {
        clearSpeechState()
        destroySpeechRecognizer()

        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            return buildSpeechCommandResult(success = false, errorCode = "unavailable")
        }

        return try {
            speechLocale = languageTag
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).also { recognizer ->
                recognizer.setRecognitionListener(createRecognitionListener())
            }

            val intent = RecognizerIntent.ACTION_RECOGNIZE_SPEECH.let { action ->
                android.content.Intent(action).apply {
                    putExtra(
                        RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                        RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
                    )
                    putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                    putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
                    if (!languageTag.isNullOrBlank()) {
                        putExtra(RecognizerIntent.EXTRA_LANGUAGE, languageTag)
                        putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, languageTag)
                    }
                }
            }

            speechListening = true
            speechRecognizer?.startListening(intent)
            buildSpeechCommandResult(success = true, errorCode = null)
        } catch (error: Throwable) {
            destroySpeechRecognizer()
            clearSpeechState()
            buildSpeechCommandResult(
                success = false,
                errorCode = "start_failed",
                errorMessage = error.message,
            )
        }
    }

    private fun stopSpeechRecognition(result: MethodChannel.Result) {
        if (pendingSpeechStopResult != null) {
            result.success(buildSpeechRecognitionResult(errorCode = "busy"))
            return
        }

        if (speechFinalized || (speechRecognizer == null && (speechTranscript.isNotBlank() || !speechErrorCode.isNullOrBlank()))) {
            result.success(buildSpeechRecognitionResult())
            clearSpeechState()
            return
        }

        if (speechRecognizer == null) {
            result.success(buildSpeechRecognitionResult(errorCode = "not_listening"))
            return
        }

        pendingSpeechStopResult = result
        speechListening = false
        scheduleSpeechStopTimeout()

        try {
            speechRecognizer?.stopListening()
        } catch (error: Throwable) {
            cancelSpeechStopTimeout()
            pendingSpeechStopResult = null
            result.success(
                buildSpeechRecognitionResult(
                    errorCode = "stop_failed",
                    errorMessage = error.message,
                ),
            )
            destroySpeechRecognizer()
            clearSpeechState()
        }
    }

    private fun cancelSpeechRecognition() {
        cancelSpeechStopTimeout()

        try {
            speechRecognizer?.cancel()
        } catch (_: Throwable) {
            // Best-effort cleanup.
        }
        destroySpeechRecognizer()

        pendingSpeechStartResult?.success(
            buildSpeechCommandResult(success = false, errorCode = "cancelled"),
        )
        pendingSpeechStartResult = null
        pendingSpeechLanguageTag = null

        pendingSpeechStopResult?.let { stopResult ->
            speechErrorCode = "cancelled"
            speechFinalized = true
            stopResult.success(buildSpeechRecognitionResult())
        }
        pendingSpeechStopResult = null
        clearSpeechState()
    }

    private fun createRecognitionListener(): RecognitionListener {
        return object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) = Unit

            override fun onBeginningOfSpeech() = Unit

            override fun onRmsChanged(rmsdB: Float) = Unit

            override fun onBufferReceived(buffer: ByteArray?) = Unit

            override fun onEndOfSpeech() {
                speechListening = false
            }

            override fun onError(error: Int) {
                speechErrorCode = mapSpeechErrorCode(error)
                speechFinalized = true
                speechListening = false
                destroySpeechRecognizer()
                finishPendingSpeechStop(force = true)
            }

            override fun onResults(results: Bundle?) {
                updateSpeechTranscript(results)
                speechErrorCode = null
                speechFinalized = true
                speechListening = false
                destroySpeechRecognizer()
                finishPendingSpeechStop(force = true)
            }

            override fun onPartialResults(partialResults: Bundle?) {
                updateSpeechTranscript(partialResults)
            }

            override fun onEvent(eventType: Int, params: Bundle?) = Unit
        }
    }

    private fun finishPendingSpeechStop(force: Boolean) {
        if (!force || pendingSpeechStopResult == null) {
            return
        }
        cancelSpeechStopTimeout()
        val stopResult = pendingSpeechStopResult
        pendingSpeechStopResult = null
        destroySpeechRecognizer()
        stopResult?.success(buildSpeechRecognitionResult())
        clearSpeechState()
    }

    private fun scheduleSpeechStopTimeout() {
        cancelSpeechStopTimeout()
        val runnable = Runnable {
            speechFinalized = true
            finishPendingSpeechStop(force = true)
        }
        speechStopTimeoutRunnable = runnable
        speechHandler.postDelayed(runnable, 1800L)
    }

    private fun cancelSpeechStopTimeout() {
        speechStopTimeoutRunnable?.let(speechHandler::removeCallbacks)
        speechStopTimeoutRunnable = null
    }

    private fun updateSpeechTranscript(results: Bundle?) {
        val matches = results
            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            ?.map { it.trim() }
            ?.filter { it.isNotEmpty() }
            ?: emptyList()
        if (matches.isNotEmpty()) {
            speechTranscript = matches.first()
        }
    }

    private fun readSpeechLanguageTag(arguments: Map<*, *>?): String? {
        return (arguments?.get("languageTag") as? String)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
    }

    private fun buildSpeechCommandResult(
        success: Boolean,
        errorCode: String?,
        errorMessage: String? = null,
    ): Map<String, Any?> {
        return mutableMapOf<String, Any?>(
            "success" to success,
            "errorCode" to errorCode,
        ).apply {
            if (!errorMessage.isNullOrBlank()) {
                put("errorMessage", errorMessage)
            }
        }
    }

    private fun buildSpeechRecognitionResult(
        errorCode: String? = null,
        errorMessage: String? = null,
    ): Map<String, Any?> {
        val text = speechTranscript.trim()
        val resolvedErrorCode = when {
            !errorCode.isNullOrBlank() -> errorCode
            text.isNotEmpty() -> null
            !speechErrorCode.isNullOrBlank() -> speechErrorCode
            else -> "no_match"
        }
        return mutableMapOf<String, Any?>(
            "success" to (text.isNotEmpty() && resolvedErrorCode == null),
            "text" to text.takeIf { it.isNotEmpty() },
            "locale" to speechLocale,
            "errorCode" to resolvedErrorCode,
        ).apply {
            if (!errorMessage.isNullOrBlank()) {
                put("errorMessage", errorMessage)
            }
        }
    }

    private fun clearSpeechState() {
        speechTranscript = ""
        speechLocale = null
        speechErrorCode = null
        speechListening = false
        speechFinalized = false
    }

    private fun destroySpeechRecognizer() {
        try {
            speechRecognizer?.destroy()
        } catch (_: Throwable) {
            // Best-effort cleanup.
        } finally {
            speechRecognizer = null
        }
    }

    private fun mapSpeechErrorCode(error: Int): String {
        return when (error) {
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "permission_denied"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "busy"
            SpeechRecognizer.ERROR_NO_MATCH,
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT,
            -> "no_match"
            SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED,
            SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE,
            -> "language_not_supported"
            SpeechRecognizer.ERROR_NETWORK,
            SpeechRecognizer.ERROR_NETWORK_TIMEOUT,
            SpeechRecognizer.ERROR_SERVER,
            -> "unavailable"
            else -> "failed"
        }
    }

    private fun speakAnnouncement(text: String, languageTag: String?) {
        val cleanText = text.trim()
        if (cleanText.isEmpty()) return

        val tts = reminderTts
        if (tts == null) {
            pendingAnnouncementText = cleanText
            pendingAnnouncementLanguageTag = languageTag
            reminderTts = TextToSpeech(applicationContext) { status ->
                reminderTtsReady = status == TextToSpeech.SUCCESS
                if (!reminderTtsReady) return@TextToSpeech
                val pendingText = pendingAnnouncementText
                val pendingLanguage = pendingAnnouncementLanguageTag
                pendingAnnouncementText = null
                pendingAnnouncementLanguageTag = null
                if (!pendingText.isNullOrBlank()) {
                    speakAnnouncement(pendingText, pendingLanguage)
                }
            }
            return
        }

        if (!reminderTtsReady) {
            pendingAnnouncementText = cleanText
            pendingAnnouncementLanguageTag = languageTag
            return
        }

        languageTag
            ?.takeIf { it.isNotBlank() }
            ?.let { tag ->
                val locale = Locale.forLanguageTag(tag)
                val availability = tts.isLanguageAvailable(locale)
                if (availability >= TextToSpeech.LANG_AVAILABLE) {
                    tts.language = locale
                }
            }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            tts.speak(cleanText, TextToSpeech.QUEUE_FLUSH, null, "focus_reminder")
        } else {
            @Suppress("DEPRECATION")
            tts.speak(cleanText, TextToSpeech.QUEUE_FLUSH, null)
        }
    }

    private fun startReminderTone(customSoundPath: String?): Boolean {
        val ringtone = createReminderRingtone(customSoundPath) ?: return false
        return try {
            ringtone.play()
            reminderRingtone = ringtone
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun createReminderRingtone(customSoundPath: String?): Ringtone? {
        val customUri = customSoundPath
            ?.takeIf { it.isNotBlank() }
            ?.let { path ->
                val file = File(path)
                if (file.exists()) Uri.fromFile(file) else null
            }
        val defaultUri =
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val targetUri = customUri ?: defaultUri ?: return null
        val ringtone = RingtoneManager.getRingtone(applicationContext, targetUri) ?: return null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            ringtone.audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            ringtone.isLooping = true
        }
        return ringtone
    }

    private fun startReminderVibration(): Boolean {
        val vibrator = resolveVibrator() ?: return false
        if (!vibrator.hasVibrator()) return false

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(
                    VibrationEffect.createWaveform(
                        longArrayOf(0, 280, 180, 420),
                        0,
                    ),
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(longArrayOf(0, 280, 180, 420), 0)
            }
            reminderVibrator = vibrator
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun resolveVibrator(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun scheduleReminderStop(durationMs: Long) {
        stopReminderRunnable?.let(reminderHandler::removeCallbacks)
        val runnable = Runnable { stopReminder() }
        stopReminderRunnable = runnable
        reminderHandler.postDelayed(runnable, durationMs)
    }

    private fun stopReminder() {
        stopReminderRunnable?.let(reminderHandler::removeCallbacks)
        stopReminderRunnable = null

        try {
            reminderRingtone?.stop()
        } catch (_: Throwable) {
            // Best-effort cleanup.
        } finally {
            reminderRingtone = null
        }

        try {
            reminderVibrator?.cancel()
        } catch (_: Throwable) {
            // Best-effort cleanup.
        } finally {
            reminderVibrator = null
        }

        try {
            reminderTts?.stop()
        } catch (_: Throwable) {
            // Best-effort cleanup.
        }
    }
}
