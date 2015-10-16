// Copyright 2015 Cutehacks AS. All rights reserved.
// License can be found in the LICENSE file.

import QtQuick 2.0

Item {
    default property alias bindings: bindings.children
    property string name: ""
    property bool subscribed: false
    property bool subscriptionSucceeded: false
    property bool subscriptionError: false

    property bool connected: parent.state == "connected"

    function handleEvent(event) {
        bindings.dispatchEvent(event);
    }

    onConnectedChanged: {
        if (connected) {
            parent.subscribe(name, handleEvent);
        }
    }

    BindingList {
        id: bindings
    }
}

