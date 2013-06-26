//
//  Copyright 2012 Twilio. All rights reserved.
//
//  Use of this software is subject to the terms and conditions of the 
//  Twilio Terms of Service located at http://www.twilio.com/legal/tos
//

#import <Foundation/Foundation.h>

/** An object encapsulating client presence state for other clients connected to the Twilio Application.

 See [TCDeviceDelegate device:didReceivePresenceUpdate:] for more information.
 */
@interface TCPresenceEvent : NSObject

/** The client name for which the event applies.
 */
@property (nonatomic, readonly) NSString *name;

/** Whether or not the client specified by name is currently connected to Twilio services for the account.
 */
@property (nonatomic, readonly, getter=isAvailable) BOOL available;

@end
