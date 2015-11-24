// Copyright 2015 Cutehacks AS. All rights reserved.
// License can be found in the LICENSE file.

import QtQuick 2.0
import "pusher.js" as Pusher

Item {
    default property alias bindings: bindings.children
    property string name: ""
    property bool subscribed: false
    property bool subscriptionSucceeded: false
    property bool subscriptionError: false

    property bool connected: parent.state == "connected"

    property bool _authenticated: false

    function handleEvent(event) {
        bindings.dispatchEvent(event);
    }

    function updateAuthStatus(err, response) {
        if (err) {
            return
        }

        if (response.auth) {
            _authenticated = true;

            var data = {
                auth: response.auth
            };

            parent.subscribe(name, handleEvent, data);
        }
    }

    onConnectedChanged: {
        if (connected) {
            if (Pusher.requiresAuth(name) && !_authenticated) {
                parent.authorize(name, updateAuthStatus);
            } else {
                parent.subscribe(name, handleEvent);
            }
        }
    }

    BindingList {
        id: bindings
    }
}

