package group.zn.xianyushengxi

import android.Manifest
import android.app.Notification
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

class TodoReminderReceiver : BroadcastReceiver() {
    companion object {
        const val actionShow = "group.zn.xianyushengxi.TODO_REMINDER"
        const val actionPerform = "group.zn.xianyushengxi.TODO_REMINDER_ACTION"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == actionPerform) {
            val todoId = intent.getIntExtra("todoId", 0)
            if (todoId <= 0) {
                return
            }
            val actionType = intent.getStringExtra("todoAction")?.trim().orEmpty()
            val shouldCancelNotification =
                !actionType.equals("detail", ignoreCase = true)
            if (shouldCancelNotification) {
                NotificationManagerCompat.from(context).cancel(todoId)
            }
            if (actionType.equals("cancel", ignoreCase = true)) {
                return
            }
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra("todoId", todoId)
                    putExtra("todoAction", actionType)
                    putExtra("todoSnoozeMinutes", intent.getIntExtra("todoSnoozeMinutes", 10))
                }
                ?: Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra("todoId", todoId)
                    putExtra("todoAction", actionType)
                    putExtra("todoSnoozeMinutes", intent.getIntExtra("todoSnoozeMinutes", 10))
                }
            try {
                context.startActivity(launchIntent)
            } catch (_: Throwable) {
                // Best-effort only.
            }
            return
        }

        TodoReminderScheduler.ensureNotificationChannels(context)

        val todoId = intent.getIntExtra("todoId", 0)
        if (todoId <= 0) {
            return
        }

        val title = intent.getStringExtra("title")?.trim().orEmpty()
        if (title.isEmpty()) {
            TodoReminderScheduler.consume(context, todoId)
            return
        }
        val description = intent.getStringExtra("description")?.trim().orEmpty()
        val mode = intent.getStringExtra("mode")?.trim().orEmpty()
        val presentationType = intent.getStringExtra("presentationType")?.trim().orEmpty()
        val stickyNotification = intent.getBooleanExtra("stickyNotification", false)
        val cancelOnOpen = intent.getBooleanExtra("cancelOnOpen", true)

        if (presentationType.equals("fakeCall", ignoreCase = true)) {
            val fakeCallIntent = buildFakeCallIntent(context, intent, todoId, title, description)
            showFakeCallNotification(context, intent, todoId, title, description, fakeCallIntent)
            try {
                context.startActivity(fakeCallIntent)
            } catch (_: Throwable) {
                // Full-screen notification above remains the reliable delivery path.
            }
            TodoReminderScheduler.consume(context, todoId)
            return
        }

        val contentIntent = buildActionPendingIntent(
            context,
            todoId,
            if (cancelOnOpen) "open" else "detail",
        )

        val channelId =
            if (mode.equals("alarm", ignoreCase = true)) {
                TodoReminderScheduler.alarmChannelId
            } else {
                TodoReminderScheduler.notificationChannelId
            }
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText(
                if (description.isNotEmpty()) description else "Todo reminder",
            )
            .setStyle(NotificationCompat.BigTextStyle().bigText(description.ifEmpty { title }))
            .setCategory(
                if (mode.equals("alarm", ignoreCase = true)) {
                    NotificationCompat.CATEGORY_ALARM
                } else {
                    NotificationCompat.CATEGORY_REMINDER
                },
            )
            .setPriority(
                if (mode.equals("alarm", ignoreCase = true)) {
                    NotificationCompat.PRIORITY_HIGH
                } else {
                    NotificationCompat.PRIORITY_DEFAULT
                },
            )
            .setAutoCancel(!(mode.equals("alarm", ignoreCase = true) || stickyNotification))
            .setOngoing(mode.equals("alarm", ignoreCase = true) || stickyNotification)
            .setContentIntent(contentIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(
                0,
                "Complete",
                buildActionPendingIntent(context, todoId, "complete"),
            )
            .addAction(
                0,
                "Snooze 10m",
                buildActionPendingIntent(context, todoId, "snooze", snoozeMinutes = 10),
            )
            .addAction(
                0,
                if (cancelOnOpen) "Open app" else "Open detail",
                buildActionPendingIntent(
                    context,
                    todoId,
                    if (cancelOnOpen) "open" else "detail",
                ),
            )
            .addAction(
                0,
                "Dismiss",
                buildActionPendingIntent(context, todoId, "cancel"),
            )
            .build()

        if (mode.equals("alarm", ignoreCase = true)) {
            notification.flags = notification.flags or Notification.FLAG_INSISTENT
        }

        if (
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.POST_NOTIFICATIONS,
                ) == PackageManager.PERMISSION_GRANTED
        ) {
            NotificationManagerCompat.from(context).notify(todoId, notification)
        }

        if (mode.equals("alarm", ignoreCase = true)) {
            val launchIntent = context.packageManager
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
            try {
                context.startActivity(launchIntent)
            } catch (_: Throwable) {
                // Full-screen launch is best-effort only.
            }
        }

        TodoReminderScheduler.consume(context, todoId)
    }

    private fun buildActionPendingIntent(
        context: Context,
        todoId: Int,
        actionType: String,
        snoozeMinutes: Int = 10,
    ): PendingIntent {
        val intent = Intent(context, TodoReminderReceiver::class.java).apply {
            action = actionPerform
            putExtra("todoId", todoId)
            putExtra("todoAction", actionType)
            putExtra("todoSnoozeMinutes", snoozeMinutes)
        }
        return PendingIntent.getBroadcast(
            context,
            todoId * 10 + actionType.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                pendingIntentMutabilityFlag(),
        )
    }

    private fun buildFakeCallIntent(
        context: Context,
        source: Intent,
        todoId: Int,
        title: String,
        description: String,
    ): Intent {
        return Intent(context, FakeIncomingCallActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS,
            )
            putExtra("todoId", todoId)
            putExtra("title", title)
            putExtra("description", description)
            putExtra("callerName", source.getStringExtra("callerName"))
            putExtra("callerNumber", source.getStringExtra("callerNumber"))
            putExtra("callerLocation", source.getStringExtra("callerLocation"))
            putExtra("callerTag", source.getStringExtra("callerTag"))
        }
    }

    private fun showFakeCallNotification(
        context: Context,
        source: Intent,
        todoId: Int,
        title: String,
        description: String,
        fakeCallIntent: Intent,
    ) {
        val callerName = source.getStringExtra("callerName")?.trim().orEmpty()
        val callerNumber = source.getStringExtra("callerNumber")?.trim().orEmpty()
        val contentTitle = callerName.ifEmpty { title.ifEmpty { localizedText(context, "模拟来电", "Fake incoming call") } }
        val contentText = callerNumber.ifEmpty {
            description.ifEmpty { localizedText(context, "来电中", "Incoming call") }
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            todoId * 100 + 7,
            fakeCallIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentMutabilityFlag(),
        )
        val notification = NotificationCompat.Builder(
            context,
            TodoReminderScheduler.fakeCallChannelId,
        )
            .setSmallIcon(android.R.drawable.sym_call_incoming)
            .setContentTitle(contentTitle)
            .setContentText(contentText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(contentText))
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(fullScreenPendingIntent)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .addAction(
                0,
                localizedText(context, "拒绝", "Decline"),
                buildActionPendingIntent(context, todoId, "cancel"),
            )
            .build()

        if (
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.POST_NOTIFICATIONS,
                ) == PackageManager.PERMISSION_GRANTED
        ) {
            NotificationManagerCompat.from(context).notify(todoId, notification)
        }
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
