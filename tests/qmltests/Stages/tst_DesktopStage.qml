/*
 * Copyright (C) 2015 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtTest 1.0
import Ubuntu.Components 1.1
import Ubuntu.Components.ListItems 1.0 as ListItem
import Unity.Application 0.1
import Unity.Test 0.1
import Utils 0.1

import "../../../qml/Stages"

Item {
    id: root
    width:  desktopStageLoader.width + controls.width
    height: desktopStageLoader.height

    Binding {
        target: MouseTouchAdaptor
        property: "enabled"
        value: false
    }

    Component.onCompleted: {
        // ensures apps which are tested decorations are in view.
        WindowStateStorage.geometry = {
            'unity8-dash': Qt.rect(0, units.gu(3), units.gu(50), units.gu(40)),
            'dialer-app': Qt.rect(units.gu(51), units.gu(3), units.gu(50), units.gu(40)),
            'camera-app': Qt.rect(0, units.gu(44), units.gu(50), units.gu(40)),
        }
    }

    Loader {
        id: desktopStageLoader
        x: ((root.width - controls.width) - width) / 2
        y: (root.height - height) / 2
        width: units.gu(160*0.9)
        height: units.gu(100*0.9)

        focus: true

        sourceComponent: Component {
            DesktopStage {
                color: "darkblue"
                anchors.fill: parent
            }
        }
    }

    Rectangle {
        id: controls
        color: "darkgrey"
        width: units.gu(30)
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: units.gu(1) }
            spacing: units.gu(1)
            Repeater {
                model: ApplicationManager.availableApplications
                ApplicationCheckBox {
                    appId: modelData
                }
            }
        }
    }

    UnityTestCase {
        id: testCase
        name: "DesktopStage"
        when: windowShown

        property Item desktopStage: desktopStageLoader.status === Loader.Ready ? desktopStageLoader.item : null

        function cleanup() {
            desktopStageLoader.active = false;

            tryCompare(desktopStageLoader, "status", Loader.Null);
            tryCompare(desktopStageLoader, "item", null);

            killAllRunningApps();

            desktopStageLoader.active = true;
            tryCompare(desktopStageLoader, "status", Loader.Ready);
        }

        function killAllRunningApps() {
            while (ApplicationManager.count > 1) {
                var appIndex = ApplicationManager.get(0).appId == "unity8-dash" ? 1 : 0
                ApplicationManager.stopApplication(ApplicationManager.get(appIndex).appId);
            }
            compare(ApplicationManager.count, 1);
        }

        function waitUntilAppSurfaceShowsUp(appId) {
            var appWindow = findChild(desktopStage, "appWindow_" + appId);
            verify(appWindow);
            var appWindowStates = findInvisibleChild(appWindow, "applicationWindowStateGroup");
            verify(appWindowStates);
            tryCompare(appWindowStates, "state", "surface");
        }

        function startApplication(appId) {
            var app = ApplicationManager.findApplication(appId);
            if (!app) {
                app = ApplicationManager.startApplication(appId);
            }
            verify(app);
            waitUntilAppSurfaceShowsUp(appId);
            verify(app.session.surface);
            return app;
        }

        function test_appFocusSwitch_data() {
            return [
                {tag: "dash to dialer", apps: [ "unity8-dash", "dialer-app", "camera-app" ], focusfrom: 0, focusTo: 1 },
                {tag: "dialer to dash", apps: [ "unity8-dash", "dialer-app", "camera-app" ], focusfrom: 1, focusTo: 0 },
            ]
        }

        function test_appFocusSwitch(data) {
            data.apps.forEach(startApplication);

            ApplicationManager.requestFocusApplication(data.apps[data.focusfrom]);
            tryCompare(ApplicationManager.findApplication(data.apps[data.focusfrom]).session.surface, "activeFocus", true);

            ApplicationManager.requestFocusApplication(data.apps[data.focusTo]);
            tryCompare(ApplicationManager.findApplication(data.apps[data.focusTo]).session.surface, "activeFocus", true);
        }

        function test_tappingOnWindowChangesFocusedApp_data() {
            return [
                {tag: "dash to dialer", apps: [ "unity8-dash", "dialer-app", "camera-app" ], focusfrom: 0, focusTo: 1 },
                {tag: "dialer to dash", apps: [ "unity8-dash", "dialer-app", "camera-app" ], focusfrom: 1, focusTo: 0 },
            ]
        }

        function test_tappingOnWindowChangesFocusedApp(data) {
            data.apps.forEach(startApplication);
            var fromAppId = data.apps[data.focusfrom];
            var toAppId = data.apps[data.focusTo]

            var fromAppWindow = findChild(desktopStage, "appWindow_" + fromAppId);
            verify(fromAppWindow);
            tap(fromAppWindow);
            compare(fromAppWindow.application.session.surface.activeFocus, true);
            compare(ApplicationManager.focusedApplicationId, fromAppId);

            var toAppWindow = findChild(desktopStage, "appWindow_" + toAppId);
            verify(toAppWindow);
            tap(toAppWindow);
            compare(toAppWindow.application.session.surface.activeFocus, true);
            compare(ApplicationManager.focusedApplicationId, toAppId);
        }

        function test_clickingOnWindowChangesFocusedApp_data() {
            return test_tappingOnWindowChangesFocusedApp_data(); // reuse test data
        }

        function test_clickingOnWindowChangesFocusedApp(data) {
            data.apps.forEach(startApplication);
            var fromAppId = data.apps[data.focusfrom];
            var toAppId = data.apps[data.focusTo]

            var fromAppWindow = findChild(desktopStage, "appWindow_" + fromAppId);
            verify(fromAppWindow);
            mouseClick(fromAppWindow);
            compare(fromAppWindow.application.session.surface.activeFocus, true);
            compare(ApplicationManager.focusedApplicationId, fromAppId);

            var toAppWindow = findChild(desktopStage, "appWindow_" + toAppId);
            verify(toAppWindow);
            mouseClick(toAppWindow);
            compare(toAppWindow.application.session.surface.activeFocus, true);
            compare(ApplicationManager.focusedApplicationId, toAppId);
        }

        function test_tappingOnDecorationFocusesApplication_data() {
            return [
                {tag: "dash to dialer", apps: [ "unity8-dash", "dialer-app", "camera-app" ], focusfrom: 0, focusTo: 1 },
                {tag: "dialer to dash", apps: [ "unity8-dash", "dialer-app", "camera-app" ], focusfrom: 1, focusTo: 0 },
            ]
        }

        function test_tappingOnDecorationFocusesApplication(data) {
            data.apps.forEach(startApplication);

            var fromAppDecoration = findChild(desktopStage, "appWindowDecoration_" + data.apps[data.focusfrom]);
            verify(fromAppDecoration);
            tap(fromAppDecoration);
            tryCompare(ApplicationManager.findApplication(data.apps[data.focusfrom]).session.surface, "activeFocus", true);

            var toAppDecoration = findChild(desktopStage, "appWindowDecoration_" + data.apps[data.focusTo]);
            verify(toAppDecoration);
            tap(toAppDecoration);
            tryCompare(ApplicationManager.findApplication(data.apps[data.focusTo]).session.surface, "activeFocus", true);
        }

        function test_clickingOnDecorationFocusesApplication_data() {
            return test_tappingOnDecorationFocusesApplication_data(); // reuse test data
        }

        function test_clickingOnDecorationFocusesApplication(data) {
            data.apps.forEach(startApplication);

            var fromAppDecoration = findChild(desktopStage, "appWindowDecoration_" + data.apps[data.focusfrom]);
            verify(fromAppDecoration);
            mouseClick(fromAppDecoration);
            tryCompare(ApplicationManager.findApplication(data.apps[data.focusfrom]).session.surface, "activeFocus", true);

            var toAppDecoration = findChild(desktopStage, "appWindowDecoration_" + data.apps[data.focusTo]);
            verify(toAppDecoration);
            mouseClick(toAppDecoration);
            tryCompare(ApplicationManager.findApplication(data.apps[data.focusTo]).session.surface, "activeFocus", true);
        }

        function test_windowMaximize() {
            var apps = ["unity8-dash", "dialer-app", "camera-app"];
            apps.forEach(startApplication);
            var appName = "dialer-app";
            var appDelegate = findChild(desktopStage, "appDelegate_" + appName);
            verify(appDelegate);
            ApplicationManager.focusApplication(appName);
            keyClick(Qt.Key_Up, Qt.MetaModifier|Qt.ControlModifier); // Ctrl+Super+Up shortcut to maximize
            tryCompare(appDelegate, "maximized", true);
            tryCompare(appDelegate, "minimized", false);
        }

        function test_windowMaximizeLeft() {
            var apps = ["unity8-dash", "dialer-app", "camera-app"];
            apps.forEach(startApplication);
            var appName = "dialer-app";
            var appDelegate = findChild(desktopStage, "appDelegate_" + appName);
            verify(appDelegate);
            ApplicationManager.focusApplication(appName);
            keyClick(Qt.Key_Left, Qt.MetaModifier|Qt.ControlModifier); // Ctrl+Super+Left shortcut to maximizeLeft
            tryCompare(appDelegate, "maximized", false);
            tryCompare(appDelegate, "minimized", false);
            tryCompare(appDelegate, "maximizedLeft", true);
            tryCompare(appDelegate, "maximizedRight", false);
        }

        function test_windowMaximizeRight() {
            var apps = ["unity8-dash", "dialer-app", "camera-app"];
            apps.forEach(startApplication);
            var appName = "dialer-app";
            var appDelegate = findChild(desktopStage, "appDelegate_" + appName);
            verify(appDelegate);
            ApplicationManager.focusApplication(appName);
            keyClick(Qt.Key_Right, Qt.MetaModifier|Qt.ControlModifier); // Ctrl+Super+Right shortcut to maximizeRight
            tryCompare(appDelegate, "maximized", false);
            tryCompare(appDelegate, "minimized", false);
            tryCompare(appDelegate, "maximizedLeft", false);
            tryCompare(appDelegate, "maximizedRight", true);
        }

        function test_windowMinimize() {
            var apps = ["unity8-dash", "dialer-app", "camera-app"];
            apps.forEach(startApplication);
            var appName = "dialer-app";
            var appDelegate = findChild(desktopStage, "appDelegate_" + appName);
            verify(appDelegate);
            ApplicationManager.focusApplication(appName);
            keyClick(Qt.Key_Down, Qt.MetaModifier|Qt.ControlModifier); // Ctrl+Super+Down shortcut to minimize
            tryCompare(appDelegate, "maximized", false);
            tryCompare(appDelegate, "minimized", true);
            verify(ApplicationManager.focusedApplicationId != ""); // verify we don't lose focus when minimizing an app
        }

        function test_windowMinimizeAll() {
            var apps = ["unity8-dash", "dialer-app", "camera-app"];
            apps.forEach(startApplication);
            verify(ApplicationManager.count == 3);
            keyClick(Qt.Key_D, Qt.MetaModifier|Qt.ControlModifier); // Ctrl+Super+D shortcut to minimize all
            tryCompare(ApplicationManager, "focusedApplicationId", ""); // verify no app is focused
        }

        function test_windowClose() {
            var apps = ["unity8-dash", "dialer-app", "camera-app"];
            apps.forEach(startApplication);
            verify(ApplicationManager.count == 3);
            var appName = "dialer-app";
            var appDelegate = findChild(desktopStage, "appDelegate_" + appName);
            verify(appDelegate);
            ApplicationManager.focusApplication(appName);
            keyClick(Qt.Key_F4, Qt.AltModifier); // Alt+F4 shortcut to close
            verify(ApplicationManager.count == 2); // verify the app is gone
            verify(ApplicationManager.findApplication(appName) === null); // and it's not in running apps
        }

        function test_smashCursorKeys() {
            var apps = ["unity8-dash", "dialer-app", "camera-app"];
            apps.forEach(startApplication);
            verify(ApplicationManager.count == 3);
            keyClick(Qt.Key_D, Qt.MetaModifier|Qt.ControlModifier); // Ctrl+Super+D shortcut to minimize all
            tryCompare(ApplicationManager, "focusedApplicationId", ""); // verify no app is focused

            // now try pressing all 4 arrow keys + ctrl + meta
            keyClick(Qt.Key_Up | Qt.Key_Down | Qt.Key_Left | Qt.Key_Right, Qt.MetaModifier|Qt.ControlModifier); // smash it!!!
            tryCompare(ApplicationManager, "focusedApplicationId", ""); // verify still no app is focused
        }
    }
}
