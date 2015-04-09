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

#define MXK_ROOM_BUBBLE_CELL_DATA_MAX_ATTACHMENTVIEW_WIDTH 192

#define MXK_ROOM_BUBBLE_CELL_DATA_DEFAULT_MAX_TEXTVIEW_WIDTH 200
#define MXK_ROOM_BUBBLE_CELL_DATA_TEXTVIEW_MARGIN 5

#import "MXKRoomBubbleCellData.h"

#import "MXKTools.h"
#import "MXKMediaManager.h"

@interface MXKRoomBubbleCellData () {

    MXKRoomDataSource *roomDataSource;
}
@end

@implementation MXKRoomBubbleCellData
@synthesize senderId, roomId, senderDisplayName, senderAvatarUrl, isSameSenderAsPreviousBubble, date, isIncoming, isAttachment;
@synthesize attributedTextMessage, startsWithSenderName, isTyping;

#pragma mark - MXKRoomBubbleCellDataStoring

- (instancetype)initWithEvent:(MXEvent *)event andRoomState:(MXRoomState *)roomState andRoomDataSource:(MXKRoomDataSource *)roomDataSource2 {
    self = [self init];
    if (self) {
        roomDataSource = roomDataSource2;

        // Create the bubble component based on matrix event
        MXKRoomBubbleComponent *firstComponent = [[MXKRoomBubbleComponent alloc] initWithEvent:event andRoomState:roomState andEventFormatter:roomDataSource.eventFormatter];
        if (firstComponent) {
            bubbleComponents = [NSMutableArray array];
            [bubbleComponents addObject:firstComponent];
            
            senderId = event.userId;
            roomId = event.roomId;
            senderDisplayName = [roomDataSource.eventFormatter senderDisplayNameForEvent:event withRoomState:roomState];
            senderAvatarUrl = [roomDataSource.eventFormatter senderAvatarUrlForEvent:event withRoomState:roomState];
            isIncoming = ([event.userId isEqualToString:roomDataSource.mxSession.myUser.userId] == NO);
            
            // Set message type (consider text by default), and check attachment if any
            _dataType = MXKRoomBubbleCellDataTypeText;
            if ([roomDataSource.eventFormatter isSupportedAttachment:event]) {
                // Note: event.eventType is equal here to MXEventTypeRoomMessage
                
                // Set default thumbnail orientation
                _thumbnailOrientation = UIImageOrientationUp;
                
                NSString *msgtype =  event.content[@"msgtype"];
                if ([msgtype isEqualToString:kMXMessageTypeImage]) {
                    [self handleImageMessage:event];
                } else if ([msgtype isEqualToString:kMXMessageTypeAudio]) {
                    // Not supported yet
                    //_dataType = MXKRoomBubbleCellDataTypeAudio;
                } else if ([msgtype isEqualToString:kMXMessageTypeVideo]) {
                    _dataType = MXKRoomBubbleCellDataTypeVideo;
                    // Retrieve content url/info
                    NSString *contentURL = event.content[@"url"];
                    // Check provided url (it may be a matrix content uri, we use SDK to build absoluteURL)
                    _attachmentURL = [roomDataSource.mxSession.matrixRestClient urlOfContent:contentURL];
                    if (nil == _attachmentURL) {
                        // It was not a matrix content uri, we keep the provided url
                        _attachmentURL = contentURL;
                    }
                    _attachmentCacheFilePath = [MXKMediaManager cachePathForMediaWithURL:_attachmentURL inFolder:event.roomId];
                    _attachmentInfo = event.content[@"info"];
                    if (_attachmentInfo) {
                        // Get video thumbnail info
                        _thumbnailURL = _attachmentInfo[@"thumbnail_url"];
                        _thumbnailInfo = _attachmentInfo[@"thumbnail_info"];
                    }
                } else if ([msgtype isEqualToString:kMXMessageTypeLocation]) {
                    // Not supported yet
                    // _dataType = MXKRoomBubbleCellDataTypeLocation;
                }
            }
            
            // Report the attributed string (This will initialize _contentSize attribute)
            self.attributedTextMessage = firstComponent.attributedTextMessage;
            
            // Initialize rendering attributes
            _maxTextViewWidth = MXK_ROOM_BUBBLE_CELL_DATA_DEFAULT_MAX_TEXTVIEW_WIDTH;
        } else {
            // Ignore this event
            self = nil;
        }
    }
    return self;
}

- (void)dealloc {
    bubbleComponents = nil;
}

- (NSUInteger)updateEvent:(NSString *)eventId withEvent:(MXEvent *)event {

    // Retrieve the component storing the event and update it
    for (NSUInteger index = 0; index < bubbleComponents.count; index++) {
        MXKRoomBubbleComponent *roomBubbleComponent = [bubbleComponents objectAtIndex:index];
        if ([roomBubbleComponent.event.eventId isEqualToString:eventId]) {
            [roomBubbleComponent updateWithEvent:event];
            if (!roomBubbleComponent.textMessage.length) {
                [bubbleComponents removeObjectAtIndex:index];
            }
            // flush the current attributed string to force refresh
            self.attributedTextMessage = nil;
            break;
        }
    }

    // The case of update of image event happens when an image echo is replaced by its true event
    // received back by the events stream
    if (MXKRoomBubbleCellDataTypeImage == _dataType) {

        NSString *msgtype =  event.content[@"msgtype"];
        if ([msgtype isEqualToString:kMXMessageTypeImage]) {

            if (NO == [_attachmentURL isEqualToString:event.content[@"url"]]) {

                // Store the echo image as preview to prevent the cell from flashing
                _previewURL = _attachmentURL;

                // Update the data with new image event
                [self handleImageMessage:event];
            }
        }
        else {
            NSLog(@"[MXKRoomBubbleCellData] updateEvent: Warning: Does not support change of event type");
        }
    }

    return bubbleComponents.count;
}

- (NSUInteger)removeEvent:(NSString *)eventId {
    
    for (MXKRoomBubbleComponent *roomBubbleComponent in bubbleComponents) {
        
        if ([roomBubbleComponent.event.eventId isEqualToString:eventId]) {
            
            [bubbleComponents removeObject:roomBubbleComponent];
            break;
        }
    }
    return bubbleComponents.count;
}

- (BOOL)hasSameSenderAsBubbleCellData:(id<MXKRoomBubbleCellDataStoring>)bubbleCellData {
    
    // Sanity check: accept only object of MXKRoomBubbleCellData classes or sub-classes
    NSParameterAssert([bubbleCellData isKindOfClass:[MXKRoomBubbleCellData class]]);
    
    // NOTE: Same sender means here same id, same display name and same avatar
    
    // Check first user id
    if ([senderId isEqualToString:bubbleCellData.senderId] == NO) {
        return NO;
    }
    // Check sender name
    if ((senderDisplayName.length || bubbleCellData.senderDisplayName.length) && ([senderDisplayName isEqualToString:bubbleCellData.senderDisplayName] == NO)) {
        return NO;
    }
    // Check avatar url
    if ((senderAvatarUrl.length || bubbleCellData.senderAvatarUrl.length) && ([senderAvatarUrl isEqualToString:bubbleCellData.senderAvatarUrl] == NO)) {
        return NO;
    }
    
    return YES;
}

#pragma mark -

- (void)prepareBubbleComponentsPosition {
    // Consider here only the first component if any
    if (bubbleComponents.count) {
        MXKRoomBubbleComponent *firstComponent = [bubbleComponents firstObject];
        CGFloat positionY = (_dataType == MXKRoomBubbleCellDataTypeText) ? MXK_ROOM_BUBBLE_CELL_DATA_TEXTVIEW_MARGIN : -MXK_ROOM_BUBBLE_CELL_DATA_TEXTVIEW_MARGIN;
        firstComponent.position = CGPointMake(0, positionY);
    }
}

#pragma mark - Text measuring

// Return the raw height of the provided text by removing any margin
- (CGFloat)rawTextHeight: (NSAttributedString*)attributedText {
    __block CGSize textSize;
    if ([NSThread currentThread] != [NSThread mainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            textSize = [self textContentSize:attributedText];
        });
    } else {
        textSize = [self textContentSize:attributedText];
    }
    
    if (textSize.height) {
        // Return the actual height of the text by removing textview margin from content height
        return (textSize.height - (2 * MXK_ROOM_BUBBLE_CELL_DATA_TEXTVIEW_MARGIN));
    }
    return 0;
}

// Return the content size of a text view initialized with the provided attributed text
// CAUTION: This method runs only on main thread
- (CGSize)textContentSize: (NSAttributedString*)attributedText {
    if (attributedText.length) {
        // Use a TextView template
        UITextView *dummyTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, _maxTextViewWidth, MAXFLOAT)];
        dummyTextView.attributedText = attributedText;
        return [dummyTextView sizeThatFits:dummyTextView.frame.size];
    }
    return CGSizeZero;
}

#pragma mark - Privates

- (void)handleImageMessage:(MXEvent*)event {
    _dataType = MXKRoomBubbleCellDataTypeImage;
    // Retrieve content url/info
    NSString *contentURL = event.content[@"url"];
    // Check provided url (it may be a matrix content uri, we use SDK to build absoluteURL)
    _attachmentURL = [roomDataSource.mxSession.matrixRestClient urlOfContent:contentURL];
    if (nil == _attachmentURL) {
        // It was not a matrix content uri, we keep the provided url
        _attachmentURL = contentURL;
    }
    _attachmentCacheFilePath = [MXKMediaManager cachePathForMediaWithURL:_attachmentURL inFolder:event.roomId];
    _attachmentInfo = event.content[@"info"];
    // Handle legacy thumbnail url/info (Not defined anymore in recent attachments)
    _thumbnailURL = event.content[@"thumbnail_url"];
    _thumbnailInfo = event.content[@"thumbnail_info"];
    if (!_thumbnailURL) {
        // Suppose contentURL is a matrix content uri, we use SDK to get the well adapted thumbnail from server
        _thumbnailURL = [roomDataSource.eventFormatter thumbnailURLForContent:contentURL inViewSize:self.contentSize withMethod:MXThumbnailingMethodScale];
        
        // Check whether the image has been uploaded with an orientation
        if (_attachmentInfo[@"rotation"]) {
            // Currently the matrix content server provides thumbnails by ignoring the original image orientation.
            // We store here the actual orientation to apply it on downloaded thumbnail.
            _thumbnailOrientation = [MXKTools imageOrientationForRotationAngleInDegree:[_attachmentInfo[@"rotation"] integerValue]];
            
            // Rotate the current content size (if need)
            if (_thumbnailOrientation == UIImageOrientationLeft || _thumbnailOrientation == UIImageOrientationRight) {
                _contentSize = CGSizeMake(_contentSize.height, _contentSize.width);
            }
        }
    }
}

#pragma mark - Properties

- (NSArray*)bubbleComponents {
    return [bubbleComponents copy];
}

- (void)setAttributedTextMessage:(NSAttributedString *)inAttributedTextMessage {
    attributedTextMessage = inAttributedTextMessage;
    
    // Reset content size
    _contentSize = CGSizeZero;
}

- (NSAttributedString*)attributedTextMessage {
    if (!attributedTextMessage.length && bubbleComponents.count) {
        // By default only one component is supported, consider here the first component
        MXKRoomBubbleComponent *firstComponent = [bubbleComponents firstObject];
        attributedTextMessage = firstComponent.attributedTextMessage;
    }
    
    return attributedTextMessage;
}

- (BOOL)startsWithSenderName {
    if (bubbleComponents.count) {
        // Consider the first component
        MXKRoomBubbleComponent *firstComponent = [bubbleComponents firstObject];
        return (firstComponent.event.isEmote || [firstComponent.textMessage hasPrefix:senderDisplayName]);
    }
    return NO;
}

- (NSArray*)events {
    NSMutableArray* eventsArray = [NSMutableArray arrayWithCapacity:bubbleComponents.count];
    for (MXKRoomBubbleComponent *roomBubbleComponent in bubbleComponents) {
        if (roomBubbleComponent.event) {
            [eventsArray addObject:roomBubbleComponent.event];
        }
    }
    return eventsArray;
}

- (NSDate*)date {
    // Consider the first component data as the bubble date
    if (bubbleComponents.count) {
        MXKRoomBubbleComponent *firstComponent = [bubbleComponents firstObject];
        return firstComponent.date;
    }
    return nil;
}

- (BOOL)isAttachment {
    return (_dataType != MXKRoomBubbleCellDataTypeText);
}

- (void)setMaxTextViewWidth:(CGFloat)inMaxTextViewWidth {
    if (_dataType == MXKRoomBubbleCellDataTypeText) {
        // Check change
        if (inMaxTextViewWidth != _maxTextViewWidth) {
            _maxTextViewWidth = inMaxTextViewWidth;
            // Reset content size
            _contentSize = CGSizeZero;
        }
    }
}

- (CGSize)contentSize {
    if (CGSizeEqualToSize(_contentSize, CGSizeZero)) {
        if (_dataType == MXKRoomBubbleCellDataTypeText) {
            if ([NSThread currentThread] != [NSThread mainThread]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    _contentSize = [self textContentSize:self.attributedTextMessage];
                });
            } else {
                _contentSize = [self textContentSize:self.attributedTextMessage];
            }
        } else if (_dataType == MXKRoomBubbleCellDataTypeImage || _dataType == MXKRoomBubbleCellDataTypeVideo) {
            CGFloat width, height;
            width = height = 40;
            if (_thumbnailInfo || _attachmentInfo) {
                if (_thumbnailInfo && _thumbnailInfo[@"w"] && _thumbnailInfo[@"h"]) {
                    width = [_thumbnailInfo[@"w"] integerValue];
                    height = [_thumbnailInfo[@"h"] integerValue];
                } else if (_attachmentInfo[@"w"] && _attachmentInfo[@"h"]) {
                    width = [_attachmentInfo[@"w"] integerValue];
                    height = [_attachmentInfo[@"h"] integerValue];
                }
                
                if (width > MXK_ROOM_BUBBLE_CELL_DATA_MAX_ATTACHMENTVIEW_WIDTH || height > MXK_ROOM_BUBBLE_CELL_DATA_MAX_ATTACHMENTVIEW_WIDTH) {
                    if (width > height) {
                        height = (height * MXK_ROOM_BUBBLE_CELL_DATA_MAX_ATTACHMENTVIEW_WIDTH) / width;
                        height = floorf(height / 2) * 2;
                        width = MXK_ROOM_BUBBLE_CELL_DATA_MAX_ATTACHMENTVIEW_WIDTH;
                    } else {
                        width = (width * MXK_ROOM_BUBBLE_CELL_DATA_MAX_ATTACHMENTVIEW_WIDTH) / height;
                        width = floorf(width / 2) * 2;
                        height = MXK_ROOM_BUBBLE_CELL_DATA_MAX_ATTACHMENTVIEW_WIDTH;
                    }
                }
            }
            
            // Check here thumbnail orientation
            if (_thumbnailOrientation == UIImageOrientationLeft || _thumbnailOrientation == UIImageOrientationRight) {
                _contentSize = CGSizeMake(height, width);
            } else {
                _contentSize = CGSizeMake(width, height);
            }
        } else {
            _contentSize = CGSizeMake(40, 40);
        }
    }
    return _contentSize;
}

- (MXKEventFormatter *)eventFormatter {
    // Retrieve event formatter from the first component
    if (bubbleComponents.count) {
        MXKRoomBubbleComponent *firstComponent = [bubbleComponents firstObject];
        return firstComponent.eventFormatter;
    }
    return nil;
}

@end
