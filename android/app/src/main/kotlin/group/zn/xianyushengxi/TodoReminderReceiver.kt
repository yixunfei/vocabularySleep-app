package group.zn.xianyushengxi

import android.Manifest
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
            NotificationManagerCompat.from(context).cancel(todoId)
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra("todoId", todoId)
                    putExtra("todoAction", intent.getStringExtra("todoAction"))
                    putExtra("todoSnoozeMinutes", intent.getIntExtra("todoSnoozeMinutes", 10))
                }
                ?: Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra("todoId", todoId)
                    putExtra("todoAction", intent.getStringExtra("todoAction"))
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
        val contentIntent = PendingIntent.getActivity(
            context,
            todoId,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                },
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
            .setAutoCancel(!mode.equals("alarm", ignoreCase = true))
            .setOngoing(mode.equals("alarm", ignoreCase = true))
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
                "Open detail",
                buildActionPendingIntent(context, todoId, "detail"),
            )
            .build()

        if (mode.equals("alarm", ignoreCase = true)) {
            notification.flags = notification.flags or android.app.Notification.FLAG_INSISTENT
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
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE
                } else {
                    0
                },
        )
    }
}
