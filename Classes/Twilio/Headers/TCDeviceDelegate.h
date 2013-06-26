//
//  Copyright 2011-2012 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the 
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//

@class TCDevice;
@class TCConnection;
@class TCPresenceEvent;

/** TCDeviceDelegate is the delegate protocol for a TCDevice.
 */
@protocol TCDeviceDelegate<NSObject>

@required

/** TCDevice is no longer listening for incoming connections.
 
 @param device The TCDevice object that stopped listening.
 
 @param error An NSError indicating the reason the TCDevice went offline. If the error is nil, this means that the incoming listener was successfully disconnected (for example, -[TCDevice unlisten] was called).  For a list of error codes associated with a non-nil error and their meanings, see <a href="http://www.twilio.com/docs/client/errors" target="_blank">http://www.twilio.com/docs/client/errors</a>.
 
 @returns None
 */
-(void)device:(TCDevice*)device didStopListeningForIncomingConnections:(NSError*)error;


@optional

/** TCDevice is now listening for incoming connections.
 
 @param device The TCDevice object that is now listening for connections.

 @returns None
 */
-(void)deviceDidStartListeningForIncomingConnections:(TCDevice*)device;


/** Called when an incoming connection request has been received.  At this point you choose to accept, ignore, or reject the new connection.
 
 When this occurs, you should assign an appropriate TCConnectionDelegate on the TCConnection to properly respond to events.
 
 Pending incoming connections may be received at any time, including while another connection is active.  This method will be invoked once for each connection, and your code should handle this situation appropriately. A single pending connection can be accepted as long as no other connections are active; all other currently pending incoming connections will be automatically rejected by the library until the active connection is terminated.
 
 @param device The TCDevice that is receiving the incoming connection request.
 
 @param connection The TCConnection associated with the incoming connection. The incoming connection will be in the TCConnectionStatusPending state until it is either accepted or disconnected.
 
 @returns None
 */
-(void)device:(TCDevice*)device didReceiveIncomingConnection:(TCConnection*)connection;


/** Called when a presence update notification has been received.
 
 When the device is ready, this selector (if implemented) is invoked once for each available client. Thereafter it is invoked as clients become available or unavailable.
 
 A client is considered available even if another call is in progress.
 
 Remember, when your client disconnects the [TCDeviceDelegate device:didStopListeningForIncomingConnections:] selector will be invoked, and when the device reconnects this presence selector will be called again for every available online client.
  
 @param device The TCDevice that is receiving the presence update.
 
 @param presenceEvent A TCPresenceEvent object describing the notification.
 
 @returns None
 */
-(void)device:(TCDevice *)device didReceivePresenceUpdate:(TCPresenceEvent *)presenceEvent;

@end
