package com.aashigupta_countdown

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar
import java.util.TimeZone
import java.util.concurrent.TimeUnit

class DeadlineWidgetProvider : AppWidgetProvider() {

    companion object {

        private const val ACTION_MIDNIGHT_REFRESH =
            "com.aashigupta_countdown.DEADLINE_MIDNIGHT_REFRESH"

        private const val ACTION_DEADLINE_REACHED =
            "com.aashigupta_countdown.DEADLINE_REACHED"

        private const val REQUEST_CODE_MIDNIGHT = 2001
        private const val REQUEST_CODE_DEADLINE = 2002

        private const val INDIA_TIME_ZONE = "Asia/Kolkata"

        fun updateAll(context: Context) {

            val appWidgetManager =
                AppWidgetManager.getInstance(context)

            val componentName =
                ComponentName(
                    context,
                    DeadlineWidgetProvider::class.java
                )

            val widgetIds =
                appWidgetManager.getAppWidgetIds(
                    componentName
                )

            for (widgetId in widgetIds) {

                updateWidget(
                    context,
                    appWidgetManager,
                    widgetId
                )
            }
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {

            val views =
    RemoteViews(
        context.packageName,
        R.layout.deadline_widget
    )

            /*
            * Reload button opens the app.
            */
            val launchIntent =
                context.packageManager
                    .getLaunchIntentForPackage(
                        context.packageName
                    )?.apply {

                        flags =
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }

            if (launchIntent != null) {

                val reloadPendingIntent =
                    PendingIntent.getActivity(
                        context,
                        appWidgetId,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or
                            PendingIntent.FLAG_IMMUTABLE
                    )

                views.setOnClickPendingIntent(
                    R.id.deadline_widget_reload_button,
                    reloadPendingIntent
                )
            }

            val data =
                HomeWidgetPlugin.getData(context)

            val title =
                data.getString(
                    "deadline_widget_title",
                    "Deadline"
                )

            val emoji =
                data.getString(
                    "deadline_widget_emoji",
                    "⏳"
                )

            val targetMillis =
                try {
                    data.getLong(
                        "deadline_widget_target_millis",
                        0L
                    )
                } catch (e: ClassCastException) {
                    data.getInt(
                        "deadline_widget_target_millis",
                        0
                    ).toLong()
                }

            val displayMode =
                data.getString(
                    "deadline_widget_display_mode",
                    "days"
                )

            views.setTextViewText(
                R.id.deadline_widget_title,
                "$emoji $title"
            )

            /*
             * No deadline selected.
             */
            if (targetMillis <= 0L) {

                cancelDeadlineAlarm(context)

                views.setViewVisibility(
                    R.id.deadline_widget_days,
                    View.GONE
                )

                views.setTextViewText(
                    R.id.deadline_widget_countdown,
                    "Set a deadline"
                )

                appWidgetManager.updateAppWidget(
                    appWidgetId,
                    views
                )

                return
            }

            val nowMillis =
                System.currentTimeMillis()

            val remainingMillis =
                targetMillis - nowMillis

            /*
             * Deadline already reached.
             */
            if (remainingMillis <= 0L) {

                cancelDeadlineAlarm(context)

                views.setViewVisibility(
                    R.id.deadline_widget_days,
                    View.GONE
                )

                views.setTextViewText(
                    R.id.deadline_widget_countdown,
                    "Deadline reached!"
                )

                appWidgetManager.updateAppWidget(
                    appWidgetId,
                    views
                )

                return
            }

            /*
             * Schedule an Android alarm for the EXACT
             * deadline so the Chronometer can never
             * remain negative after the deadline.
             */
            scheduleDeadlineAlarm(
                context,
                targetMillis
            )

            /*
             * Convert wall-clock remaining time into
             * Android elapsedRealtime time.
             */
            val chronometerBase =
                SystemClock.elapsedRealtime() +
                    remainingMillis

            /*
             * HOURS MODE
             */
            if (displayMode == "hours") {

                views.setViewVisibility(
                    R.id.deadline_widget_days,
                    View.GONE
                )

                views.setChronometerCountDown(
                    R.id.deadline_widget_countdown,
                    true
                )

                views.setChronometer(
                    R.id.deadline_widget_countdown,
                    chronometerBase,
                    "%s",
                    true
                )

            } else {

                /*
                 * DAYS MODE
                 *
                 * Example:
                 * 29d 23:54:51
                 */

                views.setViewVisibility(
                    R.id.deadline_widget_days,
                    View.VISIBLE
                )

                val totalSeconds =
                    TimeUnit.MILLISECONDS.toSeconds(
                        remainingMillis
                    )

                val days =
                    totalSeconds / 86400L

                val remainingAfterDays =
                    remainingMillis -
                        TimeUnit.DAYS.toMillis(days)

                views.setTextViewText(
                    R.id.deadline_widget_days,
                    "${days}d"
                )

                val timeBase =
                    SystemClock.elapsedRealtime() +
                        remainingAfterDays

                views.setChronometerCountDown(
                    R.id.deadline_widget_countdown,
                    true
                )

                views.setChronometer(
                    R.id.deadline_widget_countdown,
                    timeBase,
                    "%s",
                    true
                )
            }

            appWidgetManager.updateAppWidget(
                appWidgetId,
                views
            )
        }

        /*
         * Schedule the exact selected deadline.
         *
         * Only ONE Deadline Goal exists in the app,
         * so one deadline alarm is sufficient for all
         * Deadline widget instances.
         */
        fun scheduleDeadlineAlarm(
            context: Context,
            targetMillis: Long
        ) {

            val intent =
                Intent(
                    context,
                    DeadlineWidgetProvider::class.java
                ).apply {
                    action =
                        ACTION_DEADLINE_REACHED
                }

            val pendingIntent =
                PendingIntent.getBroadcast(
                    context,
                    REQUEST_CODE_DEADLINE,
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
                    targetMillis,
                    pendingIntent
                )

            } catch (e: SecurityException) {

                /*
                 * Fallback when exact alarm permission
                 * is not available.
                 */
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    targetMillis,
                    pendingIntent
                )
            }
        }

        /*
         * Cancel the previous deadline alarm.
         */
        fun cancelDeadlineAlarm(
            context: Context
        ) {

            val intent =
                Intent(
                    context,
                    DeadlineWidgetProvider::class.java
                ).apply {
                    action =
                        ACTION_DEADLINE_REACHED
                }

            val pendingIntent =
                PendingIntent.getBroadcast(
                    context,
                    REQUEST_CODE_DEADLINE,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or
                        PendingIntent.FLAG_IMMUTABLE
                )

            val alarmManager =
                context.getSystemService(
                    Context.ALARM_SERVICE
                ) as AlarmManager

            alarmManager.cancel(
                pendingIntent
            )
        }

        /*
         * Schedule the next midnight refresh in
         * Asia/Kolkata.
         *
         * This refreshes the DAYS portion.
         */
        fun scheduleNextMidnight(
            context: Context
        ) {

            val calendar =
                Calendar.getInstance(
                    TimeZone.getTimeZone(
                        INDIA_TIME_ZONE
                    )
                )

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

            val intent =
                Intent(
                    context,
                    DeadlineWidgetProvider::class.java
                ).apply {
                    action =
                        ACTION_MIDNIGHT_REFRESH
                }

            val pendingIntent =
                PendingIntent.getBroadcast(
                    context,
                    REQUEST_CODE_MIDNIGHT,
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
                    calendar.timeInMillis,
                    pendingIntent
                )

            } catch (e: SecurityException) {

                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    calendar.timeInMillis,
                    pendingIntent
                )
            }
        }

        fun cancelMidnightAlarm(
            context: Context
        ) {

            val intent =
                Intent(
                    context,
                    DeadlineWidgetProvider::class.java
                ).apply {
                    action =
                        ACTION_MIDNIGHT_REFRESH
                }

            val pendingIntent =
                PendingIntent.getBroadcast(
                    context,
                    REQUEST_CODE_MIDNIGHT,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or
                        PendingIntent.FLAG_IMMUTABLE
                )

            val alarmManager =
                context.getSystemService(
                    Context.ALARM_SERVICE
                ) as AlarmManager

            alarmManager.cancel(
                pendingIntent
            )
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

        scheduleNextMidnight(context)
    }

    override fun onEnabled(
        context: Context
    ) {

        super.onEnabled(context)

        scheduleNextMidnight(context)
    }

    override fun onDisabled(
        context: Context
    ) {

        super.onDisabled(context)

        cancelMidnightAlarm(context)
        cancelDeadlineAlarm(context)
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

            ACTION_MIDNIGHT_REFRESH -> {

                /*
                 * Recalculate the current deadline
                 * and refresh every Deadline widget.
                 */
                updateAll(context)

                scheduleNextMidnight(context)
            }

            ACTION_DEADLINE_REACHED -> {

                /*
                 * The actual deadline has arrived.
                 *
                 * updateWidget() will now detect
                 * remainingMillis <= 0 and show
                 * "Deadline reached!" instead of
                 * allowing the Chronometer to go negative.
                 */
                updateAll(context)

                cancelDeadlineAlarm(context)
            }

            Intent.ACTION_BOOT_COMPLETED -> {

                updateAll(context)

                scheduleNextMidnight(context)
            }
        }
    }
}