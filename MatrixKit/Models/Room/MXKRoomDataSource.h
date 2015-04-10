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

#import <UIKit/UIKit.h>

#import "MXKDataSource.h"
#import "MXKRoomBubbleCellDataStoring.h"
#import "MXKEventFormatter.h"


#pragma mark - Cells identifiers
/**
 String identifying the object used to store and prepare room bubble data.
 */
extern NSString *const kMXKRoomBubbleCellDataIdentifier;

/**
 String identifying the cell object to be reused to display incoming room events as text messages.
 */
extern NSString *const kMXKRoomIncomingTextMsgBubbleTableViewCellIdentifier;

/**
 String identifying the cell object to be reused to display incoming attachments.
 */
extern NSString *const kMXKRoomIncomingAttachmentBubbleTableViewCellIdentifier;

/**
 String identifying the cell object to be reused to display outgoing room events as text messages.
 */
extern NSString *const kMXKRoomOutgoingTextMsgBubbleTableViewCellIdentifier;

/**
 String identifying the cell object to be reused to display outgoing attachments.
 */
extern NSString *const kMXKRoomOutgoingAttachmentBubbleTableViewCellIdentifier;


#pragma mark - Notifications
/**
 Notification sent when an information about the room has changed.
 Tracked informations are: lastMessage, unreadCount
 */
extern NSString *const kMXKRoomDataSourceMetaDataChanged;


#pragma mark - MXKRoomDataSource
@protocol MXKRoomBubbleCellDataStoring;

/**
 The data source for `MXKRoomViewController`.
 */
@interface MXKRoomDataSource : MXKDataSource <UITableViewDataSource> {

@protected

    /**
     The data for the cells served by `MXKRoomDataSource`.
     */
    NSMutableArray *bubbles;

    /**
     The queue to process room messages.
     This processing can consume time. Handling it on a separated thread avoids to block the main thread.
     */
    dispatch_queue_t processingQueue;

    /**
     The queue of events that need to be processed in order to compute their display.
     */
    NSMutableArray *eventsToProcess;
}

/**
 The id of the room managed by the data source.

 */
@property (nonatomic, readonly) NSString *roomId;

/**
 The room the data comes from.
 The object is defined when the MXSession has data for the room
 */
@property (nonatomic, readonly) MXRoom *room;

/**
 The last event in the room that matches the `eventsFilterForMessages` property.
 */
@property (nonatomic, readonly) MXEvent *lastMessage;

/**
 The number of unread messages.
 It is automatically reset to 0 when the view controller calls numberOfRowsInSection.
 */
@property (nonatomic, readonly) NSUInteger unreadCount;


#pragma mark - Configuration
/**
 The type of events to display as messages.
 */
@property (nonatomic) NSArray *eventsFilterForMessages;

/**
 The events to display texts formatter.
 `MXKRoomBubbleCellDataStoring` instances can use it to format text.
 */
@property (nonatomic) MXKEventFormatter *eventFormatter;



#pragma mark - Life cycle
/**
 Initialise the data source to serve data corresponding to the passed room.
 
 @param roomId the id of the room to get data from.
 @param mxSession the Matrix session to get data from.
 @return the newly created instance.
 */
- (instancetype)initWithRoomId:(NSString*)roomId andMatrixSession:(MXSession*)mxSession;


#pragma mark - Public methods
/**
 Get the data for the cell at the given index.

 @param index the index of the cell in the array
 @return the cell data
 */
- (id<MXKRoomBubbleCellDataStoring>)cellDataAtIndex:(NSInteger)index;

/**
 Get the data for the cell at the given index.

 @param index the index of the cell in the array
 @return the cell data
 */
- (id<MXKRoomBubbleCellDataStoring>)cellDataOfEventWithEventId:(NSString*)eventId;


#pragma mark - Pagination
/**
 Load more messages from the history.
 This method fails (with nil error) if the data source is not ready (see `MXKDataSourceStateReady`).
 
 @param numItems the number of items to get.
 @param success a block called when the operation succeeds.
 @param failure a block called when the operation fails.
 */
- (void)paginateBackMessages:(NSUInteger)numItems success:(void (^)())success failure:(void (^)(NSError *error))failure;

/**
 Load enough messages to fill the rect.
 This method fails (with nil error) if the data source is not ready (see `MXKDataSourceStateReady`).
 
 @param the rect to fill.
 @param success a block called when the operation succeeds.
 @param failure a block called when the operation fails.
 */
- (void)paginateBackMessagesToFillRect:(CGRect)rect success:(void (^)())success failure:(void (^)(NSError *error))failure;


#pragma mark - Sending
/**
 Send a text message to the room.
 
 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.

 @param text the text to send.
 @param success A block object called when the operation succeeds. It returns
                the event id of the event generated on the home server
 @param failure A block object called when the operation fails.
 */
- (void)sendTextMessage:(NSString*)text
                success:(void (^)(NSString *eventId))success
                failure:(void (^)(NSError *error))failure;

/**
 Send an image to the room.

 While sending, a fake event will be echoed in the messages list.
 Once complete, this local echo will be replaced by the event saved by the homeserver.

 @param text the text to send.
 @param success A block object called when the operation succeeds. It returns
 the event id of the event generated on the home server
 @param failure A block object called when the operation fails.
 */
- (void)sendImage:(UIImage*)image
          success:(void (^)(NSString *eventId))success
          failure:(void (^)(NSError *error))failure;

@end
