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

Grid {
	id: buttonGrid
	width: childrenRect.width
	height: childrenRect.height
	spacing: 5
	columns: 6

	ImageButton {
		source: "images/constellationLines.png"
		action: "actionShow_Constellation_Lines"
		setting: "viewing/flag_constellation_drawing"
		shadow: true
	}

	ImageButton {
		source: "images/constellationLabels.png"
		action: "actionShow_Constellation_Labels"
		setting: "viewing/flag_constellation_name"
		shadow: true
	}

	ImageButton {
		source: "images/starlore.png"
		action: "actionShow_Constellation_Art"
		setting: "viewing/flag_constellation_art"
		shadow: true
	}

	ImageButton {
		source: "images/equatorialGrid.png"
		action: "actionShow_Equatorial_Grid"
		setting: "viewing/flag_equatorial_grid"
		shadow: true
	}

	ImageButton {
		source: "images/azimuthalGrid.png"
		action: "actionShow_Azimuthal_Grid"
		setting: "viewing/flag_azimuthal_grid"
		shadow: true
	}

	ImageButton {
		source: "images/landscape.png"
		action: "actionShow_Ground"
		setting: "landscape/flag_landscape"
		shadow: true
	}

	ImageButton {
		source: "images/atmosphere.png"
		action: "actionShow_Atmosphere"
		setting: "landscape/flag_atmosphere"
		shadow: true
	}

	ImageButton {
		source: "images/location.png"
		action: "actionShow_Cardinal_Points"
		setting: "viewing/flag_cardinal_points"
		shadow: true
	}

	ImageButton {
		source: "images/nebulas.png"
		action: "actionShow_Nebulas"
		setting: "astro/flag_nebula_name"
		shadow: true
	}

	ImageButton {
		source: "images/planets.png"
		action: "actionShow_Planets_Labels"
		setting: "astro/flag_planets_labels"
		shadow: true
	}

	ImageButton {
		source: "images/sensors.png"
		action: "actionSensorsControl"
		shadow: true
	}

	ImageButton {
		source: "images/nightView.png"
		action: "actionNight_Mode"
		shadow: true
	}
}
