// Copyright 2015 Cutehacks AS. All rights reserved.
// License can be found in the LICENSE file.

import QtQuick 2.0

Item {
    property string name: ""
    signal triggered(var event)

    function _trigger(event) {
        try {
            triggered(event);
        } catch(e) {
            console.error(e);
        }

    }

    Component.onCompleted: {
        parent.bind(name, _trigger);
    }
}

