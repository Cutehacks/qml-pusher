// Copyright 2015 Cutehacks AS. All rights reserved.
// License can be found in the LICENSE file.

import QtQuick 2.0

Item {
    id: blist
    property var _bindings: ({})

    function bind(eventName, callback, context) {
        if (eventName === "") {
            eventName = "*";
        }

        if (!_bindings[eventName]) {
            _bindings[eventName] = [];
        }
        var c = (context != undefined) ? callback : callback.bind(context);
        _bindings[eventName].push(c);
    }

    function unbind(eventName, callback) {
        if (eventName === "") {
            eventName = "*";
        }
        var callbacks = _bindings[eventName];
        if (callbacks) {
            for (var i = 0; i < callbacks.length(); i++) {
                if (callbacks[i] === callback) {
                    callbacks.splice(i, 1);
                }
            }
        }
    }

    function dispatchEvent(e) {
        var callbacks = [];
        callbacks = callbacks.concat(_bindings[e.event]);
        callbacks = callbacks.concat(_bindings["*"]);

        if (callbacks) {
            for (var i = 0; i < callbacks.length; i++) {
                if (callbacks[i]) {
                    callbacks[i](e);
                }
            }
        }
    }
}

