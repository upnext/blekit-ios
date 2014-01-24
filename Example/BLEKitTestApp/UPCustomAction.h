//
//  UPCustomAction.h
//  BLEKitTestApp
//
//  Created by Marcin Krzyzanowski on 22/01/14.
//  Copyright (c) 2014 Upnext. All rights reserved.
//

#import "BLEAction.h"

static NSString * const UPCustomActionType = @"custom-alert";

@interface UPCustomAction : BLEAction <BLEAction>

@end
