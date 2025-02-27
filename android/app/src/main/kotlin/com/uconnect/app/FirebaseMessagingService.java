package com.uconnect.app;

import android.app.ActivityManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.media.Ringtone;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;

import com.uconnect.app.MainActivity;
import com.google.firebase.messaging.RemoteMessage;
import com.track.gpsmtrack.R;

import java.util.List;
import java.util.Locale;
import java.util.Random;
import java.util.concurrent.ExecutionException;

public final class FirebaseMessagingService extends com.google.firebase.messaging.FirebaseMessagingService {
    private static final String TAG = "FirebaseMessagingService";
    private static final String CHANNEL_ID = "GPS_Wox_Channel";

    @Override
    public void onNewToken(@NonNull String token) {
        Log.e("NEW_TOKEN", token);
        // Send the new token to the server if required
    }

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);

        if (remoteMessage.getNotification() != null) {
            Log.i("@@@@", "ONMSG REC 1");
            String title = remoteMessage.getNotification().getTitle();
            String message = remoteMessage.getNotification().getBody();
            Log.i("@@@@", "ONMSG REC 2");
            sendNotification(title, message);
        }
    }

    @Override
    public void handleIntent(@NonNull Intent intent) {
        Log.i("@@@@", "HANDLE INTENT 1");
        if (intent.getExtras() != null) {
            String title = "U-Connect";
            String body = "";

            Log.i("@@@@", "HANDLE INTENT 2");
            for (String key : intent.getExtras().keySet()) {
                if (key.equals("gcm.notification.body")) {
                    Log.i("@@@@", "HANDLE INTENT 3");
                    body = intent.getExtras().getString(key);
                }
                if (key.equals("gcm.notification.title")) {
                    Log.i("@@@@", "HANDLE INTENT 4");
                    title = intent.getExtras().getString(key);
                }
            }

            Log.i("@@@@", "HANDLE INTENT 5");
            sendNotification(title, body);
        }
    }

    private void sendNotification(String title, String message) {

        Log.i("@@@@", "NOTY ID 1");

        int notificationId = new Random().nextInt(1000);

        Uri notifySound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
        if (message.toLowerCase(Locale.ROOT).contains("Desligada")) {
            notifySound = Uri.parse("android.resource://" + getPackageName() + "/" + R.raw.offline);
        } else if (message.toLowerCase(Locale.ROOT).contains("IGNIÇÃO LIGADA")) {
            notifySound = Uri.parse("android.resource://" + getPackageName() + "/" + R.raw.ignition_on);
        } else if (message.toLowerCase(Locale.ROOT).contains("IGNIÇÃO DESLIGADA")) {
            notifySound = Uri.parse("android.resource://" + getPackageName() + "/" + R.raw.ignition_off);
        } else if (message.toLowerCase(Locale.ROOT).contains("cerca em")) {
            notifySound = Uri.parse("android.resource://" + getPackageName() + "/" + R.raw.fence_in);
        } else if (message.toLowerCase(Locale.ROOT).contains("cerca para fora")) {
            notifySound = Uri.parse("android.resource://" + getPackageName() + "/" + R.raw.fence_out);
        } else if (message.toLowerCase(Locale.ROOT).contains("corte de energia")) {
            notifySound = Uri.parse("android.resource://" + getPackageName() + "/" + R.raw.power_cut);
        }else {
            notifySound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
        }

        Ringtone r = RingtoneManager.getRingtone(getApplicationContext(), notifySound);
        if (r != null) r.play();

        Log.i("@@@@", "INTENT 1");

        Intent intent = new Intent(this, MainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        try {
            boolean foreground = new ForegroundCheckTask().execute(this).get();
            NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationChannel channel = new NotificationChannel(
                        CHANNEL_ID, "U-Connect Notifications",
                        NotificationManager.IMPORTANCE_HIGH);
                channel.enableVibration(true);
                channel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
                if (notificationManager != null) {
                    notificationManager.createNotificationChannel(channel);
                }
            }

            Log.i("@@@@", "BUILDER 1");

            NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                    .setSmallIcon(R.mipmap.ic_launcher_round)
                    .setContentTitle(title)
                    .setContentText(message)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setSound(notifySound)
                    .setAutoCancel(true)
                    .setContentIntent(pendingIntent);

            if (notificationManager != null) {
                Log.i("@@@@", "NOTY 1");
                notificationManager.notify(notificationId, builder.build());
            }

        } catch (ExecutionException | InterruptedException e) {
            Log.i("@@@@", "EXCEPTION 1");
            e.printStackTrace();
        }
    }

    static class ForegroundCheckTask extends AsyncTask<Context, Void, Boolean> {
        @Override
        protected Boolean doInBackground(Context... params) {
            return isAppOnForeground(params[0]);
        }

        private boolean isAppOnForeground(Context context) {
            ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
            List<ActivityManager.RunningAppProcessInfo> appProcesses = activityManager.getRunningAppProcesses();
            if (appProcesses == null) return false;

            final String packageName = context.getPackageName();
            for (ActivityManager.RunningAppProcessInfo appProcess : appProcesses) {
                if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                        appProcess.processName.equals(packageName)) {
                    return true;
                }
            }
            return false;
        }
    }
}