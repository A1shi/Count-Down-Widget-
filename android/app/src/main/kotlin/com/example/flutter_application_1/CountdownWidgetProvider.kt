package com.aashigupta_countdown

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar
import java.util.TimeZone
import java.util.concurrent.TimeUnit

class CountdownWidgetProvider : AppWidgetProvider() {

    companion object {

        private const val ACTION_DAY_UPDATE =
            "com.aashigupta_countdown.ACTION_DAY_UPDATE"

        private const val ACTION_GOAL_REACHED =
            "com.aashigupta_countdown.ACTION_GOAL_REACHED"

        private const val REQUEST_CODE_DAY_UPDATE = 9001
        private const val REQUEST_CODE_GOAL_REACHED = 9002

        fun updateAll(context: Context) {

            val appWidgetManager =
                AppWidgetManager.getInstance(context)

            val componentName =
                ComponentName(
                    context,
                    CountdownWidgetProvider::class.java
                )

            val widgetIds =
                appWidgetManager.getAppWidgetIds(componentName)

            for (widgetId in widgetIds) {
                updateWidget(
                    context,
                    appWidgetManager,
                    widgetId
                )
            }

            // Schedule the next midnight refresh and the goal completion update.
            scheduleNextDayUpdate(context)
            scheduleGoalReachedUpdate(context)
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {

            val views =
                RemoteViews(
                    context.packageName,
                    R.layout.countdown_widget
                )

            val data =
                HomeWidgetPlugin.getData(context)

            val title =
                data.getString(
                    "widget_title",
                    "Life Countdown"
                )

            val emoji =
                data.getString(
                    "widget_emoji",
                    "🎯"
                )

            val targetMillis =
                try {
                    data.getLong(
                        "widget_target_millis",
                        0L
                    )
                } catch (e: ClassCastException) {
                    data.getInt(
                        "widget_target_millis",
                        0
                    ).toLong()
                }

            views.setTextViewText(
                R.id.widget_title,
                "$emoji $title"
            )

            // No primary goal.
            if (targetMillis <= 0L) {

                views.setTextViewText(
                    R.id.widget_days,
                    "0d"
                )

                views.setTextViewText(
                    R.id.widget_countdown,
                    "Set a primary goal"
                )

                views.setChronometer(
                    R.id.widget_countdown,
                    SystemClock.elapsedRealtime(),
                    null,
                    false
                )

                appWidgetManager.updateAppWidget(
                    appWidgetId,
                    views
                )

                return
            }

            val remainingMillis =
                targetMillis - System.currentTimeMillis()

            // Goal completed.
            if (remainingMillis <= 0L) {

                views.setTextViewText(
                    R.id.widget_days,
                    "0d"
                )

                views.setTextViewText(
                    R.id.widget_countdown,
                    "You achieved the target! 🎉"
                )

                // Stop the Chronometer so it can never continue into negative time.
                views.setChronometer(
                    R.id.widget_countdown,
                    SystemClock.elapsedRealtime(),
                    null,
                    false
                )

                appWidgetManager.updateAppWidget(
                    appWidgetId,
                    views
                )

                return
            }

            // Calculate complete remaining days.
            val totalSeconds =
                TimeUnit.MILLISECONDS.toSeconds(
                    remainingMillis
                )

            val days =
                totalSeconds / 86400L

            // Remaining time after full days.
            val remainingAfterDays =
                remainingMillis -
                    TimeUnit.DAYS.toMillis(days)

            views.setTextViewText(
                R.id.widget_days,
                "${days}d"
            )

            // Configure Chronometer countdown.
            val chronometerBase =
                SystemClock.elapsedRealtime() +
                    remainingAfterDays

            views.setChronometerCountDown(
                R.id.widget_countdown,
                true
            )

            views.setChronometer(
                R.id.widget_countdown,
                chronometerBase,
                "%s",
                true
            )

            appWidgetManager.updateAppWidget(
                appWidgetId,
                views
            )
        }

        /*
         * Refresh at the next 12:00 AM India time.
         */
        private fun scheduleNextDayUpdate(
            context: Context
        ) {

            val indiaTimeZone =
                TimeZone.getTimeZone("Asia/Kolkata")

            val calendar =
                Calendar.getInstance(indiaTimeZone)

            calendar.add(
                Calendar.DAY_OF_YEAR,
                1
            )

            calendar.set(
                Calendar.HOUR_OF_DAY,
                0
            )

            calendar.set(
                Calendar.MINUTE,
                0
            )

            calendar.set(
                Calendar.SECOND,
                0
            )

            calendar.set(
                Calendar.MILLISECOND,
                0
            )

            scheduleAlarm(
                context,
                calendar.timeInMillis,
                ACTION_DAY_UPDATE,
                REQUEST_CODE_DAY_UPDATE
            )
        }

        /*
         * Schedule an update at the exact moment
         * the goal reaches zero.
         */
        private fun scheduleGoalReachedUpdate(
            context: Context
        ) {

            val data =
                HomeWidgetPlugin.getData(context)

            val targetMillis =
                try {
                    data.getLong(
                        "widget_target_millis",
                        0L
                    )
                } catch (e: ClassCastException) {
                    data.getInt(
                        "widget_target_millis",
                        0
                    ).toLong()
                }

            // Don't schedule an alarm for an invalid or already completed goal.
            if (
                targetMillis <= System.currentTimeMillis()
            ) {
                return
            }

            scheduleAlarm(
                context,
                targetMillis,
                ACTION_GOAL_REACHED,
                REQUEST_CODE_GOAL_REACHED
            )
        }

        /*
         * Shared function for scheduling alarms.
         */
        private fun scheduleAlarm(
            context: Context,
            triggerTime: Long,
            action: String,
            requestCode: Int
        ) {

            val intent =
                Intent(
                    context,
                    CountdownWidgetProvider::class.java
                ).apply {
                    this.action = action
                }

            val pendingIntent =
                PendingIntent.getBroadcast(
                    context,
                    requestCode,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or
                        PendingIntent.FLAG_IMMUTABLE
                )

            val alarmManager =
                context.getSystemService(
                    Context.ALARM_SERVICE
                ) as AlarmManager

            try {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            } catch (e: SecurityException) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            }
        }

        private fun cancelAlarms(
            context: Context
        ) {

            val alarmManager =
                context.getSystemService(
                    Context.ALARM_SERVICE
                ) as AlarmManager

            val actions = listOf(
                Pair(
                    ACTION_DAY_UPDATE,
                    REQUEST_CODE_DAY_UPDATE
                ),
                Pair(
                    ACTION_GOAL_REACHED,
                    REQUEST_CODE_GOAL_REACHED
                )
            )

            for ((action, requestCode) in actions) {

                val intent =
                    Intent(
                        context,
                        CountdownWidgetProvider::class.java
                    ).apply {
                        this.action = action
                    }

                val pendingIntent =
                    PendingIntent.getBroadcast(
                        context,
                        requestCode,
                        intent,
                        PendingIntent.FLAG_UPDATE_CURRENT or
                            PendingIntent.FLAG_IMMUTABLE
                    )

                alarmManager.cancel(pendingIntent)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {

        for (appWidgetId in appWidgetIds) {
            updateWidget(
                context,
                appWidgetManager,
                appWidgetId
            )
        }

        scheduleNextDayUpdate(context)
        scheduleGoalReachedUpdate(context)
    }

    override fun onEnabled(
        context: Context
    ) {
        super.onEnabled(context)
        updateAll(context)
    }

    override fun onDisabled(
        context: Context
    ) {
        super.onDisabled(context)
        cancelAlarms(context)
    }

    override fun onReceive(
        context: Context,
        intent: Intent
    ) {

        super.onReceive(
            context,
            intent
        )

        when (intent.action) {

            ACTION_DAY_UPDATE,
            ACTION_GOAL_REACHED -> {

                updateAll(context)
            }

            Intent.ACTION_BOOT_COMPLETED -> {

                updateAll(context)
            }
        }
    }
}