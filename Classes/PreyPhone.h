//
//  PreyPhone.h
//  Prey
//
//  Created by Javier Cala Uribe on 13/06/13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCDevice.h"
#import "TCConnection.h"
#import "TCDeviceDelegate.h"

@interface PreyPhone : NSObject <TCDeviceDelegate>
{
@private
    TCDevice*       _preyDevice;
    TCConnection*   _preyConnection;
}

- (void)connect:(NSString*)phoneNumber;
- (void)disconnect;

- (void)deviceDidStartListeningForIncomingConnections:(TCDevice*)device;
- (void)device:(TCDevice*)device didStopListeningForIncomingConnections:(NSError*)error;
- (void)device:(TCDevice*)device didReceiveIncomingConnection:(TCConnection*)connection;

@end