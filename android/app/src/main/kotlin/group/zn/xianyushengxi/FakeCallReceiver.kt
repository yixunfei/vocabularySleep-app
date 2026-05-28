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

class FakeCallReceiver : BroadcastReceiver() {
    companion object {
        const val actionShow = "group.zn.xianyushengxi.FAKE_CALL_SHOW"
        const val actionDismiss = "group.zn.xianyushengxi.FAKE_CALL_DISMISS"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val callId = intent.getIntExtra("callId", 0)
        if (callId <= 0) {
            return
        }

        if (intent.action == actionDismiss) {
            FakeCallScheduler.cancel(context, callId)
            return
        }

        FakeCallScheduler.ensureNotificationChannel(context)
        val stored = FakeCallScheduler.consume(context, callId)
        val spec = stored ?: FakeCallSpec(
            callId = callId,
            triggerAtMillis = System.currentTimeMillis(),
            callerName = intent.getStringExtra("callerName")?.trim(),
            callerNumber = intent.getStringExtra("callerNumber")?.trim(),
            callerLocation = intent.getStringExtra("callerLocation")?.trim(),
            callerTag = intent.getStringExtra("callerTag")?.trim(),
            ringtoneEnabled = intent.getBooleanExtra("ringtoneEnabled", true),
            vibrationEnabled = intent.getBooleanExtra("vibrationEnabled", true),
            incomingBackgroundPath = intent.getStringExtra("incomingBackgroundPath")?.trim(),
            incomingBackgroundStyle = intent.getStringExtra("incomingBackgroundStyle")?.trim(),
            inCallBackgroundPath = intent.getStringExtra("inCallBackgroundPath")?.trim(),
            inCallBackgroundStyle = intent.getStringExtra("inCallBackgroundStyle")?.trim(),
        )
        val activityIntent = FakeCallScheduler.buildActivityIntent(context, spec)
        showFullScreenNotification(context, spec, activityIntent)
        try {
            context.startActivity(activityIntent)
        } catch (_: Throwable) {
            // Full-screen notification remains the delivery path when direct launch is blocked.
        }
    }

    private fun showFullScreenNotification(
        context: Context,
        spec: FakeCallSpec,
        activityIntent: Intent,
    ) {
        val contentTitle = spec.callerName?.takeIf { it.isNotBlank() }
            ?: localizedText(context, "模拟来电", "Fake incoming call")
        val contentText = spec.callerNumber?.takeIf { it.isNotBlank() }
            ?: localizedText(context, "来电中", "Incoming call")
        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            spec.callId * 100 + 43,
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentMutabilityFlag(),
        )
        val dismissPendingIntent = PendingIntent.getBroadcast(
            context,
            spec.callId * 100 + 44,
            Intent(context, FakeCallReceiver::class.java).apply {
                action = actionDismiss
                putExtra("callId", spec.callId)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentMutabilityFlag(),
        )
        val notification = NotificationCompat.Builder(context, FakeCallScheduler.channelId)
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
            .addAction(0, localizedText(context, "拒绝", "Decline"), dismissPendingIntent)
            .build()
        if (spec.ringtoneEnabled) {
            notification.flags = notification.flags or Notification.FLAG_INSISTENT
        }

        if (
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.POST_NOTIFICATIONS,
                ) == PackageManager.PERMISSION_GRANTED
        ) {
            NotificationManagerCompat.from(context).notify(spec.callId, notification)
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
