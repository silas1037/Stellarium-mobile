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

#include "StelModule.hpp"

class GPSMgr : public StelModule
{
	Q_OBJECT
	Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)
public:
	GPSMgr();
	virtual ~GPSMgr();
	virtual void init() Q_DECL_OVERRIDE;
	virtual void update(double deltaTime) Q_DECL_OVERRIDE {Q_UNUSED(deltaTime)}
	bool isEnabled() const {return enabled;}
	void setEnabled(bool value);
	Q_INVOKABLE void onFix(double latitude, double longitude, double altitude, double accuracy);
signals:
	void enabledChanged(bool);
private:
	bool enabled;
};
