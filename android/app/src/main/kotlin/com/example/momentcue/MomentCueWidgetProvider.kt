package com.example.momentcue

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.*

class MomentCueWidgetProvider : AppWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update all widget instances
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        if (intent.action == "com.example.momentcue.QUICK_CHECK") {
            // Handle quick check action
            val checkId = intent.getStringExtra("check_id")
            val checkTitle = intent.getStringExtra("check_title")
            
            // Show confirmation
            Toast.makeText(context, "Quick check: $checkTitle", Toast.LENGTH_SHORT).show()
            
            // Here you would update the check status in your database
            // For now, we'll just show a toast
        }
    }
    
    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.momentcue_widget)
        
        // Set up the main app launch intent
        val mainIntent = Intent(context, MainActivity::class.java)
        val mainPendingIntent = PendingIntent.getActivity(
            context, 0, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_main_button, mainPendingIntent)
        
        // Set up quick check buttons (you can add more as needed)
        setupQuickCheckButton(context, views, "check_1", "Water", R.id.widget_quick_check_1)
        setupQuickCheckButton(context, views, "check_2", "Exercise", R.id.widget_quick_check_2)
        setupQuickCheckButton(context, views, "check_3", "Meditation", R.id.widget_quick_check_3)
        
        // Update time
        val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        val dateFormat = SimpleDateFormat("MMM dd", Locale.getDefault())
        val now = Date()
        
        views.setTextViewText(R.id.widget_time, timeFormat.format(now))
        views.setTextViewText(R.id.widget_date, dateFormat.format(now))
        
        // Update widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
    
    private fun setupQuickCheckButton(
        context: Context,
        views: RemoteViews,
        checkId: String,
        checkTitle: String,
        buttonId: Int
    ) {
        val intent = Intent(context, MomentCueWidgetProvider::class.java).apply {
            action = "com.example.momentcue.QUICK_CHECK"
            putExtra("check_id", checkId)
            putExtra("check_title", checkTitle)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context, checkId.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        views.setOnClickPendingIntent(buttonId, pendingIntent)
        views.setTextViewText(buttonId, checkTitle)
    }
}
