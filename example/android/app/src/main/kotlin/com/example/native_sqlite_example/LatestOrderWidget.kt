package com.example.native_sqlite_example

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.native_sqlite_example.generated.DatabaseManager
import com.example.native_sqlite_example.generated.Order
import com.example.native_sqlite_example.generated.OrderHelper
import com.example.native_sqlite_example.generated.OrderSchema
import java.util.Locale
import java.util.concurrent.Executors

/** Home-screen widget that reads the latest order through generated helpers. */
class LatestOrderWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val pendingResult = goAsync()
        val executor = Executors.newSingleThreadExecutor()
        executor.execute {
            try {
                DatabaseManager.init(context.applicationContext)
                val latest = OrderHelper(DatabaseManager.currentDatabase).findWhere(
                    orderBy = "${OrderSchema.CREATED_AT} DESC",
                    limit = 1,
                ).firstOrNull()
                appWidgetIds.forEach { id ->
                    appWidgetManager.updateAppWidget(
                        id,
                        views(context, latest),
                    )
                }
            } catch (error: Exception) {
                appWidgetIds.forEach { id ->
                    appWidgetManager.updateAppWidget(
                        id,
                        errorViews(context, error),
                    )
                }
            } finally {
                DatabaseManager.close()
                executor.shutdown()
                pendingResult.finish()
            }
        }
    }

    private fun views(context: Context, order: Order?): RemoteViews =
        RemoteViews(context.packageName, R.layout.latest_order_widget).apply {
            val openApp = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            setOnClickPendingIntent(R.id.widget_root, openApp)
            if (order == null) {
                setTextViewText(R.id.widget_order_title, "No orders yet")
                setTextViewText(R.id.widget_order_detail, "Open the example to create one")
            } else {
                setTextViewText(R.id.widget_order_title, "Order #${order.id}")
                setTextViewText(
                    R.id.widget_order_detail,
                    "${order.status.name} • " +
                        String.format(Locale.US, "%.2f", order.totalPrice),
                )
            }
        }

    private fun errorViews(context: Context, error: Exception): RemoteViews =
        RemoteViews(context.packageName, R.layout.latest_order_widget).apply {
            setTextViewText(R.id.widget_order_title, "Order widget unavailable")
            setTextViewText(
                R.id.widget_order_detail,
                error.message ?: error.javaClass.simpleName,
            )
        }
}
