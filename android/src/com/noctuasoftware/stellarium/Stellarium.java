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
    public static boolean canPause = false;
    private static String[] LOC_PROVIDERS = {
        LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER};

    public Stellarium(Activity activity) {
        m_activity = activity;
        m_locationManager = (LocationManager)activity.getSystemService(Activity.LOCATION_SERVICE);
    }

    public void setCanPause(boolean value) {
        canPause = value;
    }

    public String getModel() {
        return android.os.Build.MANUFACTURER + ":" + android.os.Build.MODEL;
    }

    private Location getLastKnownLocation()
    {
        Location ret = null;
        for (String provider : LOC_PROVIDERS) {
            if (!m_locationManager.isProviderEnabled(provider)) continue;
            ret = m_locationManager.getLastKnownLocation(provider);
            if (ret != null) break;
        }
        return ret;
    }

    public int isGPSSupported() {
        for (String provider : LOC_PROVIDERS) {
            if (m_locationManager.isProviderEnabled(provider)) return 1;
        }
        return 0;
    }

    public void startGPS() {
        final LocationListener listener = this;
        m_activity.runOnUiThread(new Runnable() {
            public void run() {
                boolean ok = false;
                final long minTime = 60 * 1000;

                // Alway start with the last known location, with an artificial
                // high inaccuracy.
                Location location = getLastKnownLocation();
                if (location != null) {
                    locationDataUpdated(location.getLatitude(),
                                        location.getLongitude(),
                                        location.getAltitude(),
                                        10000);
                }

                for (String provider : LOC_PROVIDERS) {
                    if (!m_locationManager.isProviderEnabled(provider)) continue;
                    m_locationManager.requestLocationUpdates(provider, minTime, 0, listener);
                }
            }
        });
    }

    public void stopGPS() {
        final LocationListener listener = this;
        m_locationManager.removeUpdates(listener);
    }

    @Override
    public void onLocationChanged(Location location) {
        Log.d(TAG, "onLocationChanged: " + location.getProvider() + " acc:" + location.getAccuracy());
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

