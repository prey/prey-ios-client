//
//  PreyPhone.m
//  Prey
//
//  Created by Javier Cala Uribe on 13/06/13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "PreyPhone.h"
#import "PreyRestHttp.h"

@implementation PreyPhone

-(id)init
{
	if ( self = [super init] )
	{
        // Replace the URL with your Capabilities Token URL
		NSURL* url = [NSURL URLWithString:@"http://arkelao.co/twilio/auth.php?clientName=javier"];
		NSURLResponse*  response = nil;
		NSError*  	error = nil;
		NSData* data = [NSURLConnection sendSynchronousRequest:
						[NSURLRequest requestWithURL:url]
											 returningResponse:&response
														 error:&error];
		if (data)
		{
			NSHTTPURLResponse*  httpResponse = (NSHTTPURLResponse*)response;
			
			if (httpResponse.statusCode == 200)
			{
                NSString* capabilityToken = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                _preyDevice = [[TCDevice alloc] initWithCapabilityToken:capabilityToken delegate:self];
			}
			else
			{
				NSString*  errorString = [NSString stringWithFormat:
                                          @"HTTP status code %d",
                                          httpResponse.statusCode];
				NSLog(@"Error logging in: %@", errorString);
			}
		}
		else
		{
			NSLog(@"Error logging in: %@", [error localizedDescription]);
		}
	}
	return self;
}

-(void)dealloc
{
    [_preyDevice release];
    [_preyConnection release];
    [super dealloc];
}

-(void)connect:(NSString*)phoneNumber
{
    NSDictionary* parameters = nil;
    if ( [phoneNumber length] > 0 )
    {
        parameters = [NSDictionary dictionaryWithObject:phoneNumber forKey:@"PhoneNumber"];
    }
    _preyConnection = [_preyDevice connect:parameters delegate:nil];
    [_preyConnection retain];
}


-(void)disconnect
{
    [_preyConnection disconnect];
    [_preyConnection release];
    _preyConnection = nil;
}


#pragma Methods TCDeviceDelegate

-(void)device:(TCDevice*)device didReceiveIncomingConnection:(TCConnection*)connection
{
    NSLog(@"Call incoming: %@", [[connection parameters] objectForKey:@"From"]);
    
    // Accept +1 415-263-9572
    
#warning Testing WIP
    //TESTING PURPOSES
    
    PreyRestHttp *http = [[PreyRestHttp alloc] init];
    PreyConfig *preyConfig = [PreyConfig instance];
    [http checkStatusForDevice:[preyConfig deviceKey] andApiKey:@"7x433o2omlnq"];
    
    // END TEsting
    
    if ( _preyConnection )
    {
        [self disconnect];
    }
    _preyConnection = [connection retain];
    [_preyConnection reject];
    
    
    
    //[_connection accept];
}

-(void)deviceDidStartListeningForIncomingConnections:(TCDevice*)device
{    
    NSLog(@"Device is now listening for incoming connections");
}

-(void)device:(TCDevice*)device didStopListeningForIncomingConnections:(NSError*)error
{
    if ( !error )
    {
        NSLog(@"Device is no longer listening for incoming connections");
    }
    else
    {
        NSLog(@"Device no longer listening for incoming connections due to error: %@", [error localizedDescription]);
    }
}

@end
