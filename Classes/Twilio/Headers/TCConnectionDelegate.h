//
//  Copyright 2011-2012 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the 
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//

#import <Foundation/Foundation.h>

@class TCConnection;

/** TCConnectionDelegate is the delegate protocol for receiving TCConnection state-change notifications.
 */
@protocol TCConnectionDelegate<NSObject>

@required

/** The TCConnection has failed with an error. 
 
 After this selector has been called, it is safe to assume that the connection is no longer connected.  When this occurs the TCConnection will be in the TCConnectionStateDisconnected state.
 
 For a list of error codes and their meanings, see <a href="http://www.twilio.com/docs/client/errors" target="_blank">http://www.twilio.com/docs/client/errors</a>.

 @param connection The TCConnection that encountered an error
 
 @param error The NSError for the error encountered by TCConnection
 
 @returns None
 */
-(void)connection:(TCConnection*)connection didFailWithError:(NSError*)error;


@optional


/** The TCConnection is in the process of trying to connect.

 When this occurs, TCConnection is in the TCConnectionStateConnecting state.
 
 @param connection The TCConnection that is in the process of trying to connect.

 @returns None
 */
-(void)connectionDidStartConnecting:(TCConnection*)connection;

/** The TCConnection has successfully connected. 
 
 When this occurs, TCConnection is in the TCConnectionStateConnected state.
 
 @param connection The TCConnection that has just connected.
 
 @returns None
 */
-(void)connectionDidConnect:(TCConnection*)connection;

/** The TCConnection has just disconnected. 
 
 This will occur when the connection has been disconnected or ignored by any party. When this occurs the TCConnection will be in the TCConnectionStateDisconnected state.
  
 @param connection The TCConnection has just disconnected.
 
 @returns None
 */
-(void)connectionDidDisconnect:(TCConnection*)connection;

@end
