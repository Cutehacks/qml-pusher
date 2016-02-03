// Copyright 2015 Cutehacks AS. All rights reserved.
// License can be found in the LICENSE file.

import QtQuick 2.0
import QtWebSockets 1.0
import "pusher.js" as Pusher

Item {
    id: client
    default property alias connection: connection.children
    property alias appKey: connection.appKey
    property alias encrypted: connection.encrypted
    property alias authEndpoint: connection.authEndpoint
    property alias authTransport: connection.authTransport
    property alias auth: connection.auth
    property alias cluster: connection.cluster
    property alias disableStats: connection.disableStats
    property alias pingTimeout: connection.pingTimeout
    readonly property alias state: connection.state

    readonly property bool initialized:     connection.state == "initialized"
    readonly property bool connecting:      connection.state == "connecting"
    readonly property bool connected:       connection.state == "connected"
    readonly property bool unavailable:     connection.state == "unavailable"
    readonly property bool failed:          connection.state == "failed"
    readonly property bool disconnected:    connection.state == "disconnected"

    signal error(var code, var message)

    // Public functions
    function disconnect() {
        socket.active = false;
    }

    function reconnect() {
        socket.active = false;
        socket.active = true;
    }

    function ping() {
        connection.ping();
    }

    // Internal item
    BindingList {
        id: connection
        property string appKey: ""
        property bool encrypted: true
        property string authEndpoint: "/pusher/auth"
        property string authTransport: "ajax"
        property var auth: ({
            params: {},
            headers: {}
        })
        property string cluster: ""
        property bool disableStats: false

        state: "initialized"

        states: [
            State {
                name: "initialized"
            },
            State {
                name: "connecting"
            },
            State {
                name: "connected"
            },
            State {
                name: "unavailable"
            },
            State {
                name: "failed"
            },
            State {
                name: "disconnected"
            }
        ]

        property int autoPingInterval: 120
        property int pingTimeout: 30

        // Internal properties
        property string socketId: ""
        property int _protocol: 7
        property string _client: Qt.platform.os + "-libQtPusher"
        property string _version: "1.9.3"
        property var _handlers: ({
            "pusher:ping": connection.handlePing,
            "pusher:pong": connection.handlePong,
            "pusher:connection_established": connection.handleConnectionEstablished,
            "pusher:error": connection.handleError
        })

        property var _channels: ({})

        function authorize(channelName, callback) {
            if (!connection.auth.headers && !connection.auth.params) {
                Pusher.warn("No 'auth' fields found.")
            }

            var xhr = new XMLHttpRequest();
            xhr.open("POST", connection.authEndpoint);
            xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            for(var headerName in connection.auth.headers) {
                xhr.setRequestHeader(headerName, connection.auth.headers[headerName]);
            }

            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    if (xhr.status === 200) {
                        var data, parsed = false;

                        try {
                            data = JSON.parse(xhr.responseText);
                            parsed = true;
                        } catch (e) {
                            callback(true, 'JSON returned from webapp was invalid, yet status code was 200. Data was: ' + xhr.responseText);
                        }

                        if (parsed) { // prevents double execution.
                            callback(false, data);
                        }
                    } else {
                        Pusher.warn("Couldn't get auth info from your webapp", xhr.status);
                        callback(true, xhr.status);
                    }
                }
            };

            var data = connection.composeQuery(channelName, connection.socketId);
            xhr.send(data);
        }

        function composeQuery(channelName, socketId) {
            var query = 'socket_id=' + encodeURIComponent(socketId) +
                    '&channel_name=' + encodeURIComponent(channelName);

            for(var i in connection.auth.params) {
                query += "&" + encodeURIComponent(i) + "=" + encodeURIComponent(connection.auth.params[i]);
            }

            return query;
        }

        function subscribe(channel, callback, data) {
            var data = data || {};
            data.channel = channel;

            var e = new Pusher.Event("pusher:subscribe", data);
            sendEvent(e);
            _channels[channel] = callback;
        }

        function unsubscribe(channel) {
            var data = data || {};
            data.channel = channel;
            var e = new Pusher.Event("pusher:unsubscribe", data);
            sendEvent(e);
            delete _channels[channel];
        }

        function ping() {
            var ping = new Pusher.Event("pusher:ping", {});
            sendEvent(ping);
        }

        function pong() {
            var pong = new Pusher.Event("pusher:pong", {});
            sendEvent(pong);
        }

        function handlePong(event) {
            // nothing to do (?)
        }

        function handlePing(event) {
            pong();
        }

        function handleConnectionEstablished(event) {
            connection.socketId = event.data.socket_id;
            connection.autoPingInterval = event.data.activity_timeout;
            connection.state = "connected";
        }

        function handleError(event) {
            client.error(event.data.code, event.data.message);
        }

        function sendEvent(event) {
            var message = JSON.stringify(event);
            socket.sendTextMessage(message);
            inactivityTimer.restart();
            timeoutTimer.restart();
        }

        Timer {
            id: inactivityTimer
            interval: connection.autoPingInterval * 1000
            running: false
            onTriggered: {
                connection.ping(); // keep-alive
            }
        }

        Timer {
            id: timeoutTimer
            interval: connection.pingTimeout * 1000
            running: false
            onTriggered: {
                connection.state = "unavailable"
                connection.ping(); // retry
            }
        }

        WebSocket {
            id: socket
            url: (connection.encrypted ? "wss" : "ws") +
                 "://ws.pusherapp.com:" +
                 (connection.encrypted ? "443" : "80") +
                 "/app/" + connection.appKey + "?" +
                 "protocol=" + connection._protocol +
                 "&client=" + connection._client +
                 "&version=" + connection._version

            active: true

            onTextMessageReceived: {
                inactivityTimer.restart();
                timeoutTimer.stop();

                var e = new Pusher.Event(message);

                // Handle event locally first
                var handler = connection._handlers[e.event];
                if (handler) {
                    handler(e);
                }

                if (connection.state !== "connected" && connection.socketId != "")
                    connection.state = "connected";

                // Dispatch event to registered channels
                if (e.channel) {
                    var chCallback = connection._channels[e.channel];
                    if (chCallback) {
                        chCallback(e);
                    }
                }

                // Dispatch events to any Bind elements on Pusher item
                connection.dispatchEvent(e);
            }

            onStatusChanged: {
                switch (status) {
                case WebSocket.Connecting:
                    connection.state = "connecting";
                    break;
                case WebSocket.Open:
                    // Don't go to "connected", until we get
                    // connection_established event.
                    connection.state = "connecting";
                    break;
                case WebSocket.Closed:
                    connection.state = "disconnected";
                    break;
                case WebSocket.Error:
                    connection.state = "failed";
                    break;
                default:
                    break;
                }
            }

            onErrorStringChanged: {
                if (errorString === "")
                    return;

                var data = {
                    message: errorString
                };

                var e = new Pusher.Event("websocket:error", data);
                connection.handleError(e);
            }
        }
    }
}

