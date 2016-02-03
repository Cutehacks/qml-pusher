# qml-pusher

This is a QML client library for the [Pusher](https://www.pusher.com) service. Internally
it uses QML's `WebSocket` element, but should have no other dependencies apart from that.
 
## Installing
 
The module is available on qpm:

```
qpm install com.cutehacks.pusher
```

## Usage

Here is a code snippet demonstrating how the component is used:

```
import com.cutehacks.pusher 1.0

...

    // Declare the Pusher item and register the appKey
    Pusher {
        id: pusher
        appKey: "YOUR_APP_KEY"
        encrypted: true

        onStateChanged: {
            console.log(state);
        }

        onError: {
            console.log(code);
            console.log(message);
        }

        // Declare Channels to listen to channel events
        Channel {
            id: fooChannel
            name: "foo"

            // Declare an Event that will be triggered for all events on this
            // channel
            Event {
                onTriggered: {
                    console.log("channel event triggered: " + fooChannel.name);
                    console.log(JSON.stringify(event, null, 4));
                }
            }

            // Declare an Event that will be triggered for a specific event
            Event {
                name: "bar"
                onTriggered: {
                    console.log("channel event triggered for: " + fooChannel.name);
                    console.log(JSON.stringify(event, null, 4));
                }
            }
        }

        // Declare an Event that will be triggered for all events on all channels
        Event {
            onTriggered: {
                console.log("pusher event triggered");
                console.log(JSON.stringify(event, null, 4));
            }
        }

        // Declare an Event that will be triggered for a specific event on
        // all channels
        Event {
            name: "bar"
            onTriggered: {
                console.log("pusher event triggered: " + name);
                console.log(JSON.stringify(event, null, 4));
            }
        }
    }
```

At the moment there are three QML items that make up the API.

### Pusher

This must be the topmost item in the hierarchy and declares properties for setting up the
connection. It contains the following properties:

#### appKey : string 

The appKey for your Pusher account.

#### encrypted : bool [true]

Determines whether the connection to Pusher should be encrypted or not.

#### pingTimeout : int [30]

Specifies the time in seconds that the client should wait before triggering a timeout. If a
timeout occurs, the state property will be "unavailable" and the module will automatically
call the ping() function at intervals specified by this property.

#### state : string ["initialized"]

Indicates the current state of the connection. Each state is also available as a boolean
property on this object (eg: connected). This is done as a convenience so you can trigger
functions on specific states (eg: onConnected).

#### error : signal(code, message)

This signal is emitted when an error occurs either internally or if one is returned from
Pusher.

#### ping() : function

Sends a ping request to Pusher and resets the internal timeout timer as well as the inactivity timer.
Normally you should not need to call this function as it is called internally by the module.

#### disconnect() :  function

Disconnects from Pusher.

#### reconnect() :  function

Reconnects to Pusher. Useful after a network disruption.

#### authEndpoint : string ["/pusher/auth"]

Not implemented yet.

#### authTransport : string ["ajax"]

Not implemented yet.

#### auth : object

Not implemented yet.

#### cluster : string

Not implemented yet.

#### disableStats : bool [false]

Not implemented yet.

### Channel

This is for subscribing to specific channels in the Pusher session. A `Channel` must be declared
as the child of a `Pusher` item.

#### name : string

The name of the channel you want to subscribe to.

#### active : bool

Whether or not the channel should be active and therefore listening to events.

#### subscribed : readonly bool

Indicates that the channel is properly subscribed and listening for events.

### Event

This item represents a binding to a particular event type. An `Event` must be declared as a child
of a `Pusher` item or a `Channel` item.

#### name : string

The type of event to listen for. Omitting this property will create a binding for all events.
 
#### triggered : signal

This signal is emitted whenever a new event arrives.

## TODO

The following pieces of functionality are not yet implemented:

* Presence Channels
* Channel Client Events

