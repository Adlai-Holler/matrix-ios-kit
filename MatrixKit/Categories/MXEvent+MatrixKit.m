/*
 Copyright 2015 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXEvent+MatrixKit.h"
#import <objc/runtime.h>

@implementation MXEvent (MatrixKit)

- (MXKEventState)mxkState
{
    NSNumber *associatedState = objc_getAssociatedObject(self, @selector(state));
    if (associatedState)
    {
        return [associatedState unsignedIntegerValue];
    }
    return MXKEventStateDefault;
}

- (void)setMxkState:(MXKEventState)state
{
    objc_setAssociatedObject(self, @selector(state), [NSNumber numberWithUnsignedInteger:state], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isRedactedEvent
{
    return (self.redactedBecause != nil);
}

- (BOOL)isEmote
{
    if (self.eventType == MXEventTypeRoomMessage)
    {
        NSString *msgtype = self.content[@"msgtype"];
        if ([msgtype isEqualToString:kMXMessageTypeEmote])
        {
            return YES;
        }
    }
    return NO;
}


#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    
    // Make mxkState survive after a copy
    MXEvent *eventCopy = [super copyWithZone:zone];
    [eventCopy setMxkState:self.mxkState];
    
    return eventCopy;
}

@end
