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

StelSpinBox {
	id: root
	property string type // year | month | day | hour | minute | second
	property date time
	property date newTime // Se use it to avoid nasty loops with stellarium time!
	text: type
	min: -10000
	max: 10000
	valueText: value < 10 ? "0%1".arg(value) : "%1".arg(value)

	onTimeChanged: setValue()

	function setValue() {
		if (type == "year")
			value = time.getFullYear()
		if (type == "month")
			value = time.getMonth() + 1
		if (type == "day")
			value = time.getDate()
		if (type == "hour")
			value = time.getHours()
		if (type == "minute")
			value = time.getMinutes()
		if (type == "second")
			value = time.getSeconds()
	}

	onValueChanged: {
		var time = new Date(root.time)
		if (type == "year")
			time.setFullYear(value)
		if (type == "month")
			time.setMonth(value - 1)
		if (type == "day")
			time.setDate(value)
		if (type == "hour")
			time.setHours(value)
		if (type == "minute")
			time.setMinutes(value)
		if (type == "second")
			time.setSeconds(value)
		newTime = time
	}
}
