//
//  Copyright 2011-2012 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the 
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//

#import <Foundation/Foundation.h>

#import "TCDeviceDelegate.h"
#import "TCConnectionDelegate.h"

/** TCDeviceState represents the various states of the device's ability to listen for incoming connections and make outgoing connections. 

 The TCDeviceDelegate gets notified of the state changes.
 */
typedef enum
{
	TCDeviceStateOffline = 0,		/**< TCDevice The device is not connected and cannot receive incoming connections or make outgoing connections. */
	TCDeviceStateReady,				/**< TCDevice can receive incoming connections and attempt outgoing connections if capabilities allow. */
	TCDeviceStateBusy				/**< TCDevice is connected to the network and has an active connection.  No additional connections can be created or accepted. */
} TCDeviceState;

/** @name Device capability keys */

/*
 * These keys can retrieve values from the TCDevice.capabilities dictionary.
 * The values are extracted from the Capability Token that is used to initialize a TCDevice.
 */
extern NSString* const TCDeviceCapabilityIncomingKey; /**< NSNumber of BOOL that indicates whether the device can receive incoming calls. */
extern NSString* const TCDeviceCapabilityOutgoingKey; /**< NSNumber of BOOL that indicates whether the device can make outgoing calls. */
extern NSString* const TCDeviceCapabilityExpirationKey; /**< NSNumber of long long that represents the time the device's capability token expires (number of seconds relative to the UNIX epoch). */
extern NSString* const TCDeviceCapabilityAccountSIDKey; /**< NSString representing the account SID. */
extern NSString* const TCDeviceCapabilityApplicationSIDKey; /**< The application SID used when making an outgoing call.  Only present if TCDeviceCapabilityOutgoingKey is also present with a YES value. */
extern NSString* const TCDeviceCapabilityApplicationParametersKey; /**< A non-modifiable NSDictionary of key/value pairs that will be passed to the Twilio Application when making an outgoing call.  Only present if TCDeviceCapabilityOutgoingKey is also present with a YES value and the Capability Token contains application parameters.  Additional parameters may be specified in the connect:delegate: method if needed. */
extern NSString* const TCDeviceCapabilityClientNameKey; /**< NSString representing the client name. */


@class TCConnection;

/** An instance of TCDevice is an object that knows how to interface with Twilio Services.
 
 A TCDevice is the primary entry point for Twilio Client.  An iOS application should initialize a TCDevice with the initWithCapabilityToken:delegate: method with a Capability Token to talk to Twilio services.
 
 A Capability Token is a JSON Web Token (JWT) that specifies what the TCDevice may do with respect to the Twilio Application, such as whether it can make outgoing calls, how long the token and the TCDevice are valid before needing to be refreshed, and so on.  Please visit http://www.twilio.com/docs/client/capability-tokens for more information.

 @see TCDeviceDelegate
 */
@interface TCDevice : NSObject 

/** Current status of the TCDevice.
 
 State changes will cause relevant methods to be called in TCDeviceDelegate and will include any NSErrors that occur.
 */
@property (nonatomic, readonly) TCDeviceState state;


/** Current capabilities of the TCDevice.  The keys are defined by the "Device capability keys" constants.
  */
@property (nonatomic, readonly) NSDictionary* capabilities;


/** The delegate object which will receive events from a TCDevice object.
 */
@property (nonatomic, assign) id<TCDeviceDelegate> delegate;

/** A BOOL indicating if a sound should be played for an incoming connection.
 
 The default value is YES.  See the Twilio Client iOS Usage Guide for more information on sounds.
 */
@property (nonatomic) BOOL incomingSoundEnabled;

/** A BOOL indicating if a sound should be played for an outgoing connection.
 
 The default value is YES.  See the Twilio Client iOS Usage Guide for more information on sounds.
 */
@property (nonatomic) BOOL outgoingSoundEnabled;

/** A BOOL indicating if a sound should be played when a connection is disconnected for any reason.
 
 The default value is YES.  See the Twilio Client iOS Usage Guide for more information on sounds.
 */
@property (nonatomic) BOOL disconnectSoundEnabled;


/** Initialize a new TCDevice object. If the incoming capabilities are defined, then the device will automatically begin listening for incoming connections.
 
 @param capabilityToken A signed JSON Web Token that defines the features available to the TCDevice.  These may be created using the Twilio Helper Libraries included with the SDK or available at http://www.twilio.com .  The capabilities are used to begin listening for incoming connections and provide the default parameters used for establishing outgoing connections.  Please visit http://www.twilio.com/docs/client/capability-tokens for more information.
 
 @param delegate The delegate object which will receive events from a TCDevice object.
 
 @returns The initialized receiver
 
 @see updateCapabilityToken:
 */
-(id)initWithCapabilityToken:(NSString*)capabilityToken delegate:(id<TCDeviceDelegate>)delegate;


/** Start TCDevice to listen for incoming connections.
 
 The TCDevice will automatically listen for incoming connections on method calls to initWithCapabilityToken:delegate: or updateCapabilityToken: if the token allows.
 
 This method only needs to be called if unlisten was previously called.

 @returns None
 */
-(void)listen;


/** Stop the device from listening for incoming connections.  This could be used for a "silence" mode on the your iOS application, for instance. 
 
 This method will do nothing if the TCDevice is currently not listening, either because of a previous call to unlisten or because the TCDevice has not been granted the incoming capability.
 
 @returns None
 */
-(void)unlisten;


/** Update the capabilities of the TCDevice. 
 
 There may be circumstances when the defined capabilities have expired. For example, the TCDevice may enter the TCDeviceStateOffline state because the capabilities have expired. In these cases, the capabilities will need to be updated.  If the device is currently listening for incoming connections, it will restart the listening process (if permitted) using these updated capabilities.
 
 Existing connections are not affected by updating the capability token.

 @param capabilityToken A signed JWT that defines the capability token available to the TCDevice.  Please visit http://www.twilio.com/docs/client/capability-tokens for more information on capability tokens.
 
 @return None
 */
-(void)updateCapabilityToken:(NSString*)capabilityToken;


/** Create an outgoing connection. 
	
 @param parameters An optional dictionary containing parameters for the outgoing connection that get passed to your Twilio Application.  These parameters are merged with any parameters supplied in the Capability Token (e.g. the dictionary retrived with the TCDeviceCapabilityApplicationParametersKey against the capabilities property).  If there are any key collisions with the two dictionaries, the value(s) from TCDeviceCapabilityApplicationParametersKey dictionary will take precedence.
  
 @param delegate An optional delegate object to receive callbacks when state changes occur to the TCConnection object.

 @returns A TCConnection object representing the new outgoing connection. If TCConnection is nil, the connection could not be initialized.
 */
-(TCConnection*)connect:(NSDictionary*)parameters delegate:(id<TCConnectionDelegate>)delegate;


/** Disconnect all current connections associated with the receiver.
 
 This a convenience routine that disconnects all current incoming and outgoing connections, including pending incoming connections.
 
 @returns None
 */
-(void)disconnectAll;

@end
