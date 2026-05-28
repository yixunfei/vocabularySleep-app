package group.zn.xianyushengxi

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.content.getSystemService
import org.json.JSONObject

data class FakeCallSpec(
    val callId: Int,
    val triggerAtMillis: Long,
    val callerName: String?,
    val callerNumber: String?,
    val callerLocation: String?,
    val callerTag: String?,
    val ringtoneEnabled: Boolean,
    val vibrationEnabled: Boolean,
    val incomingBackgroundPath: String?,
    val incomingBackgroundStyle: String?,
    val inCallBackgroundPath: String?,
    val inCallBackgroundStyle: String?,
) {
    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("callId", callId)
            put("triggerAtMillis", triggerAtMillis)
            put("callerName", callerName)
            put("callerNumber", callerNumber)
            put("callerLocation", callerLocation)
            put("callerTag", callerTag)
            put("ringtoneEnabled", ringtoneEnabled)
            put("vibrationEnabled", vibrationEnabled)
            put("incomingBackgroundPath", incomingBackgroundPath)
            put("incomingBackgroundStyle", incomingBackgroundStyle)
            put("inCallBackgroundPath", inCallBackgroundPath)
            put("inCallBackgroundStyle", inCallBackgroundStyle)
        }
    }

    companion object {
        fun fromJson(json: JSONObject): FakeCallSpec? {
            val callId = json.optInt("callId", 0)
            val triggerAtMillis = json.optLong("triggerAtMillis", 0L)
            if (callId <= 0 || triggerAtMillis <= 0L) {
                return null
            }
            return FakeCallSpec(
                callId = callId,
                triggerAtMillis = triggerAtMillis,
                callerName = json.optString("callerName", "").trim().ifEmpty { null },
                callerNumber = json.optString("callerNumber", "").trim().ifEmpty { null },
                callerLocation = json.optString("callerLocation", "").trim().ifEmpty { null },
                callerTag = json.optString("callerTag", "").trim().ifEmpty { null },
                ringtoneEnabled = json.optBoolean("ringtoneEnabled", true),
                vibrationEnabled = json.optBoolean("vibrationEnabled", true),
                incomingBackgroundPath =
                    json.optString("incomingBackgroundPath", "").trim().ifEmpty { null },
                incomingBackgroundStyle =
                    json.optString("incomingBackgroundStyle", "").trim().ifEmpty { null },
                inCallBackgroundPath =
                    json.optString("inCallBackgroundPath", "").trim().ifEmpty { null },
                inCallBackgroundStyle =
                    json.optString("inCallBackgroundStyle", "").trim().ifEmpty { null },
            )
        }
    }
}

object FakeCallScheduler {
    private const val preferenceName = "toolbox_fake_calls"
    private const val preferenceKey = "scheduled_items"
    const val channelId = "toolbox_fake_incoming_call"

    fun schedule(context: Context, spec: FakeCallSpec): Boolean {
        ensureNotificationChannel(context)
        storeSpec(context, spec)

        val alarmManager = context.getSystemService<AlarmManager>() ?: return false
        val pendingIntent = buildTriggerPendingIntent(context, spec)
        cancelAlarm(context, spec.callId)
        val triggerAt = spec.triggerAtMillis.coerceAtLeast(System.currentTimeMillis() + 1000L)

        return try {
            alarmManager.setAlarmClock(
                AlarmManager.AlarmClockInfo(
                    triggerAt,
                    buildShowIntent(context, spec),
                ),
                pendingIntent,
            )
            true
        } catch (_: Throwable) {
            try {
                if (
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                        alarmManager.canScheduleExactAlarms()
                ) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAt,
                        pendingIntent,
                    )
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAt,
                        pendingIntent,
                    )
                } else {
                    @Suppress("DEPRECATION")
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                }
                true
            } catch (_: Throwable) {
                false
            }
        }
    }

    fun cancel(context: Context, callId: Int) {
        if (callId <= 0) {
            return
        }
        cancelAlarm(context, callId)
        val all = loadAll(context).toMutableMap()
        all.remove(callId)
        saveAll(context, all)
        try {
            context.getSystemService<NotificationManager>()?.cancel(callId)
        } catch (_: Throwable) {
            // Best-effort cleanup only.
        }
    }

    fun consume(context: Context, callId: Int): FakeCallSpec? {
        val all = loadAll(context).toMutableMap()
        val spec = all.remove(callId)
        saveAll(context, all)
        return spec
    }

    fun rescheduleAll(context: Context) {
        val now = System.currentTimeMillis()
        val all = loadAll(context).toMutableMap()
        val iterator = all.iterator()
        while (iterator.hasNext()) {
            val spec = iterator.next().value
            if (spec.triggerAtMillis < now - 60_000L) {
                cancelAlarm(context, spec.callId)
                iterator.remove()
                continue
            }
            schedule(context, spec)
        }
        saveAll(context, all)
    }

    fun ensureNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val manager = context.getSystemService<NotificationManager>() ?: return
        if (manager.getNotificationChannel(channelId) != null) {
            return
        }
        val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val channel = NotificationChannel(
            channelId,
            localizedText(context, zh = "模拟来电", en = "Fake incoming calls"),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = localizedText(
                context,
                zh = "按指定时间全屏播放模拟来电",
                en = "Full-screen fake incoming call playback",
            )
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 300, 220, 520)
            setSound(
                ringtoneUri,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    fun buildActivityIntent(
        context: Context,
        spec: FakeCallSpec,
    ): Intent {
        return Intent(context, FakeIncomingCallActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS,
            )
            putExtra("callId", spec.callId)
            putExtra("title", localizedText(context, zh = "模拟来电", en = "Fake incoming call"))
            putExtra("description", localizedText(context, zh = "来电中", en = "Incoming call"))
            putExtra("callerName", spec.callerName)
            putExtra("callerNumber", spec.callerNumber)
            putExtra("callerLocation", spec.callerLocation)
            putExtra("callerTag", spec.callerTag)
            putExtra("ringtoneEnabled", spec.ringtoneEnabled)
            putExtra("vibrationEnabled", spec.vibrationEnabled)
            putExtra("incomingBackgroundPath", spec.incomingBackgroundPath)
            putExtra("incomingBackgroundStyle", spec.incomingBackgroundStyle)
            putExtra("inCallBackgroundPath", spec.inCallBackgroundPath)
            putExtra("inCallBackgroundStyle", spec.inCallBackgroundStyle)
        }
    }

    private fun storeSpec(context: Context, spec: FakeCallSpec) {
        val all = loadAll(context).toMutableMap()
        all[spec.callId] = spec
        saveAll(context, all)
    }

    private fun loadAll(context: Context): Map<Int, FakeCallSpec> {
        val preferences = context.getSharedPreferences(preferenceName, Context.MODE_PRIVATE)
        val raw = preferences.getString(preferenceKey, null)?.trim().orEmpty()
        if (raw.isEmpty()) {
            return emptyMap()
        }
        return try {
            val root = JSONObject(raw)
            buildMap {
                val keys = root.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    val callId = key.toIntOrNull() ?: continue
                    val spec = FakeCallSpec.fromJson(root.optJSONObject(key) ?: continue)
                        ?: continue
                    put(callId, spec)
                }
            }
        } catch (_: Throwable) {
            emptyMap()
        }
    }

    private fun saveAll(context: Context, specs: Map<Int, FakeCallSpec>) {
        val root = JSONObject()
        for ((callId, spec) in specs) {
            root.put(callId.toString(), spec.toJson())
        }
        context.getSharedPreferences(preferenceName, Context.MODE_PRIVATE)
            .edit()
            .putString(preferenceKey, root.toString())
            .apply()
    }

    private fun cancelAlarm(context: Context, callId: Int) {
        val alarmManager = context.getSystemService<AlarmManager>() ?: return
        val pendingIntent = buildTriggerPendingIntent(context, callId)
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
        buildShowIntent(context, callId).cancel()
    }

    private fun buildTriggerPendingIntent(
        context: Context,
        spec: FakeCallSpec,
    ): PendingIntent {
        val intent = Intent(context, FakeCallReceiver::class.java).apply {
            action = FakeCallReceiver.actionShow
            putExtra("callId", spec.callId)
            putExtra("callerName", spec.callerName)
            putExtra("callerNumber", spec.callerNumber)
            putExtra("callerLocation", spec.callerLocation)
            putExtra("callerTag", spec.callerTag)
            putExtra("ringtoneEnabled", spec.ringtoneEnabled)
            putExtra("vibrationEnabled", spec.vibrationEnabled)
            putExtra("incomingBackgroundPath", spec.incomingBackgroundPath)
            putExtra("incomingBackgroundStyle", spec.incomingBackgroundStyle)
            putExtra("inCallBackgroundPath", spec.inCallBackgroundPath)
            putExtra("inCallBackgroundStyle", spec.inCallBackgroundStyle)
        }
        return PendingIntent.getBroadcast(
            context,
            spec.callId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentMutabilityFlag(),
        )
    }

    private fun buildTriggerPendingIntent(context: Context, callId: Int): PendingIntent {
        val intent = Intent(context, FakeCallReceiver::class.java).apply {
            action = FakeCallReceiver.actionShow
            putExtra("callId", callId)
        }
        return PendingIntent.getBroadcast(
            context,
            callId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentMutabilityFlag(),
        )
    }

    private fun buildShowIntent(context: Context, spec: FakeCallSpec): PendingIntent {
        return PendingIntent.getActivity(
            context,
            spec.callId * 100 + 41,
            buildActivityIntent(context, spec),
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentMutabilityFlag(),
        )
    }

    private fun buildShowIntent(context: Context, callId: Int): PendingIntent {
        val intent = Intent(context, FakeIncomingCallActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra("callId", callId)
        }
        return PendingIntent.getActivity(
            context,
            callId * 100 + 41,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentMutabilityFlag(),
        )
    }

    private fun pendingIntentMutabilityFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }

    private fun localizedText(context: Context, zh: String, en: String): String {
        val language = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            context.resources.configuration.locales[0]?.language.orEmpty()
        } else {
            @Suppress("DEPRECATION")
            context.resources.configuration.locale.language.orEmpty()
        }
        return if (language.startsWith("zh")) zh else en
    }
}
