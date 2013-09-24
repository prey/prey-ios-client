//
//  PictureModule.m
//  Prey-iOS
//
//  Created by Carlos Yaconi on 24/03/2011.
//  Copyright 2011 Fork Ltd. All rights reserved.
//  License: GPLv3
//  Full license at "/LICENSE"
//

#import "PictureModule.h"
#import "PicturesController.h"


@implementation PictureModule


-(void) get {
    [[PicturesController instance]takePictureAndNotifyTo:@selector(pictureReady:) onTarget:self];
}

- (void) pictureReady:(UIImage *) picture {
    //UIImageWriteToSavedPhotosAlbum(picture, nil, nil, nil);
    [super createResponseFromData:UIImagePNGRepresentation(picture) withKey:[self getName]];
}

- (NSString *) getName {
	return @"picture";
}


- (void)dealloc {
	[super dealloc];
}

@end
