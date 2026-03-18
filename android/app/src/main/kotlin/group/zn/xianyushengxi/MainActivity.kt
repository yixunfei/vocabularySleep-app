package group.zn.xianyushengxi

import android.Manifest
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
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
import android.provider.CalendarContract
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
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val reminderChannelName = "vocabulary_sleep/reminder"
    private val systemSpeechChannelName = "vocabulary_sleep/system_speech"
    private val systemCalendarChannelName = "vocabulary_sleep/system_calendar"

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
    private var speechUsingIntentActivity = false
    private var ignoreNextSpeechIntentResult = false

    private var pendingCalendarResult: MethodChannel.Result? = null
    private var pendingCalendarMethod: String? = null
    private var pendingCalendarArguments: Map<*, *>? = null

    companion object {
        private const val speechPermissionRequestCode = 44102
        private const val calendarPermissionRequestCode = 44103
        private const val speechIntentRequestCode = 44104
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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            systemCalendarChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "upsertTodoReminder" -> {
                    upsertTodoReminder(call.arguments as? Map<*, *>, result)
                }

                "removeTodoReminder" -> {
                    removeTodoReminder(call.arguments as? Map<*, *>, result)
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
            if (requestCode != calendarPermissionRequestCode) {
                return
            }

            val result = pendingCalendarResult
            val method = pendingCalendarMethod
            val arguments = pendingCalendarArguments
            pendingCalendarResult = null
            pendingCalendarMethod = null
            pendingCalendarArguments = null
            if (result == null || method == null) {
                return
            }

            val granted =
                grantResults.isNotEmpty() &&
                    grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            if (!granted) {
                result.success(
                    buildCalendarResult(success = false, errorCode = "permission_denied"),
                )
                return
            }

            when (method) {
                "upsertTodoReminder" -> {
                    result.success(upsertTodoReminderInternal(arguments))
                }

                "removeTodoReminder" -> {
                    result.success(removeTodoReminderInternal(arguments))
                }

                else -> {
                    result.success(buildCalendarResult(success = false, errorCode = "failed"))
                }
            }
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != speechIntentRequestCode) {
            return
        }

        val shouldIgnore = ignoreNextSpeechIntentResult
        ignoreNextSpeechIntentResult = false
        speechListening = false
        speechUsingIntentActivity = false

        if (shouldIgnore) {
            clearSpeechState()
            return
        }

        updateSpeechTranscriptFromIntent(data)
        speechErrorCode = when {
            resultCode == RESULT_OK && speechTranscript.isNotBlank() -> null
            resultCode == RESULT_CANCELED -> "cancelled"
            else -> "no_match"
        }
        speechFinalized = true
        finishPendingSpeechStop(force = true)
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

        val languageTag = readSpeechLanguageTag(arguments)
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            if (canLaunchSpeechRecognitionIntent()) {
                result.success(startSpeechRecognitionIntent(languageTag))
                return
            }
            result.success(buildSpeechCommandResult(success = false, errorCode = "unavailable"))
            return
        }

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
            if (canLaunchSpeechRecognitionIntent()) {
                return startSpeechRecognitionIntent(languageTag)
            }
            return buildSpeechCommandResult(success = false, errorCode = "unavailable")
        }

        return try {
            speechLocale = resolveSpeechLocale(languageTag)
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).also { recognizer ->
                recognizer.setRecognitionListener(createRecognitionListener())
            }

            val intent = buildSpeechRecognitionIntent(languageTag).apply {
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
            }

            speechListening = true
            speechRecognizer?.startListening(intent)
            buildSpeechCommandResult(success = true, errorCode = null)
        } catch (error: Throwable) {
            destroySpeechRecognizer()
            clearSpeechState()
            if (canLaunchSpeechRecognitionIntent()) {
                return startSpeechRecognitionIntent(languageTag)
            }
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
        ignoreNextSpeechIntentResult = speechUsingIntentActivity

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

    private fun updateSpeechTranscriptFromIntent(data: Intent?) {
        val matches = data
            ?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
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
            ?.replace('_', '-')
            ?.takeIf { it.isNotEmpty() }
    }

    private fun canLaunchSpeechRecognitionIntent(): Boolean {
        val intent = buildSpeechRecognitionIntent(languageTag = null)
        return intent.resolveActivity(packageManager) != null
    }

    private fun buildSpeechRecognitionIntent(languageTag: String?): Intent {
        val resolvedLanguageTag = resolveSpeechLocale(languageTag)
        return Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak now")
            if (!resolvedLanguageTag.isNullOrBlank()) {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, resolvedLanguageTag)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, resolvedLanguageTag)
            }
        }
    }

    private fun startSpeechRecognitionIntent(languageTag: String?): Map<String, Any?> {
        if (!canLaunchSpeechRecognitionIntent()) {
            return buildSpeechCommandResult(success = false, errorCode = "unavailable")
        }

        clearSpeechState()
        speechLocale = resolveSpeechLocale(languageTag)
        speechUsingIntentActivity = true
        speechListening = true
        ignoreNextSpeechIntentResult = false

        return try {
            startActivityForResult(buildSpeechRecognitionIntent(languageTag), speechIntentRequestCode)
            buildSpeechCommandResult(success = true, errorCode = null)
        } catch (error: Throwable) {
            clearSpeechState()
            buildSpeechCommandResult(
                success = false,
                errorCode = "start_failed",
                errorMessage = error.message,
            )
        }
    }

    private fun resolveSpeechLocale(languageTag: String?): String? {
        val raw = languageTag?.trim()?.replace('_', '-') ?: ""
        if (raw.isEmpty() || raw.equals("auto", ignoreCase = true) || raw.equals("system", ignoreCase = true)) {
            return Locale.getDefault().toLanguageTag()
        }

        val normalized = when (raw.lowercase(Locale.US)) {
            "en" -> "en-US"
            "en-gb" -> "en-GB"
            "zh", "zh-cn", "zh-hans" -> "zh-CN"
            "zh-tw", "zh-hk", "zh-hant" -> "zh-TW"
            "ja" -> "ja-JP"
            "ko" -> "ko-KR"
            "de" -> "de-DE"
            "fr" -> "fr-FR"
            "es" -> "es-ES"
            "pt" -> "pt-BR"
            "it" -> "it-IT"
            "ru" -> "ru-RU"
            else -> raw
        }
        val locale = Locale.forLanguageTag(normalized)
        return locale.toLanguageTag().takeIf { it.isNotBlank() } ?: normalized
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
        speechUsingIntentActivity = false
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

    private fun upsertTodoReminder(
        arguments: Map<*, *>?,
        result: MethodChannel.Result,
    ) {
        if (pendingCalendarResult != null) {
            result.success(buildCalendarResult(success = false, errorCode = "busy"))
            return
        }

        if (!ensureCalendarPermissions(arguments, result, "upsertTodoReminder")) {
            return
        }

        result.success(upsertTodoReminderInternal(arguments))
    }

    private fun removeTodoReminder(
        arguments: Map<*, *>?,
        result: MethodChannel.Result,
    ) {
        if (pendingCalendarResult != null) {
            result.success(buildCalendarResult(success = false, errorCode = "busy"))
            return
        }

        if (!ensureCalendarPermissions(arguments, result, "removeTodoReminder")) {
            return
        }

        result.success(removeTodoReminderInternal(arguments))
    }

    private fun ensureCalendarPermissions(
        arguments: Map<*, *>?,
        result: MethodChannel.Result,
        method: String,
    ): Boolean {
        val hasReadPermission =
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALENDAR) ==
                PackageManager.PERMISSION_GRANTED
        val hasWritePermission =
            ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_CALENDAR) ==
                PackageManager.PERMISSION_GRANTED
        if (hasReadPermission && hasWritePermission) {
            return true
        }

        pendingCalendarResult = result
        pendingCalendarMethod = method
        pendingCalendarArguments = arguments
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR),
            calendarPermissionRequestCode,
        )
        return false
    }

    private fun upsertTodoReminderInternal(arguments: Map<*, *>?): Map<String, Any?> {
        if (arguments == null) {
            return buildCalendarResult(success = false, errorCode = "invalid_args")
        }

        val title = (arguments["title"] as? String)?.trim().orEmpty()
        val startAtMillis = (arguments["startAtMillis"] as? Number)?.toLong()
        val endAtMillis = (arguments["endAtMillis"] as? Number)?.toLong()
        if (title.isEmpty() || startAtMillis == null) {
            return buildCalendarResult(success = false, errorCode = "invalid_args")
        }

        val calendarId = resolveWritableCalendarId()
            ?: return buildCalendarResult(success = false, errorCode = "unavailable")
        val description = (arguments["description"] as? String)?.trim()
        val resolvedEndAtMillis =
            (endAtMillis ?: (startAtMillis + 30L * 60L * 1000L))
                .coerceAtLeast(startAtMillis + 60_000L)
        val reminderOffsets = readCalendarReminderOffsets(arguments)
        var eventId = (arguments["eventId"] as? String)?.trim()?.toLongOrNull()

        return try {
            val values = ContentValues().apply {
                put(CalendarContract.Events.CALENDAR_ID, calendarId)
                put(CalendarContract.Events.TITLE, title)
                put(CalendarContract.Events.DTSTART, startAtMillis)
                put(CalendarContract.Events.DTEND, resolvedEndAtMillis)
                put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
                put(CalendarContract.Events.HAS_ALARM, if (reminderOffsets.isNotEmpty()) 1 else 0)
                if (!description.isNullOrBlank()) {
                    put(CalendarContract.Events.DESCRIPTION, description)
                }
            }

            if (eventId != null) {
                val eventUri = ContentUris.withAppendedId(
                    CalendarContract.Events.CONTENT_URI,
                    eventId,
                )
                val updated = contentResolver.update(eventUri, values, null, null)
                if (updated <= 0) {
                    eventId = null
                }
            }

            if (eventId == null) {
                val insertedUri = contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
                    ?: return buildCalendarResult(success = false, errorCode = "failed")
                eventId = ContentUris.parseId(insertedUri)
            }

            syncCalendarReminders(eventId!!, reminderOffsets)
            buildCalendarResult(
                success = true,
                errorCode = null,
                eventId = eventId.toString(),
            )
        } catch (_: SecurityException) {
            buildCalendarResult(success = false, errorCode = "permission_denied")
        } catch (error: Throwable) {
            buildCalendarResult(
                success = false,
                errorCode = "failed",
                errorMessage = error.message,
            )
        }
    }

    private fun removeTodoReminderInternal(arguments: Map<*, *>?): Map<String, Any?> {
        val eventId = (arguments?.get("eventId") as? String)?.trim()?.toLongOrNull()
            ?: return buildCalendarResult(success = true, errorCode = "not_found")

        return try {
            val deleted = contentResolver.delete(
                ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId),
                null,
                null,
            )
            if (deleted > 0) {
                buildCalendarResult(success = true, errorCode = null)
            } else {
                buildCalendarResult(success = true, errorCode = "not_found")
            }
        } catch (_: SecurityException) {
            buildCalendarResult(success = false, errorCode = "permission_denied")
        } catch (error: Throwable) {
            buildCalendarResult(
                success = false,
                errorCode = "failed",
                errorMessage = error.message,
            )
        }
    }

    private fun resolveWritableCalendarId(): Long? {
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.IS_PRIMARY,
        )
        val selection =
            "${CalendarContract.Calendars.VISIBLE} = 1 AND " +
                "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL} >= ?"
        val selectionArgs = arrayOf(
            CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString(),
        )

        contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            "${CalendarContract.Calendars.IS_PRIMARY} DESC, ${CalendarContract.Calendars._ID} ASC",
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getLong(0)
            }
        }
        return null
    }

    private fun syncCalendarReminders(eventId: Long, reminderOffsets: List<Int>) {
        contentResolver.delete(
            CalendarContract.Reminders.CONTENT_URI,
            "${CalendarContract.Reminders.EVENT_ID} = ?",
            arrayOf(eventId.toString()),
        )
        if (reminderOffsets.isEmpty()) {
            return
        }
        for (minutes in reminderOffsets) {
            val reminderValues = ContentValues().apply {
                put(CalendarContract.Reminders.EVENT_ID, eventId)
                put(CalendarContract.Reminders.MINUTES, minutes.coerceAtLeast(0))
                put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
            }
            contentResolver.insert(CalendarContract.Reminders.CONTENT_URI, reminderValues)
        }
    }

    private fun readCalendarReminderOffsets(arguments: Map<*, *>?): List<Int> {
        val rawOffsets = arguments?.get("reminderOffsetsMinutes") as? List<*> ?: return emptyList()
        val offsets = mutableListOf<Int>()
        for (item in rawOffsets) {
            val parsed =
                when (item) {
                    is Number -> item.toInt()
                    else -> item?.toString()?.trim()?.toIntOrNull()
                } ?: continue
            val safeMinutes = parsed.coerceAtLeast(0)
            if (!offsets.contains(safeMinutes)) {
                offsets.add(safeMinutes)
            }
        }
        offsets.sort()
        return offsets
    }

    private fun buildCalendarResult(
        success: Boolean,
        errorCode: String?,
        eventId: String? = null,
        errorMessage: String? = null,
    ): Map<String, Any?> {
        return mutableMapOf<String, Any?>(
            "success" to success,
            "errorCode" to errorCode,
            "eventId" to eventId,
        ).apply {
            if (!errorMessage.isNullOrBlank()) {
                put("errorMessage", errorMessage)
            }
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
