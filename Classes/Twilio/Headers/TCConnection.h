//
//  Copyright 2011-2012 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the 
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//

#import <Foundation/Foundation.h>

#import "TCConnectionDelegate.h"

/** TCConnectionState is an enum representing the current status of TCConnection.
 */
typedef enum
{
	TCConnectionStatePending = 0,	/**< An incoming TCConnection has not yet been accepted. */
	TCConnectionStateConnecting,	/**< An incoming TCConnection has been accepted, or an outgoing TCConnection is being established. */
	TCConnectionStateConnected,		/**< A connection has been established. */
	TCConnectionStateDisconnected	/**< An open connection has been disconnected. */
} TCConnectionState;


/** @name Incoming connection parameter capability keys */

/*
 * These keys can retrieve values from the TCConnection.parameters dictionary for incoming connections.
 * These are a subset of the values provided as a part of a Twilio Request to your Twilio application.
 * Please visit http://www.twilio.com/docs/api/twiml/twilio_request for details on the specifics of the parameters.
 */
extern NSString* const TCConnectionIncomingParameterFromKey; /**< NSString representing the calling party.  If the caller is a telephone, it will be in the E.164 format.  If the caller is another Twilio Client, it will be in a URI format "client:name" */
extern NSString* const TCConnectionIncomingParameterToKey; /**< NSString representing the client name of the called party.  This is in a URI format "client:name" */
extern NSString* const TCConnectionIncomingParameterAccountSIDKey; /**< NSString representing the account id making the incoming call */
extern NSString* const TCConnectionIncomingParameterAPIVersionKey; /**< NSString representing the version of the Twilio API used in the server application */
extern NSString* const TCConnectionIncomingParameterCallSIDKey; /**< NSString representing a unique identifier for the incoming call */

// Outgoing parameters are completely up to application developers and thus there are no constants for them here.


/** A TCConnection object represents the connection between a TCDevice and Twilio's services.

 A TCConnection is either incoming or outgoing.  You do not create a TCConnection directly; an outgoing connection is created by calling the -[TCDevice connect:delegate:] method.  Incoming connections are created internally by TCDevice and handed to the registered TCDeviceDelegate via -[TCDeviceDelegate device:didReceiveIncomingConnection:].
 */
@interface TCConnection : NSObject 

/** Current status of the TCConnection.
 */
@property (nonatomic, readonly) TCConnectionState state;

/** BOOL representing if the TCConnection is an incoming or outgoing connection.
 
 If the connection is incoming, the value is YES.
 */
@property (nonatomic, readonly, getter=isIncoming) BOOL incoming;

/** A dictionary of parameters that define the connection.
 
 Incoming connection parameters are defined by the "Incoming connection parameter capability keys".
 Outgoing connection parameters are defined by the union of optional application parameters specified in the Capability Token and any additional parameters specified when the -[TCDevice connect:delegate:] method is called.
 */
@property (nonatomic, readonly) NSDictionary* parameters;

/** The delegate object which will receive TCConnection events.
 */
@property (nonatomic, assign) id<TCConnectionDelegate> delegate;

/** Property that defines if the connection's microphone is muted.

 Setting the property will only take effect if the connection's state is TCConnectionStateConnected.
 */
@property (nonatomic, getter=isMuted) BOOL muted;

/** Accepts an incoming connection request. 
 
 When the TCDeviceDelegate receives a -[TCDeviceDelegate device:didReceiveIncomingConnection:] message, calling this method will accept the incoming connection. Calling this method on a TCConnection that is not in the TCConnectionStatePending state will have no effect.
 
 @returns None
 */
-(void)accept;

/** Ignores an incoming connection request.
 
 When the TCDeviceDelegate receives a -[TCDeviceDelegate device:didReceiveIncomingConnection:] message, calling ignore will close the incoming connection request and the connection may not be accepted. Calling this method on a TCConnection that is not in the TCConnectionStatePending state will have no effect.
 The TCConnectionDelegate will eventually receive a -[TCConnectionDelegate connectionDidDisconnect:] message once the connection is terminated.
 
 @returns None
 */
-(void)ignore;

/** Rejects an incoming connection request.
 
 When the TCDeviceDelegate receives a -[TCDeviceDelegate device:didReceiveIncomingConnection:] message, calling reject will terminate the request, notifying the caller that the call was rejected. Calling this method on a TCConnection that is not in the TCConnectionStatePending state will have no effect.
 The TCConnectionDelegate will eventually receive a -[TCConnectionDelegate connectionDidDisconnect:] message once the connection is terminated.

 @returns None
 */
-(void)reject;

/** Disconnect the connection. 
 
 Calling this method on a TCConnection that is in the TCConnectionStateDisconnected state will have no effect.
 The TCConnectionDelegate will eventually receive a -[TCConnectionDelegate connectionDidDisconnect:] message once the connection is terminated.

 @returns None
 */
-(void)disconnect;

/** Send a string of digits over the connection. Calling this method on a TCConnection that is not in the TCConnectionStateConnected state will have no effect.
 
 @param digits A string of characters to be played.  Valid values are '0' - '9', '*', '#', and 'w'.  Each 'w' will cause a 500 ms pause between digits sent.  If any invalid character is present, no digits will be sent.
  
 @returns None
 */
-(void)sendDigits:(NSString*)digits;

@end
