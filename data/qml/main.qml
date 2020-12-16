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
import Stellarium 1.0

Item {
	id: root
	property string mode: "DEFAULT" // DEFAULT | TIME | QUICKBAR | DIALOGS | SETTINGS

	// Show equatorial grid in time mode when we drag.
	property bool savedGridFlag;
	StelAction {
		id: showEquatorGrid
		action: "actionShow_Equatorial_Grid"
	}
	property alias dragging: touchPinchArea.dragging
	onDraggingChanged: {
		if (root.mode !== "TIME") return
		if (dragging) {
			savedGridFlag = showEquatorGrid.checked
			showEquatorGrid.checked = true
		} else {
			showEquatorGrid.checked = savedGridFlag
		}
	}

	// XXX: this is a bit messy.
	onModeChanged: {
		if (mode === "SETTINGS") {
			settingsPanel.state = "visible"
		} else if (mode !== "DIALOGS") {
			settingsPanel.close(false)
		}
		if (mode == "DEFAULT") { // The focus could have been grabed by the search box.
			root.focus = true
		}
	}

	Stellarium {
		id: stellarium
		anchors.fill: parent
		forwardClicks: mode !== "DEFAULT"
		property bool hasSelectedObject: stellarium.selectedObjectInfo !== ""

		// Trick to deselect current object when we click on it again.
		property string lastSelectedObject
		onSelectedObjectChanged: {
			if (selectedObjectName && selectedObjectName == lastSelectedObject) {
				lastSelectedObject = ""
				unselectObject()
				return
			}
			lastSelectedObject = selectedObjectName
			root.mode = "DEFAULT"
		}

		TouchPinchArea {
			id: touchPinchArea
			anchors.fill: parent
			useMouseArea: root.mode === "SETTINGS" || stellarium.desktop
			onPressed: stellarium.touch(0, x, height - 1 - y)
			onReleased: {
				if (root.mode === "DEFAULT")
					stellarium.touch(1, x, height - 1 - y)
				stellarium.dragTimeMode = false
				root.mode = "DEFAULT"
				Qt.inputMethod.hide()
			}
			onMoved: stellarium.touch(2, x, height - 1 - y)
			onPinchStarted: stellarium.pinch(1, true)
			onPinchUpdated: stellarium.pinch(pinch, false)
		}

		onDragTimeModeChanged: {
			if (dragTimeMode) {
				root.mode = "TIME"
			} else {
				root.mode = "DEFAULT"
			}
		}

		Component.onCompleted: {
			if (autoGotoNight && isDay()) {
				goToNight.start();
			}
		}

		Timer {
			id: goToNight
			property int state: 0
			interval: 1000
			running: false
			repeat: true
			triggeredOnStart: true
			onTriggered: {
				if (state === 0) {
					rootMessage.show(qsTr("It is daytime, fast forward time until..."))
					state = 1
				} else if (state === 1) {
					stellarium.timeRate = 2 / 24;
					interval = 100
					state = 2
				} else if (state === 2 && !stellarium.isDay()) {
					stellarium.timeRate = 1 / 24. / 60. / 60.
					stop()
					rootMessage.show(stellarium.printableTime, 3000)
				}
			}
		}
	}

	// Handle android buttons.
	focus: true
	Keys.onReleased: {
		if (event.key === Qt.Key_MediaNext) { // Remapped from menu button.
			root.mode = "QUICKBAR"
		}
		if (event.key === Qt.Key_MediaStop) { // Remapped from search button.
			root.mode = "QUICKBAR"
			searchInput.takeFocus(true)
			Qt.inputMethod.show()
		}
		if (event.key === Qt.Key_Back) {
			if (mode === "DEFAULT") {
				event.accepted = false
				return
			}
			event.accepted = true
			mode = "DEFAULT"
		}
	}

	StelMessage {
		id: rootMessage
	}

	SettingsPanel {
		id: settingsPanel
		onClosed: root.mode = "QUICKBAR"
	}

	SearchInput {
		id: searchInput
		visible: root.mode === "QUICKBAR"
		onReturnPressed: root.mode = "DEFAULT"
	}

	InfoPanel {
		id: infoPanel
		anchors {
			left: parent.left
			top: parent.top
			margins: 0
		}
		opacity: (root.mode === "DEFAULT" && stellarium.hasSelectedObject)? 1 : 0
		visible: opacity > 0
		Behavior on opacity { PropertyAnimation {} }
	}
	

	ImageButton {
		opacity: (root.mode === "QUICKBAR")? 1 : 0
		visible: opacity > 0
		Behavior on opacity { PropertyAnimation {} }
		
		anchors {
			left: parent.left
			bottom: quickBar.top
			bottomMargin: 20*rootStyle.scale
		}
		
		source: "images/settings.png"
		helpMessage: qsTr("Settings")
		onClicked: {
			root.mode = "SETTINGS"
		}
		shadow: true
	}

	ImageButton {
		id: openQuickBarButton
		source: "images/openQuickBar.png"
		opacity: (root.mode === "DEFAULT")? 1 : 0
		visible: opacity > 0
		Behavior on opacity { PropertyAnimation {} }
		helpMessage: qsTr("Open Quick Bar")
		anchors {
			right: parent.right
			bottom: parent.bottom
		}
		onClicked: {
			root.mode = "QUICKBAR"
		}
		shadow: true
	}

	QuickBar {
		id: quickBar
		opacity: (root.mode === "QUICKBAR")? 1 : 0
		visible: opacity > 0
		Behavior on opacity { PropertyAnimation {} }
		anchors {
			horizontalCenter: parent.horizontalCenter
			bottom: parent.bottom
			margins: 5
		}
	}

	// Time.
	Item {
		id: timeBarFrame
		height: openQuickBarButton.height
		width: timeBarFrameImg.sourceSize.width*height/timeBarFrameImg.sourceSize.height
		anchors {
			left: parent.left
			bottom: parent.bottom
			margins: 0
		}
		opacity: (root.mode === "DEFAULT")? 1 : 0
		visible: opacity > 0
		Behavior on opacity { PropertyAnimation {} }
		
		Image {
			id: timeBarFrameImg
			anchors.fill: parent
			source: "images/timeBarFrame.png"
		}
		Text {
			id: hourText
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.top:  parent.top
			anchors.topMargin: 5*rootStyle.scale
			color: "white"
			font.pixelSize: rootStyle.fontNormalSize
			text: {
				var lines = stellarium.printableTime.split(" ")
				return lines[1];
			}
		}
		Text {
			id: dateText
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.top:  hourText.bottom
			anchors.topMargin: 1*rootStyle.scale
			color: "white"
			font.pixelSize: rootStyle.fontSmallSize
			text: {
				var lines = stellarium.printableTime.split(" ")
				return lines[0];
			}
		}
		MouseArea {
			anchors.fill: parent
			onClicked: {
				stellarium.dragTimeMode = true
			}
		}
	}

	TimeBar {
		id: timeBar
		opacity: (root.mode === "TIME")? 1 : 0
		visible: opacity > 0
		Behavior on opacity { PropertyAnimation {} }
		anchors {
			left: parent.left
			bottom: parent.bottom
			margins: 10
		}
		onVisibleChanged: {
			if (visible)
				rootMessage.show(qsTr("Drag sky to move in time"), 4000)
			else
				rootMessage.hide()
		}
	}

	// The zoom buttons.
	Item {
		id: zoomButtons
		opacity: (root.mode === "DEFAULT")? 0.4 : 0
		visible: opacity > 0
		Behavior on opacity { PropertyAnimation {} }
		anchors {
			bottom: parent.bottom
			left: timeBarFrame.right
			right: openQuickBarButton.left
		}
		height: childrenRect.height

		Row {
			height: childrenRect.height
			anchors.horizontalCenter: parent.horizontalCenter
			ImageButton {
				source: "images/autoZoomIn.png"
				onPressed: stellarium.zoom(1)
				onReleased: stellarium.zoom(0)
				shadow: true
			}
			ImageButton {
				source: "images/autoZoomOut.png"
				onPressed: stellarium.zoom(-1)
				onReleased: stellarium.zoom(0)
				shadow: true
			}
		}
	}

	// The fov
	Text {
		id : fov
		property double fade: 0
		opacity: fade * ((root.mode === "DEFAULT")? 0.75 : 0)
		visible: opacity > 0
		anchors {
			bottom: zoomButtons.top
			horizontalCenter: zoomButtons.horizontalCenter
		}
		text: "FOV " + stellarium.fov.toFixed(1) + '°'
		horizontalAlignment: Text.AlignHCenter
		font.pixelSize: rootStyle.fontNormalSize
		color: "white"
		onTextChanged: showAnimation.restart()
		SequentialAnimation {
			id: showAnimation
			NumberAnimation {target: fov; properties: "fade"; to: 1}
			PauseAnimation { duration: 1000 }
			NumberAnimation {target: fov; properties: "fade"; to: 0}
		}
	}

	// Show FPS
	/*
	Text {
		anchors {
			top: parent.top
			right: parent.right
		}
		color: "white"
		text: "fps:" + stellarium.fps
	}
	*/

	Item {
		id: rootStyle
		property double scale: stellarium.guiScaleFactor
		property int fontReferenceSize: 16*scale
		property int fontNormalSize: 1.2*fontReferenceSize
		property int fontSmallSize: 0.9*fontReferenceSize
		property int fontLargeSize: 1.5*fontReferenceSize
		property int fontExtraLargeSize: 2*fontReferenceSize
		property int margin: 8*scale
		// A snapped menu width to avoid having menu taking almost the screen width but not quite (which looks bad)
		property int niceMenuWidth: root.width-(400.*stellarium.guiScaleFactor)<80*stellarium.guiScaleFactor ? root.width : 400.*stellarium.guiScaleFactor
		property color color0: "#01162d"
		property color color1: "#012d1b"
	}

	// Create a color based on the style colors
	function getColor(index, darker, pressed)
	{
		var c = [rootStyle.color0, rootStyle.color1][index];
		if (darker)
			c = Qt.darker(c, darker)
		if (pressed)
			c = Qt.lighter(c, 1.5);
		return c;
	}
}
