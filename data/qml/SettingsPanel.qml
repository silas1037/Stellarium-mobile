/*
 * Stellarium
 * Copyright (C) 2013 Fabien Chereau
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

import QtQuick 2.1

StelDialog {
	id: root
	title: qsTr("Settings")
	width: 200*stellarium.guiScaleFactor
	height: childrenRect.height
	Column {
		width: parent.width
		Repeater {
			model: settingsModel
			StelListItem {
				text: title;
				withArrow: true
				onClicked: root.openPage(page)
			}
		}
	}

	ListModel {
		id: settingsModel
		ListElement {
			title: "Time"
			page: "TimeDialog.qml"
		}
		ListElement {
			title: "Landscapes"
			page: "LandscapesDialog.qml"
		}
		ListElement {
			title: "Planets"
			page: "PlanetsDialog.qml"
		}
		ListElement {
			title: "Location"
			page: "LocationDialog.qml"
		}
		ListElement {
			title: "Starlore"
			page: "StarloreDialog.qml"
		}
		ListElement {
			title: "About"
			page: "AboutDialog.qml"
		}
	}
}
