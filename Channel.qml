// Copyright 2015 Cutehacks AS. All rights reserved.
// License can be found in the LICENSE file.

import QtQuick 2.0
import "pusher.js" as Pusher

Item {
    id: channel
    default property alias bindings: bindings.children
    property string name: ""
    property bool active: true

    readonly property alias subscribed: channel._subscribed

    property bool _authenticated: false
    property string _oldName: name
    property bool _connected: parent.state == "connected"
    property bool _subscribed: false

    function _handleEvent(event) {
        if (event.event == "pusher_internal:subscription_succeeded") {
            _subscribed = true;
            _oldName = name;
        }
        bindings.dispatchEvent(event);
    }

    function _updateAuthStatus(err, response) {
        if (err) {
            var errEvent = {
                data: {
                    code: response,
                    message: "Forbidden"
                }
            }
            parent.handleError(errEvent);
            _subscribed = false;
            _authenticated = false;
            return;
        }

        if (response.auth) {
            _authenticated = true;

            var data = {
                auth: response.auth
            };

            _subscribe(data);
        }
    }

    function _subscribe(data) {
        var validName = (name != "" && name != "private-");

        if (_connected && active && validName) {
            if (Pusher.requiresAuth(name) && !_authenticated) {
                parent.authorize(name, _updateAuthStatus);
            } else {
                parent.subscribe(name, _handleEvent, data);
            }
        }
    }

    function _unsubscribe() {
        if (subscribed) {
            parent.unsubscribe(_oldName);
            _subscribed = false;
            _authenticated = false;
        }
    }

    onNameChanged: {
        _unsubscribe();
        _subscribe();
    }

    onActiveChanged: {
        if (active) {
            _subscribe();
        } else {
            _unsubscribe();
        }
    }

    on_ConnectedChanged: {
        if (active && _connected) {
            _subscribe();
        } else {
            _unsubscribe();
        }
    }

    BindingList {
        id: bindings
    }
}

