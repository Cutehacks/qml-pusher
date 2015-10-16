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

            // Declare a Bind that will be triggered for all events on this
            // channel
            Bind {
                onTriggered: {
                    console.log("channel bind called: " + fooChannel.name);
                    console.log(JSON.stringify(event, null, 4));
                }
            }

            // Declare a Bind that will be triggered for a specific event
            Bind {
                event: "bar"
                onTriggered: {
                    console.log("channel bind called for event: " + fooChannel.name);
                    console.log(JSON.stringify(event, null, 4));
                }
            }
        }

        // Declare a Bind that will be triggered for all events on all channels
        Bind {
            onTriggered: {
                console.log("pusher bind called");
                console.log(JSON.stringify(event, null, 4));
            }
        }

        // Declare a Bind that will be triggered for a specific event on
        // all channels
        Bind {
            event: "bar"
            onTriggered: {
                console.log("pusher bind called for event");
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

#### state : string ["initial"]

Indicates the current state of the connection. Each state is also available as a boolean
property on this object (eg: connected). This is done as a convenience so you can trigger
functions on specific states (eg: onConnected).

#### error : signal(code, message)

This signal is emitted when an error occurs either internally or if one is returned from
Pusher.

#### ping() : function

Sends a ping request Pusher and resets the internal timeout timer as well as the inactivity timer.
Normally you should not need to call this function as it is called internally by the module.

#### disconnect() :  function

Disconnects from Pusher.


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

### Bind

This item represents a binding to a particular event type. A `Bind` must be decalred as a child
of a `Pusher` item or a `Channel` item.

#### event : string

The type of event to listen for. Omitting this property will create a binding for all events.
 
#### triggered : signal

This signal is emitted whenever a new event arrives.

## TODO

The following pieces of functionality are not yet implemented:

* Private Channels
* Presence Channels
* Channel CLient Events

