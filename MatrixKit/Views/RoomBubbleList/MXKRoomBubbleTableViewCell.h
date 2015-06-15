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

#import "MXKCellRendering.h"

#import "MXKRoomBubbleCellData.h"
#import "MXKMediaManager.h"

#import "MXKImageView.h"
#import "MXKPieChartView.h"

#pragma mark - MXKCellRenderingDelegate cell tap locations
/**
 Action identifier used when the user tapped on avatar view.
 
 The `userInfo` dictionary contains an `NSString` object under the `kMXKRoomBubbleCellUserIdKey` key, representing the user id of the tapped avatar.
 */
extern NSString *const kMXKRoomBubbleCellTapOnAvatarView;

/**
 Action identifier used when the user tapped on date/time container.
 
 The `userInfo` is nil.
 */
extern NSString *const kMXKRoomBubbleCellTapOnDateTimeContainer;

/**
 Action identifier used when the user tapped on attachment view.
 
 The `userInfo` is nil. The attachment can be retrieved via MXKRoomBubbleTableViewCell.attachmentView.
 */
extern NSString *const kMXKRoomBubbleCellTapOnAttachmentView;

/**
 Action identifier used when the user pressed unsent button displayed in front of an unsent event.
 
 The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the unsent event.
 */
extern NSString *const kMXKRoomBubbleCellUnsentButtonPressed;

/**
 Action identifier used when the user long pressed on a displayed event.
 
 The `userInfo` dictionary contains an `MXEvent` object under the `kMXKRoomBubbleCellEventKey` key, representing the selected event.
 */
extern NSString *const kMXKRoomBubbleCellLongPressOnEvent;

/**
 Action identifier used when the user long pressed on progress view.
 
 The `userInfo` is nil. The progress view can be retrieved via MXKRoomBubbleTableViewCell.progressView.
 */
extern NSString *const kMXKRoomBubbleCellLongPressOnProgressView;

/**
 Notifications `userInfo` keys
 */
extern NSString *const kMXKRoomBubbleCellUserIdKey;
extern NSString *const kMXKRoomBubbleCellEventKey;

#pragma mark - MXKRoomBubbleTableViewCell
/**
 `MXKRoomBubbleTableViewCell` is a base class for displaying a room bubble.
 */
@interface MXKRoomBubbleTableViewCell : UITableViewCell <MXKCellRendering>

/**
 The current bubble data displayed by the table view cell
 */
@property (strong, nonatomic) MXKRoomBubbleCellData *bubbleData;

/**
 The default picture displayed when no picture is available.
 */
@property (nonatomic) UIImage *picturePlaceholder;

@property (strong, nonatomic) IBOutlet MXKImageView *pictureView;
@property (weak, nonatomic) IBOutlet UITextView  *messageTextView;
@property (strong, nonatomic) IBOutlet MXKImageView *attachmentView;
@property (strong, nonatomic) IBOutlet UIImageView *playIconView;
@property (weak, nonatomic) IBOutlet UIView *dateTimeLabelContainer;

@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *statsLabel;
@property (weak, nonatomic) IBOutlet MXKPieChartView *progressChartView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *msgTextViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *msgTextViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *msgTextViewTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *attachViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dateTimeLabelContainerTopConstraint;

- (void)updateProgressUI:(NSDictionary*)statisticsDict;

#pragma mark - Original Xib values

/**
 Get an original instance of the `MXKRoomBubbleTableViewCell` child class.

 @return an instance of the child class caller which has the original Xib values.
 */
+ (MXKRoomBubbleTableViewCell*)cellWithOriginalXib;

/**
 The `MXKRoomBubbleTableViewCell` orignal implementation of [MXKCellRendering render:] not
 overidden by a class child.

 @param cellData the data object to render.
 */
- (void)originalRender:(MXKCellData*)cellData;

/**
 The `MXKRoomBubbleTableViewCell` orignal implementation of [MXKCellRendering 
 originalHeightForCellData: withMaximumWidth:] not overidden by a class child.

 @param cellData the data object to render.
 @param maxWidth the maximum available width.
 @return the cell height
 */
+ (CGFloat)originalHeightForCellData:(MXKCellData*)cellData withMaximumWidth:(CGFloat)maxWidth;

@end
