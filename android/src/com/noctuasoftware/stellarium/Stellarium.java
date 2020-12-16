package com.noctuasoftware.stellarium;

import android.app.Activity;
import android.util.DisplayMetrics;
import android.location.Criteria;
import android.location.LocationListener;
import android.location.LocationManager;
import android.location.Location;
import android.util.Log;
import android.os.Bundle;
import android.view.Display;

public class Stellarium implements LocationListener
{
    private Activity m_activity;
    private LocationManager m_locationManager;
    private static String TAG = "Stellarium";

    public Stellarium(Activity activity) {
        m_activity = activity;
        m_locationManager = (LocationManager)activity.getSystemService(Activity.LOCATION_SERVICE);
    }

    public void startGPS() {
        final LocationListener listener = this;
        m_activity.runOnUiThread(new Runnable() {
            public void run() {
                m_locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0, 0, listener);
                m_locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 0, 0, listener);
            }
        });
    }

    public void stopGPS() {
        final LocationListener listener = this;
        m_locationManager.removeUpdates(listener);
    }

    @Override
    public void onLocationChanged(Location location) {
        locationDataUpdated(location.getLatitude(), location.getLongitude(), location.getAltitude(), location.getAccuracy());
    }

    public static native void locationDataUpdated(double latitude, double longitude, double altitude, double accuracy);

    @Override
    public void onProviderDisabled(String provider) {
        Log.i(TAG, "onProviderDisabled " + provider);
    }

    @Override
    public void onProviderEnabled(String provider) {
        Log.i(TAG, "onProviderEnabled " + provider);
    }

    @Override
    public void onStatusChanged(String provider, int status, Bundle extras) {
        Log.i(TAG, "onStatusChanged " + provider);
    }

    public float getScreenDensity() {
        DisplayMetrics metrics = new DisplayMetrics();
        m_activity.getWindowManager().getDefaultDisplay().getMetrics(metrics);
        return metrics.density * 160;
    }

    public int getRotation() {
        Display display = m_activity.getWindowManager().getDefaultDisplay();
        return display.getRotation();
    }
};

