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
#include "StelApp.hpp"
#include "StelCore.hpp"
#include "StelModuleMgr.hpp"
#include <QDebug>

#ifdef Q_OS_ANDROID
#  include "StelAndroid.hpp"
#  define BACKEND StelAndroid
#elif defined Q_OS_IOS
#  include "StelIOS.hpp"
#  define BACKEND StelIOS
#endif

GPSMgr::GPSMgr() :
	state(GPSMgr::Disabled)
{
	setObjectName("GPSMgr");
#ifdef Q_OS_ANDROID
	if (!StelAndroid::GPSSupported())
		state = Unsupported;
#endif
}

GPSMgr::~GPSMgr()
{
#ifdef BACKEND
	BACKEND::setGPSCallback(NULL);
#endif
}

void GPSMgr::init()
{
	qRegisterMetaType<GPSMgr::State>("GPSMgr::State");
	addAction("actionGPS", N_("Movement and Selection"), N_("GPS"), "enabled");
	if (StelApp::getInstance().getCore()->getCurrentLocation().name == "GPS")
	{
		setEnabled(true);
	}
}

static void onLocationChanged(double latitude, double longitude, double altitude, double accuracy);

static void setGPSStatus(bool value)
{
#ifdef BACKEND
	BACKEND::setGPSCallback(value ? &onLocationChanged : NULL);
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
	if (state == Unsupported)
		return;
	if (isEnabled() == value)
		return;
	state = value ? Searching : Disabled;
	setGPSStatus(value);
	emit stateChanged(state);
	emit enabledChanged(value);
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
	if (accuracy < 500) // Stop GPS when accuracy is < 500 m.
	{
		setGPSStatus(false);
		state = Found;
		emit stateChanged(state);
	}
}
