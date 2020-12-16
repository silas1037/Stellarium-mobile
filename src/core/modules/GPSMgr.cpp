/*
 * Stellarium
 * Copyright (C) 2013 Guillaume Chereau
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA  02110-1335, USA.
 */

#include "GPSMgr.hpp"
#include "StelTranslator.hpp"
#include "StelAndroid.hpp"
#include "StelApp.hpp"
#include "StelCore.hpp"
#include "StelModuleMgr.hpp"
#include <QDebug>

GPSMgr::GPSMgr() :
    enabled(false)
{
	setObjectName("GPSMgr");
}

GPSMgr::~GPSMgr()
{
#ifdef Q_OS_ANDROID
	StelAndroid::setGPSCallback(NULL);
#endif
}

void GPSMgr::init()
{
	addAction("actionGPS", N_("Movement and Selection"), N_("GPS"), "enabled");
	if (StelApp::getInstance().getCore()->getCurrentLocation().name == "GPS")
	{
		setEnabled(true);
	}
}

static void onLocationChanged(double latitude, double longitude, double altitude, double accuracy);

static void setGPSStatus(bool value)
{
#ifdef Q_OS_ANDROID
	StelAndroid::setGPSCallback(value ? &onLocationChanged : NULL);
#endif
}

static void onLocationChanged(double latitude, double longitude, double altitude, double accuracy)
{
	QMetaObject::invokeMethod(GETSTELMODULE(GPSMgr), "onFix", Qt::AutoConnection,
	                          Q_ARG(double, latitude),
	                          Q_ARG(double, longitude),
	                          Q_ARG(double, altitude),
	                          Q_ARG(double, accuracy));
}

void GPSMgr::setEnabled(bool value)
{
	if (value == enabled)
		return;
	enabled = value;
	setGPSStatus(enabled);
	emit enabledChanged(enabled);
}

void GPSMgr::onFix(double latitude, double longitude, double altitude, double accuracy)
{
	StelLocation loc;
	loc.planetName = "Earth";
	loc.latitude = latitude;
	loc.longitude = longitude;
	loc.altitude = altitude;
	loc.name = "GPS";
	StelApp::getInstance().getCore()->moveObserverTo(loc, 0.);
	StelApp::getInstance().getCore()->setDefaultLocationID(loc.getID());
	if (accuracy < 50000)  // Stop GPS when accuracy is < 50 km.
		setGPSStatus(false);
}
