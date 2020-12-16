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

#include "StelAndroid.hpp"

#include <jni.h>
#include <QDebug>
#include <QStringList>
#include <QRegExp>
#include <QDir>
#include <QAndroidJniObject>
#include <QAndroidJniEnvironment>

void (*StelAndroid::GPSCallback)(double, double, double, double) = NULL;

static void locationDataUpdated(JNIEnv* env, jobject thiz, double latitude, double longitude,
                                double altitude, double accuracy)
{
	Q_UNUSED(env)
	Q_UNUSED(thiz)
	if (StelAndroid::GPSCallback)
		StelAndroid::GPSCallback(latitude, longitude, altitude, accuracy);
}

jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
	Q_UNUSED(reserved);
	JNINativeMethod methods[] {{"locationDataUpdated", "(DDDD)V", reinterpret_cast<void *>(locationDataUpdated)}};
	JNIEnv* env;
	if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_4) != JNI_OK)
	{
		return -1;
	}
	jclass clazz = env->FindClass("com/noctuasoftware/stellarium/Stellarium");
	env->RegisterNatives(clazz, methods, sizeof(methods) / sizeof(methods[0]));
	return JNI_VERSION_1_4;
}

QAndroidJniObject* StelAndroid::getStellarium()
{
	static QAndroidJniObject* stellarium = NULL;
	if (!stellarium)
	{
		QAndroidJniObject activity = QAndroidJniObject::callStaticObjectMethod(
		            "org/qtproject/qt5/android/QtNative", "activity", "()Landroid/app/Activity;");
		stellarium = new QAndroidJniObject("com/noctuasoftware/stellarium/Stellarium", "(Landroid/app/Activity;)V",
		                                   activity.object<jobject>());
	}
	return stellarium;
}

float StelAndroid::getScreenDensity()
{
	return getStellarium()->callMethod<float>("getScreenDensity", "()F");
}

bool StelAndroid::GPSSupported()
{
	return getStellarium()->callMethod<int>("isGPSSupported", "()I");
}

void StelAndroid::setGPSCallback(void (*callback)(double, double, double, double))
{
	StelAndroid::GPSCallback = callback;
	if (callback)
		getStellarium()->callMethod<void>("startGPS", "()V");
	else
		getStellarium()->callMethod<void>("stopGPS", "()V");
}

int StelAndroid::getOrientation()
{
	return getStellarium()->callMethod<int>("getRotation", "()I");
}

void StelAndroid::setCanPause(bool value)
{
	getStellarium()->callMethod<void>("setCanPause", "(Z)V", value);
}

QString StelAndroid::getModel()
{
	return getStellarium()->callObjectMethod<jstring>("getModel").toString();
}

QStringList AndroidFileInfo::entries;
bool AndroidFileInfo::initialized = false;

void AndroidFileInfo::initEntries()
{
	QFile file("assets:/data/files.txt");
	file.open(QIODevice::ReadOnly);
	QTextStream in(&file);
	while(!in.atEnd())
	{
		QString line = in.readLine();
		entries << "assets:/" + line;
	}
	file.close();
	initialized = true;
}

AndroidFileInfo::AndroidFileInfo(const QString& file) : isAsset(false)
{
	if (!initialized)
		initEntries();
	if (file.startsWith("assets:"))
	{
		isAsset = true;
		path = file;
		if (entries.contains(file + "/"))
			path.append('/');
	}
	if (!isAsset)
		setFile(file);
}

void AndroidFileInfo::compute()
{
	if (!isAsset)
	{
		qWarning() << "slow";
		setFile(path);
		isAsset = false;
	}
}

QString	AndroidFileInfo::baseName()
{
	compute();
	return QFileInfo::baseName();
}

bool AndroidFileInfo::isAbsolute() const
{
	if (!isAsset)
		return QFileInfo::isAbsolute();
	return true;
}

QString	AndroidFileInfo::filePath() const
{
	if (!isAsset)
		return QFileInfo::filePath();
	return path;
}

QString AndroidFileInfo::absoluteFilePath() const
{
	if (!isAsset)
		return QFileInfo::absoluteFilePath();
	return path;
}

bool AndroidFileInfo::exists() const
{
	if (!isAsset)
		return QFileInfo::exists();
	return entries.contains(path);
}

bool AndroidFileInfo::isReadable() const
{
	if (!isAsset)
		return QFileInfo::isReadable();
	return true;
}

bool AndroidFileInfo::isWritable() const
{
	if (!isAsset)
		return QFileInfo::isWritable();
	return false;
}

bool AndroidFileInfo::isFile() const
{
	if (!isAsset)
		return QFileInfo::isFile();
	return !path.endsWith('/');
}

bool AndroidFileInfo::isDir() const
{
	if (!isAsset)
		return QFileInfo::isDir();
	return path.endsWith('/');
}

qint64 AndroidFileInfo::size()
{
	compute();
	return QFileInfo::size();
}

QDir AndroidFileInfo::dir() const
{
	if (!isAsset)
		return QFileInfo::dir();
	return QFileInfo(path).dir();
}

QStringList AndroidFileInfo::entryList() const
{
	Q_ASSERT(isAsset);
	QStringList ret;
	foreach (QString entry, entries)
	{
		if (!entry.startsWith(path))
			continue;
		entry = entry.remove(0, path.size());
		if (entry.endsWith("/")) entry.chop(1);
		if (!entry.contains('/') && !entry.isEmpty())
			ret.append(entry);
	}
	return ret;
}
