package com.example.native_sqlite_example

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.example.native_sqlite_example.generated.DatabaseManager
import com.example.native_sqlite_example.generated.SyncEvent
import com.example.native_sqlite_example.generated.SyncEventHelper
import java.time.Instant
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class NativeSyncWorker(
    context: Context,
    params: WorkerParameters,
) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            val id = NativeSyncTask.run(applicationContext)
            Result.success(workDataOf("row_id" to id))
        } catch (error: Exception) {
            Result.failure(workDataOf("error" to (error.message ?: error.javaClass.simpleName)))
        }
    }
}

object NativeSyncTask {
    const val periodicWorkName = "native-sqlite-background-sync"
    private const val immediateWorkName = "native-sqlite-background-sync-now"

    fun run(context: Context): Long {
        DatabaseManager.init(context.applicationContext)
        val events = SyncEventHelper(DatabaseManager.currentDatabase)
        return events.insert(
            SyncEvent(
                source = "native-worker",
                message = "Android WorkManager sync",
                createdAt = Instant.now(),
            )
        )
    }

    fun schedulePeriodic(context: Context) {
        val request = PeriodicWorkRequestBuilder<NativeSyncWorker>(
            15,
            TimeUnit.MINUTES,
        ).build()
        WorkManager.getInstance(context.applicationContext).enqueueUniquePeriodicWork(
            periodicWorkName,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    fun enqueueNow(context: Context) {
        val request = OneTimeWorkRequestBuilder<NativeSyncWorker>().build()
        WorkManager.getInstance(context.applicationContext).enqueueUniqueWork(
            immediateWorkName,
            ExistingWorkPolicy.REPLACE,
            request,
        )
    }
}
