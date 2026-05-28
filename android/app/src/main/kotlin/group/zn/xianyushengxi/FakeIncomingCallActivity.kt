package group.zn.xianyushengxi

import android.animation.Animator
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.app.Activity
import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.RenderEffect
import android.graphics.Shader
import android.graphics.drawable.GradientDrawable
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationManagerCompat

class FakeIncomingCallActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private val inCallAnimators = mutableListOf<Animator>()
    private var ringtone: Ringtone? = null
    private var vibrator: Vibrator? = null
    private var accepted = false
    private var callStartedAt = 0L
    private var durationText: TextView? = null
    private val durationTick = object : Runnable {
        override fun run() {
            durationText?.text = formatDuration(SystemClock.elapsedRealtime() - callStartedAt)
            handler.postDelayed(this, 1000L)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        configureWindow()
        showIncomingScreen()
        startIncomingEffects()
    }

    override fun onDestroy() {
        handler.removeCallbacks(durationTick)
        stopInCallAnimation()
        stopIncomingEffects()
        dismissNotification()
        super.onDestroy()
    }

    private fun configureWindow() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            )
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes = window.attributes.apply {
                layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }
        window.decorView.systemUiVisibility =
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
    }

    private fun showIncomingScreen() {
        accepted = false
        durationText = null
        stopInCallAnimation()
        setContentView(
            buildRoot(
                imagePath = intent.getStringExtra("incomingBackgroundPath"),
                style = intent.getStringExtra("incomingBackgroundStyle"),
                accepted = false,
            ) {
                addHeader(localizedText(zh = "来电中", en = "Incoming call"))
                addCallerBlock()
                addView(space(weight = 1f))
                addView(LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER
                    addView(
                        buildActionButton(
                            localizedText(zh = "拒绝", en = "Decline"),
                            0xFFC24141.toInt(),
                        ) {
                            hangUp(returnHome = true)
                        },
                    )
                    addView(buildSpacer())
                    addView(
                        buildActionButton(
                            localizedText(zh = "接听", en = "Accept"),
                            0xFF2E9C67.toInt(),
                        ) {
                            acceptCall()
                        },
                    )
                })
            },
        )
    }

    private fun acceptCall() {
        if (accepted) {
            return
        }
        accepted = true
        stopIncomingEffects()
        callStartedAt = SystemClock.elapsedRealtime()
        setContentView(
            buildRoot(
                imagePath = intent.getStringExtra("inCallBackgroundPath"),
                style = intent.getStringExtra("inCallBackgroundStyle"),
                accepted = true,
            ) {
                addHeader(localizedText(zh = "通话中", en = "In call"))
                durationText = TextView(context).apply {
                    text = "00:00"
                    gravity = Gravity.CENTER
                    textSize = 38f
                    setTextColor(Color.WHITE)
                    setPadding(0, dp(16), 0, dp(26))
                }
                addView(durationText)
                addView(buildInCallStage())
                addView(
                    buildActionButton(
                        localizedText(zh = "挂断", en = "Hang up"),
                        0xFFC24141.toInt(),
                    ) {
                        hangUp(returnHome = true)
                    },
                )
            },
        )
        handler.removeCallbacks(durationTick)
        handler.post(durationTick)
    }

    private fun buildRoot(
        imagePath: String?,
        style: String?,
        accepted: Boolean,
        content: LinearLayout.() -> Unit,
    ): View {
        val root = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            )
            background = buildGradientBackground(accepted)
        }
        buildBackgroundImage(imagePath, style)?.let { imageView ->
            root.addView(imageView)
        }
        root.addView(View(this).apply {
            setBackgroundColor(Color.argb(backgroundOverlayAlpha(style), 0, 0, 0))
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            )
        })
        root.addView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(24), dp(48), dp(24), dp(32))
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            )
            content()
        })
        return root
    }

    private fun LinearLayout.addHeader(label: String) {
        addView(TextView(context).apply {
            text = label
            gravity = Gravity.CENTER
            textSize = 18f
            setTextColor(0xFFCBD5E1.toInt())
        })
        addView(space(height = dp(26)))
    }

    private fun LinearLayout.addCallerBlock() {
        val details = callerDetails()
        addView(TextView(context).apply {
            text = details.name.firstOrNull()?.uppercaseChar()?.toString() ?: "?"
            gravity = Gravity.CENTER
            textSize = 42f
            setTextColor(Color.WHITE)
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(0xAA20384E.toInt())
            }
            layoutParams = LinearLayout.LayoutParams(dp(112), dp(112))
        })
        addView(TextView(context).apply {
            text = details.name
            gravity = Gravity.CENTER
            textSize = 34f
            setTextColor(Color.WHITE)
            setPadding(0, dp(24), 0, dp(8))
        })
        addView(TextView(context).apply {
            text = details.number
            gravity = Gravity.CENTER
            textSize = 20f
            setTextColor(0xFFD8E4F0.toInt())
        })
        if (details.meta.isNotBlank()) {
            addView(TextView(context).apply {
                text = details.meta
                gravity = Gravity.CENTER
                textSize = 15f
                setTextColor(0xFFCBD5E1.toInt())
                setPadding(0, dp(12), 0, 0)
            })
        }
    }

    private fun buildInCallStage(): View {
        val details = callerDetails()
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f,
            )

            addView(FrameLayout(context).apply {
                layoutParams = LinearLayout.LayoutParams(dp(320), dp(320))
                addView(buildPulseRing(delayMs = 0L))
                addView(buildPulseRing(delayMs = 560L))
                addView(buildPulseRing(delayMs = 1120L))
                addView(TextView(context).apply {
                    text = details.name.firstOrNull()?.uppercaseChar()?.toString() ?: "?"
                    gravity = Gravity.CENTER
                    textSize = 42f
                    setTextColor(Color.WHITE)
                    background = GradientDrawable().apply {
                        shape = GradientDrawable.OVAL
                        setColor(0xCC20384E.toInt())
                    }
                    layoutParams = FrameLayout.LayoutParams(dp(124), dp(124), Gravity.CENTER)
                })
            })

            addView(TextView(context).apply {
                text = details.name
                gravity = Gravity.CENTER
                textSize = 30f
                setTextColor(Color.WHITE)
                setPadding(0, dp(18), 0, dp(8))
            })
            addView(TextView(context).apply {
                text = details.number
                gravity = Gravity.CENTER
                textSize = 18f
                setTextColor(0xFFD8E4F0.toInt())
            })
            if (details.meta.isNotBlank()) {
                addView(TextView(context).apply {
                    text = details.meta
                    gravity = Gravity.CENTER
                    textSize = 14f
                    setTextColor(0xFFCBD5E1.toInt())
                    setPadding(0, dp(10), 0, 0)
                })
            }
        }
    }

    private fun buildPulseRing(delayMs: Long): View {
        return View(this).apply {
            alpha = 0.34f
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.TRANSPARENT)
                setStroke(dp(2), 0x6634D399)
            }
            layoutParams = FrameLayout.LayoutParams(dp(118), dp(118), Gravity.CENTER)
            val scaleX = ObjectAnimator.ofFloat(this, View.SCALE_X, 0.72f, 2.55f).apply {
                repeatCount = ValueAnimator.INFINITE
                repeatMode = ValueAnimator.RESTART
            }
            val scaleY = ObjectAnimator.ofFloat(this, View.SCALE_Y, 0.72f, 2.55f).apply {
                repeatCount = ValueAnimator.INFINITE
                repeatMode = ValueAnimator.RESTART
            }
            val fade = ObjectAnimator.ofFloat(this, View.ALPHA, 0.34f, 0f).apply {
                repeatCount = ValueAnimator.INFINITE
                repeatMode = ValueAnimator.RESTART
            }
            AnimatorSet().apply {
                duration = 1800L
                startDelay = delayMs
                playTogether(scaleX, scaleY, fade)
                start()
                inCallAnimators.add(this)
            }
        }
    }

    private fun stopInCallAnimation() {
        inCallAnimators.forEach { animator ->
            try {
                animator.cancel()
            } catch (_: Throwable) {
                // Best-effort animation cleanup only.
            }
        }
        inCallAnimators.clear()
    }

    private fun callerDetails(): CallerDetails {
        val title = intent.getStringExtra("title")?.trim().orEmpty()
        val description = intent.getStringExtra("description")?.trim().orEmpty()
        val callerName = intent.getStringExtra("callerName")?.trim().orEmpty()
        val callerNumber = intent.getStringExtra("callerNumber")?.trim().orEmpty()
        val callerLocation = intent.getStringExtra("callerLocation")?.trim().orEmpty()
        val callerTag = intent.getStringExtra("callerTag")?.trim().orEmpty()
        val name = callerName.ifEmpty {
            title.ifEmpty { localizedText(zh = "模拟来电", en = "Fake incoming call") }
        }
        val number = callerNumber.ifEmpty {
            description.ifEmpty { localizedText(zh = "未知号码", en = "Unknown number") }
        }
        return CallerDetails(
            name = name,
            number = number,
            meta = listOf(callerLocation, callerTag)
                .filter { it.isNotBlank() }
                .joinToString("  ·  "),
        )
    }

    private fun buildActionButton(
        label: String,
        backgroundColor: Int,
        onClick: () -> Unit,
    ): Button {
        return Button(this).apply {
            text = label
            textSize = 18f
            minWidth = dp(120)
            minimumHeight = dp(56)
            setTextColor(Color.WHITE)
            background = GradientDrawable().apply {
                cornerRadius = dp(28).toFloat()
                setColor(backgroundColor)
            }
            setOnClickListener { onClick() }
        }
    }

    private fun buildGradientBackground(accepted: Boolean): GradientDrawable {
        val gradientColors = if (accepted) {
            intArrayOf(0xFF102A24.toInt(), 0xFF071018.toInt())
        } else {
            intArrayOf(0xFF132536.toInt(), 0xFF071018.toInt())
        }
        return GradientDrawable(
            GradientDrawable.Orientation.TL_BR,
            gradientColors,
        )
    }

    private fun buildBackgroundImage(imagePath: String?, style: String?): ImageView? {
        val path = imagePath?.trim().orEmpty()
        if (path.isBlank()) {
            return null
        }
        return try {
            val bitmap = BitmapFactory.decodeFile(path) ?: return null
            ImageView(this).apply {
                setImageBitmap(bitmap)
                scaleType = ImageView.ScaleType.CENTER_CROP
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                )
                if (style == "blur" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setRenderEffect(
                        RenderEffect.createBlurEffect(
                            dp(12).toFloat(),
                            dp(12).toFloat(),
                            Shader.TileMode.CLAMP,
                        ),
                    )
                }
            }
        } catch (_: Throwable) {
            null
        }
    }

    private fun backgroundOverlayAlpha(style: String?): Int {
        return when (style) {
            "dim" -> 188
            "blur" -> 172
            else -> 132
        }
    }

    private fun startIncomingEffects() {
        if (intent.getBooleanExtra("ringtoneEnabled", true)) {
            if (ringtone == null) {
                val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                ringtone = RingtoneManager.getRingtone(applicationContext, ringtoneUri)?.apply {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        isLooping = true
                    }
                    audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                }
            }
            try {
                ringtone?.play()
            } catch (_: Throwable) {
                // Best-effort only.
            }
        }

        if (!intent.getBooleanExtra("vibrationEnabled", true)) {
            return
        }
        if (vibrator == null) {
            vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)
                    ?.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
            }
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(
                    VibrationEffect.createWaveform(longArrayOf(0, 300, 220, 520), 0),
                )
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(longArrayOf(0, 300, 220, 520), 0)
            }
        } catch (_: Throwable) {
            // Best-effort only.
        }
    }

    private fun stopIncomingEffects() {
        try {
            ringtone?.stop()
        } catch (_: Throwable) {
            // Best-effort only.
        }
        try {
            vibrator?.cancel()
        } catch (_: Throwable) {
            // Best-effort only.
        }
    }

    private fun hangUp(returnHome: Boolean) {
        handler.removeCallbacks(durationTick)
        stopInCallAnimation()
        stopIncomingEffects()
        dismissNotification()
        if (returnHome) {
            try {
                moveTaskToBack(true)
            } catch (_: Throwable) {
                // Some launch modes disallow moving the task; finishing is enough.
            }
        }
        finish()
    }

    private fun dismissNotification() {
        val callId = intent.getIntExtra("callId", 0).takeIf { it > 0 }
            ?: intent.getIntExtra("todoId", 0)
        if (callId <= 0) {
            return
        }
        try {
            NotificationManagerCompat.from(this).cancel(callId)
        } catch (_: Throwable) {
            // Best-effort cleanup only.
        }
    }

    private fun formatDuration(millis: Long): String {
        val totalSeconds = (millis / 1000L).coerceAtLeast(0L)
        val hours = totalSeconds / 3600L
        val minutes = (totalSeconds / 60L) % 60L
        val seconds = totalSeconds % 60L
        return if (hours > 0L) {
            "%02d:%02d:%02d".format(hours, minutes, seconds)
        } else {
            "%02d:%02d".format(minutes, seconds)
        }
    }

    private fun buildSpacer(): View {
        return View(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(18), 1)
        }
    }

    private fun space(height: Int = 0, weight: Float = 0f): View {
        return View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                height,
                weight,
            )
        }
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }

    private fun localizedText(zh: String, en: String): String {
        val language = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            resources.configuration.locales[0]?.language.orEmpty()
        } else {
            @Suppress("DEPRECATION")
            resources.configuration.locale.language.orEmpty()
        }
        return if (language.startsWith("zh")) zh else en
    }

    private data class CallerDetails(
        val name: String,
        val number: String,
        val meta: String,
    )
}
