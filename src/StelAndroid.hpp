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

#include <QString>
#include <QFileInfo>

class StelAndroid
{
public:
	static float getScreenDensity();
	static bool GPSSupported();
	static void setGPSCallback(void (*callback)(double, double, double, double));
	static void (*GPSCallback)(double, double, double, double);
	static int getOrientation();
	static void setCanPause(bool value);
	static QString getModel();
private:
	static class QAndroidJniObject* getStellarium();
};

//! A subclass of QFileInfo that optimize access to assets files by using
//! a precomputed list of all the assets.
//! This is just a hack to improve the loading speed on android.
//! At the first occasion we should remove this class.
class AndroidFileInfo : protected QFileInfo
{
public:
	AndroidFileInfo(const QString& file);
	bool isAbsolute() const;
	QString	filePath() const;
	QString absoluteFilePath() const;
	QString	baseName();
	bool exists() const;
	bool isWritable() const;
	bool isReadable() const;
	bool isFile() const;
	bool isDir() const;
	qint64 size();
	QDir dir() const;
	QStringList entryList() const;
private:
	void compute();
	static QStringList entries;
	static void initEntries();
	static bool initialized;
	bool isAsset; // The file in the assets.
	QString path;
};
