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

data class TodoReminderSpec(
    val todoId: Int,
    val title: String,
    val description: String?,
    val triggerAtMillis: Long,
    val dueAtMillis: Long,
    val mode: String,
    val presentationType: String,
    val stickyNotification: Boolean,
    val cancelOnOpen: Boolean,
    val callerName: String?,
    val callerNumber: String?,
    val callerLocation: String?,
    val callerTag: String?,
) {
    fun toJson(): JSONObject {
        return JSONObject().apply {
            put("todoId", todoId)
            put("title", title)
            put("description", description)
            put("triggerAtMillis", triggerAtMillis)
            put("dueAtMillis", dueAtMillis)
            put("mode", mode)
            put("presentationType", presentationType)
            put("stickyNotification", stickyNotification)
            put("cancelOnOpen", cancelOnOpen)
            put("callerName", callerName)
            put("callerNumber", callerNumber)
            put("callerLocation", callerLocation)
            put("callerTag", callerTag)
        }
    }

    companion object {
        fun fromJson(json: JSONObject): TodoReminderSpec? {
            val todoId = json.optInt("todoId", 0)
            val title = json.optString("title", "").trim()
            val triggerAtMillis = json.optLong("triggerAtMillis", 0L)
            val dueAtMillis = json.optLong("dueAtMillis", 0L)
            val mode = json.optString("mode", "notification").trim()
            val presentationType = json.optString("presentationType", mode).trim()
            if (todoId <= 0 || title.isEmpty() || triggerAtMillis <= 0L || dueAtMillis <= 0L) {
                return null
            }
            return TodoReminderSpec(
                todoId = todoId,
                title = title,
                description = json.optString("description", "").trim().ifEmpty { null },
                triggerAtMillis = triggerAtMillis,
                dueAtMillis = dueAtMillis,
                mode = mode.ifEmpty { "notification" },
                presentationType = presentationType.ifEmpty { mode.ifEmpty { "notification" } },
                stickyNotification = json.optBoolean("stickyNotification", false),
                cancelOnOpen = json.optBoolean("cancelOnOpen", true),
                callerName = json.optString("callerName", "").trim().ifEmpty { null },
                callerNumber = json.optString("callerNumber", "").trim().ifEmpty { null },
                callerLocation = json.optString("callerLocation", "").trim().ifEmpty { null },
                callerTag = json.optString("callerTag", "").trim().ifEmpty { null },
            )
        }
    }
}

object TodoReminderScheduler {
    private const val preferenceName = "todo_reminders"
    private const val preferenceKey = "scheduled_items"
    const val notificationChannelId = "todo_reminder_notification"
    const val alarmChannelId = "todo_reminder_alarm"
    const val fakeCallChannelId = "todo_fake_incoming_call"

    fun upsert(context: Context, spec: TodoReminderSpec) {
        storeSpec(context, spec)
        schedule(context, spec, allowImmediateFallback = true)
    }

    fun remove(context: Context, todoId: Int) {
        cancelAlarm(context, todoId)
        val all = loadAll(context).toMutableMap()
        all.remove(todoId)
        saveAll(context, all)
    }

    fun consume(context: Context, todoId: Int): TodoReminderSpec? {
        val all = loadAll(context).toMutableMap()
        val spec = all.remove(todoId)
        saveAll(context, all)
        return spec
    }

    fun rescheduleAll(context: Context) {
        val now = System.currentTimeMillis()
        val all = loadAll(context).toMutableMap()
        val iterator = all.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            val spec = entry.value
            if (spec.dueAtMillis < now - 60_000L) {
                cancelAlarm(context, spec.todoId)
                iterator.remove()
                continue
            }
            schedule(context, spec, allowImmediateFallback = false)
        }
        saveAll(context, all)
    }

    fun ensureNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        val manager = context.getSystemService<NotificationManager>() ?: return
        if (manager.getNotificationChannel(notificationChannelId) == null) {
            val notificationUri =
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val channel = NotificationChannel(
                notificationChannelId,
                "Todo reminders",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "App-managed todo reminder notifications"
                enableVibration(true)
                setSound(
                    notificationUri,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
            }
            manager.createNotificationChannel(channel)
        }
        if (manager.getNotificationChannel(alarmChannelId) == null) {
            val alarmUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val channel = NotificationChannel(
                alarmChannelId,
                "Todo alarms",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "App-managed todo alarm reminders"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 180, 420)
                setSound(
                    alarmUri,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build(),
                )
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(channel)
        }
        if (manager.getNotificationChannel(fakeCallChannelId) == null) {
            val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val channel = NotificationChannel(
                fakeCallChannelId,
                localizedText(context, zh = "模拟来电", en = "Fake incoming calls"),
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = localizedText(
                    context,
                    zh = "用于按时触发全屏模拟来电",
                    en = "Full-screen fake incoming call alerts",
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
    }

    private fun schedule(
        context: Context,
        spec: TodoReminderSpec,
        allowImmediateFallback: Boolean,
    ) {
        ensureNotificationChannels(context)
        val alarmManager = context.getSystemService<AlarmManager>() ?: return
        val triggerAt = when {
            spec.triggerAtMillis > System.currentTimeMillis() -> spec.triggerAtMillis
            allowImmediateFallback -> System.currentTimeMillis() + 1000L
            else -> spec.triggerAtMillis
        }
        val pendingIntent = buildPendingIntent(context, spec)
        cancelAlarm(context, spec.todoId)

        if (spec.presentationType.equals("fakeCall", ignoreCase = true)) {
            try {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(
                        triggerAt,
                        buildAlarmClockShowIntent(context, spec.todoId),
                    ),
                    pendingIntent,
                )
                return
            } catch (_: Throwable) {
                // Fall through to the regular reminder scheduling path.
            }
        }

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
        } catch (_: Throwable) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    pendingIntent,
                )
            } else {
                @Suppress("DEPRECATION")
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            }
        }
    }

    private fun storeSpec(context: Context, spec: TodoReminderSpec) {
        val all = loadAll(context).toMutableMap()
        all[spec.todoId] = spec
        saveAll(context, all)
    }

    private fun loadAll(context: Context): Map<Int, TodoReminderSpec> {
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
                    val todoId = key.toIntOrNull() ?: continue
                    val spec = TodoReminderSpec.fromJson(root.optJSONObject(key) ?: continue)
                        ?: continue
                    put(todoId, spec)
                }
            }
        } catch (_: Throwable) {
            emptyMap()
        }
    }

    private fun saveAll(
        context: Context,
        specs: Map<Int, TodoReminderSpec>,
    ) {
        val root = JSONObject()
        for ((todoId, spec) in specs) {
            root.put(todoId.toString(), spec.toJson())
        }
        context.getSharedPreferences(preferenceName, Context.MODE_PRIVATE)
            .edit()
            .putString(preferenceKey, root.toString())
            .apply()
    }

    private fun cancelAlarm(context: Context, todoId: Int) {
        val alarmManager = context.getSystemService<AlarmManager>() ?: return
        val pendingIntent = buildPendingIntent(context, todoId)
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
        buildAlarmClockShowIntent(context, todoId).cancel()
    }

    private fun buildPendingIntent(context: Context, spec: TodoReminderSpec): PendingIntent {
        val intent = Intent(context, TodoReminderReceiver::class.java).apply {
            action = TodoReminderReceiver.actionShow
            putExtra("todoId", spec.todoId)
            putExtra("title", spec.title)
            putExtra("description", spec.description)
            putExtra("dueAtMillis", spec.dueAtMillis)
            putExtra("mode", spec.mode)
            putExtra("presentationType", spec.presentationType)
            putExtra("stickyNotification", spec.stickyNotification)
            putExtra("cancelOnOpen", spec.cancelOnOpen)
            putExtra("callerName", spec.callerName)
            putExtra("callerNumber", spec.callerNumber)
            putExtra("callerLocation", spec.callerLocation)
            putExtra("callerTag", spec.callerTag)
        }
        return PendingIntent.getBroadcast(
            context,
            spec.todoId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentMutabilityFlag(),
        )
    }

    private fun buildPendingIntent(context: Context, todoId: Int): PendingIntent {
        val intent = Intent(context, TodoReminderReceiver::class.java).apply {
            action = TodoReminderReceiver.actionShow
            putExtra("todoId", todoId)
        }
        return PendingIntent.getBroadcast(
            context,
            todoId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentMutabilityFlag(),
        )
    }

    private fun buildAlarmClockShowIntent(context: Context, todoId: Int): PendingIntent {
        val intent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("todoId", todoId)
                putExtra("todoAction", "open")
            }
            ?: Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("todoId", todoId)
                putExtra("todoAction", "open")
            }
        return PendingIntent.getActivity(
            context,
            todoId * 100 + 11,
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
