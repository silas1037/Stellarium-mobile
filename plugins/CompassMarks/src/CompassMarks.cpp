/*
 * Copyright (C) 2009 Matthew Gates
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

#include "VecMath.hpp"
#include "StelProjector.hpp"
#include "StelPainter.hpp"
#include "StelApp.hpp"
#include "StelCore.hpp"
#include "StelLocaleMgr.hpp"
#include "StelModuleMgr.hpp"
#include "StelUtils.hpp"
#include "StelFileMgr.hpp"
#include "LandscapeMgr.hpp"
#include "CompassMarks.hpp"
#include "StelGui.hpp"
#include "StelGuiItems.hpp"
#include "StelIniParser.hpp"

#include <QDebug>
#include <QPixmap>
#include <QSettings>
#include <QKeyEvent>
#include <QtNetwork>
#include <cmath>

//! This method is the one called automatically by the StelModuleMgr just
//! after loading the dynamic library
StelModule* CompassMarksStelPluginInterface::getStelModule() const
{
	return new CompassMarks();
}

StelPluginInfo CompassMarksStelPluginInterface::getPluginInfo() const
{
	// Allow to load the resources when used as a static plugin
	Q_INIT_RESOURCE(CompassMarks);

	StelPluginInfo info;
	info.id = "CompassMarks";
	info.displayedName = N_("Compass Marks");
	info.authors = "Matthew Gates";
	info.contact = "http://porpoisehead.net/";
	info.description = N_("Displays compass bearing marks along the horizon");
	return info;
}

CompassMarks::CompassMarks()
	: markColor(1,1,1), pxmapGlow(NULL), pxmapOnIcon(NULL), pxmapOffIcon(NULL), toolbarButton(NULL)
{
	setObjectName("CompassMarks");

	QSettings* conf = StelApp::getInstance().getSettings();
	// Setup defaults if not present
	if (!conf->contains("CompassMarks/mark_color"))
		conf->setValue("CompassMarks/mark_color", "1,0,0");

	if (!conf->contains("CompassMarks/font_size"))
		conf->setValue("CompassMarks/font_size", 10);

	if (!conf->contains("CompassMarks/enable_at_startup"))
		conf->setValue("CompassMarks/enable_at_startup", false);

	// Load settings from main config file
	markColor = StelUtils::strToVec3f(conf->value("CompassMarks/mark_color", "1,0,0").toString());
	font.setPixelSize(conf->value("CompassMarks/font_size", 10).toInt());
}

CompassMarks::~CompassMarks()
{
	if (pxmapGlow!=NULL)
		delete pxmapGlow;
	if (pxmapOnIcon!=NULL)
		delete pxmapOnIcon;
	if (pxmapOffIcon!=NULL)
		delete pxmapOffIcon;
	
	// TODO (requires work in core API)
	// 1. Remove button from toolbar
	// 2. Remove action from GUI
	// 3. Delete GUI objects.  I'll leave this commented right now because
	// unloading (when implemented) might cause problems if we do it before we
	// can do parts 1 and 2.
	//if (toolbarButton!=NULL)
	//	delete toolbarButton;
	// BTW, the above remark is from 2009 --BM
	// See http://stellarium.svn.sourceforge.net/viewvc/stellarium/trunk/extmodules/CompassMarks/src/CompassMarks.cpp?r1=4333&r2=4332&pathrev=4333
}

//! Determine which "layer" the plugin's drawing will happen on.
double CompassMarks::getCallOrder(StelModuleActionName actionName) const
{
	if (actionName==StelModule::ActionDraw)
		return StelApp::getInstance().getModuleMgr().getModule("LandscapeMgr")->getCallOrder(actionName)+10.;
	return 0;
}

void CompassMarks::init()
{
	qDebug() << "CompassMarks plugin - press control-C to toggle compass marks";
	try
	{
		StelGui* gui = dynamic_cast<StelGui*>(StelApp::getInstance().getGui());
		pxmapGlow = new QPixmap(":/graphicGui/glow32x32.png");
		pxmapOnIcon = new QPixmap(":/compassMarks/bt_compass_on.png");
		pxmapOffIcon = new QPixmap(":/compassMarks/bt_compass_off.png");

		addAction("actionShow_Compass_Marks", N_("Compass Marks"), N_("Compass marks"), "marksVisible");
		toolbarButton = new StelButton(NULL, *pxmapOnIcon, *pxmapOffIcon, *pxmapGlow, "actionShow_Compass_Marks");
		gui->getButtonBar()->addButton(toolbarButton, "065-pluginsGroup");
		connect(GETSTELMODULE(LandscapeMgr), SIGNAL(cardinalsPointsDisplayedChanged(bool)), this, SLOT(cardinalPointsChanged(bool)));
		cardinalPointsState = false;

		QSettings* conf = StelApp::getInstance().getSettings();
		setCompassMarks(conf->value("CompassMarks/enable_at_startup", false).toBool());
	}
	catch (std::runtime_error& e)
	{
		qWarning() << "WARNING: unable create toolbar button for CompassMarks plugin: " << e.what();
	}


}

//! Draw any parts on the screen which are for our module
void CompassMarks::draw(StelCore* core)
{
	if (markFader.getInterstate() <= 0.0) { return; }

	Vec3d pos;
	StelProjectorP prj = core->getProjection(StelCore::FrameAltAz, StelCore::RefractionOff); // Maybe conflict with Scenery3d branch. AW20120214 No. GZ20120826.
	StelPainter painter(prj);
	painter.setFont(font);

	painter.setColor(markColor[0], markColor[1], markColor[2], markFader.getInterstate());
	glDisable(GL_TEXTURE_2D);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	glEnable(GL_LINE_SMOOTH);

	for(int i=0; i<360; i++)
	{
		float a = i*M_PI/180;
		pos.set(sin(a),cos(a), 0.f);
		float h = -0.002;
		if (i % 15 == 0)
		{
			h = -0.02;  // the size of the mark every 15 degrees

			QString s = QString("%1").arg((i+90)%360);

			float shiftx = painter.getFontMetrics().width(s) / 2.;
			float shifty = painter.getFontMetrics().height() / 2.;
			painter.drawText(pos, s, 0, -shiftx, shifty);
		}
		else if (i % 5 == 0)
		{
			h = -0.01;  // the size of the mark every 5 degrees
		}

		glDisable(GL_TEXTURE_2D);
		painter.drawGreatCircleArc(pos, Vec3d(pos[0], pos[1], h), NULL);		
		glEnable(GL_TEXTURE_2D);
	}
	glDisable(GL_LINE_SMOOTH);
	glDisable(GL_BLEND);
	glEnable(GL_TEXTURE_2D);

}

void CompassMarks::update(double deltaTime)
{
	markFader.update((int)(deltaTime*1000));
}

void CompassMarks::setCompassMarks(bool b)
{
	if (b == markFader)
		return;
	if (b)
	{
		// Save the display state of the cardinal points and hide them.
		cardinalPointsState = GETSTELMODULE(LandscapeMgr)->getFlagCardinalsPoints();
		GETSTELMODULE(LandscapeMgr)->setFlagCardinalsPoints(false);
	} else {
		// Restore the cardinal points state.
		GETSTELMODULE(LandscapeMgr)->setFlagCardinalsPoints(cardinalPointsState);
	}
	markFader = b;
	emit compassMarksChanged(b);
}

void CompassMarks::cardinalPointsChanged(bool b)
{
	if (b && getCompassMarks()) {
		cardinalPointsState = true;
		setCompassMarks(false);
	}
}
