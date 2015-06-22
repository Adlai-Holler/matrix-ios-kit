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

#import "MXKRoomBubbleTableViewCell.h"

#import "NSBundle+MatrixKit.h"

#pragma mark - Constant definitions
NSString *const kMXKRoomBubbleCellTapOnAvatarView = @"kMXKRoomBubbleCellTapOnAvatarView";
NSString *const kMXKRoomBubbleCellTapOnDateTimeContainer = @"kMXKRoomBubbleCellTapOnDateTimeContainer";
NSString *const kMXKRoomBubbleCellTapOnAttachmentView = @"kMXKRoomBubbleCellTapOnAttachmentView";
NSString *const kMXKRoomBubbleCellUnsentButtonPressed = @"kMXKRoomBubbleCellUnsentButtonPressed";

NSString *const kMXKRoomBubbleCellLongPressOnEvent = @"kMXKRoomBubbleCellLongPressOnEvent";
NSString *const kMXKRoomBubbleCellLongPressOnProgressView = @"kMXKRoomBubbleCellLongPressOnProgressView";

NSString *const kMXKRoomBubbleCellUserIdKey = @"kMXKRoomBubbleCellUserIdKey";
NSString *const kMXKRoomBubbleCellEventKey = @"kMXKRoomBubbleCellEventKey";


@implementation MXKRoomBubbleTableViewCell
@synthesize delegate, bubbleData;

+ (instancetype)roomBubbleTableViewCell
{
    // Check whether a xib is defined
    if ([[self class] nib])
    {
        return [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
    }
    
    return [[[self class] alloc] init];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.pictureView.backgroundColor = [UIColor clearColor];
    
    self.playIconView.image = [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"play"];
}

- (void)dealloc
{
    // remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    delegate = nil;
}

- (UIImage*)picturePlaceholder
{
    return [NSBundle mxk_imageFromMXKAssetsBundleWithName:@"default-profile"];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)render:(MXKCellData *)cellData
{
    [self originalRender:cellData];
}

- (void)originalRender:(MXKCellData *)cellData
{
    // Sanity check: accept only object of MXKRoomBubbleCellData classes or sub-classes
    NSParameterAssert([cellData isKindOfClass:[MXKRoomBubbleCellData class]]);
    
    bubbleData = (MXKRoomBubbleCellData*)cellData;
    if (bubbleData)
    {
        // set the media folders
        self.pictureView.mediaFolder = kMXKMediaManagerAvatarThumbnailFolder;
        self.attachmentView.mediaFolder = bubbleData.roomId;
        
        // Handle sender's picture and adjust view's constraints
        self.pictureView.hidden = NO;
        self.msgTextViewTopConstraint.constant = self.class.cellWithOriginalXib.msgTextViewTopConstraint.constant;
        self.attachViewTopConstraint.constant = self.class.cellWithOriginalXib.attachViewTopConstraint.constant ;
        // Handle user's picture
        NSString *avatarThumbURL = nil;
        if (bubbleData.senderAvatarUrl)
        {
            // Suppose this url is a matrix content uri, we use SDK to get the well adapted thumbnail from server
            avatarThumbURL = [bubbleData.mxSession.matrixRestClient urlOfContentThumbnail:bubbleData.senderAvatarUrl toFitViewSize:self.pictureView.frame.size withMethod:MXThumbnailingMethodCrop];
        }
        [self.pictureView setImageURL:avatarThumbURL withImageOrientation:UIImageOrientationUp andPreviewImage:self.picturePlaceholder];
        [self.pictureView.layer setCornerRadius:self.pictureView.frame.size.width / 2];
        self.pictureView.clipsToBounds = YES;
        self.pictureView.backgroundColor = [UIColor redColor];
        
        // Listen to avatar tap
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAvatarTap:)];
        [tapGesture setNumberOfTouchesRequired:1];
        [tapGesture setNumberOfTapsRequired:1];
        [tapGesture setDelegate:self];
        [self.pictureView addGestureRecognizer:tapGesture];
        self.pictureView.userInteractionEnabled = YES;
        
        // Adjust top constraint constant for dateTime labels container, and hide it by default
        if (bubbleData.dataType == MXKRoomBubbleCellDataTypeText)
        {
            self.dateTimeLabelContainerTopConstraint.constant = self.msgTextViewTopConstraint.constant;
        }
        else
        {
            self.dateTimeLabelContainerTopConstraint.constant = self.attachViewTopConstraint.constant;
        }
        self.dateTimeLabelContainer.hidden = YES;
        
        // Set message content
        bubbleData.maxTextViewWidth = self.frame.size.width - (self.class.cellWithOriginalXib.msgTextViewLeadingConstraint.constant + self.class.cellWithOriginalXib.msgTextViewTrailingConstraint.constant);
        CGSize contentSize = bubbleData.contentSize;
        if (bubbleData.dataType != MXKRoomBubbleCellDataTypeText)
        {
            self.messageTextView.hidden = YES;
            self.attachmentView.hidden = NO;
            
            // Update image view frame in order to center loading wheel (if any)
            CGRect frame = self.attachmentView.frame;
            frame.size.width = contentSize.width;
            frame.size.height = contentSize.height;
            self.attachmentView.frame = frame;
            
            NSString *url = bubbleData.thumbnailURL;
            if (bubbleData.dataType == MXKRoomBubbleCellDataTypeVideo)
            {
                self.playIconView.hidden = NO;
            }
            else
            {
                self.playIconView.hidden = YES;
            }
            UIImage *preview = nil;
            if (bubbleData.previewURL)
            {
                NSString *cacheFilePath = [MXKMediaManager cachePathForMediaWithURL:bubbleData.previewURL inFolder:self.attachmentView.mediaFolder];
                preview = [MXKMediaManager loadPictureFromFilePath:cacheFilePath];
            }
            [self.attachmentView setImageURL:url withImageOrientation:bubbleData.thumbnailOrientation andPreviewImage:preview];
            
            if (url && bubbleData.attachmentURL && bubbleData.attachmentInfo)
            {
                
                // Add tap recognizer to open attachment
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onAttachmentTap:)];
                [tap setNumberOfTouchesRequired:1];
                [tap setNumberOfTapsRequired:1];
                [tap setDelegate:self];
                [self.attachmentView addGestureRecognizer:tap];
                
                // Store attachment content description used in showAttachmentView:
                self.attachmentView.mediaInfo = @{
                                                  @"msgtype" : [NSNumber numberWithUnsignedInt:bubbleData.dataType],
                                                  @"url" : bubbleData.attachmentURL,
                                                  @"info" : bubbleData.attachmentInfo
                                                  };
            }
            
            [self startProgressUI];
            
            // Adjust Attachment width constant
            self.attachViewWidthConstraint.constant = contentSize.width;
            
            // Add a long gesture recognizer on attachment view in order to display event details
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressGesture:)];
            [self.attachmentView addGestureRecognizer:longPress];
            // Add another long gesture recognizer on progressView to cancel the current operation (Note: only the download can be cancelled).
            longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressGesture:)];
            [self.progressView addGestureRecognizer:longPress];
        }
        else
        {
            self.attachmentView.hidden = YES;
            self.playIconView.hidden = YES;
            self.messageTextView.hidden = NO;
            if (!bubbleData.isIncoming)
            {
                // Adjust horizontal position for outgoing messages (text is left aligned, but the textView should be right aligned)
                CGFloat leftInset = bubbleData.maxTextViewWidth - contentSize.width;
                self.messageTextView.contentInset = UIEdgeInsetsMake(0, leftInset, 0, -leftInset);
            }
            self.messageTextView.attributedText = bubbleData.attributedTextMessage;
            
            // Add a long gesture recognizer on text view in order to display event details
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressGesture:)];
            [self.messageTextView addGestureRecognizer:longPress];
        }
        
        // Check and update each component position (used to align timestamps label in front of events, and to handle tap gesture on events)
        [bubbleData prepareBubbleComponentsPosition];
        
        // Handle timestamp display
        if (bubbleData.showBubbleDateTime)
        {
            // Add datetime label for each component
            self.dateTimeLabelContainer.hidden = NO;
            for (MXKRoomBubbleComponent *component in bubbleData.bubbleComponents)
            {
                if (component.date && (component.event.mxkState != MXKEventStateSendingFailed))
                {
                    UILabel *dateTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, component.position.y, self.dateTimeLabelContainer.frame.size.width , 20)];
                    dateTimeLabel.text = [bubbleData.eventFormatter.dateFormatter stringFromDate:component.date];
                    if (bubbleData.isIncoming)
                    {
                        dateTimeLabel.textAlignment = NSTextAlignmentRight;
                    }
                    else
                    {
                        dateTimeLabel.textAlignment = NSTextAlignmentLeft;
                    }
                    dateTimeLabel.textColor = [UIColor lightGrayColor];
                    dateTimeLabel.font = [UIFont systemFontOfSize:12];
                    dateTimeLabel.adjustsFontSizeToFitWidth = YES;
                    dateTimeLabel.minimumScaleFactor = 0.6;
                    [dateTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
                    [self.dateTimeLabelContainer addSubview:dateTimeLabel];
                    // Force dateTimeLabel in full width (to handle auto-layout in case of screen rotation)
                    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:dateTimeLabel
                                                                                      attribute:NSLayoutAttributeLeading
                                                                                      relatedBy:NSLayoutRelationEqual
                                                                                         toItem:self.dateTimeLabelContainer
                                                                                      attribute:NSLayoutAttributeLeading
                                                                                     multiplier:1.0
                                                                                       constant:0];
                    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:dateTimeLabel
                                                                                       attribute:NSLayoutAttributeTrailing
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:self.dateTimeLabelContainer
                                                                                       attribute:NSLayoutAttributeTrailing
                                                                                      multiplier:1.0
                                                                                        constant:0];
                    // Vertical constraints are required for iOS > 8
                    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:dateTimeLabel
                                                                                     attribute:NSLayoutAttributeTop
                                                                                     relatedBy:NSLayoutRelationEqual
                                                                                        toItem:self.dateTimeLabelContainer
                                                                                     attribute:NSLayoutAttributeTop
                                                                                    multiplier:1.0
                                                                                      constant:component.position.y];
                    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:dateTimeLabel
                                                                                        attribute:NSLayoutAttributeHeight
                                                                                        relatedBy:NSLayoutRelationEqual
                                                                                           toItem:nil
                                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                                       multiplier:1.0
                                                                                         constant:20];
                    if ([NSLayoutConstraint respondsToSelector:@selector(activateConstraints:)])
                    {
                        [NSLayoutConstraint activateConstraints:@[leftConstraint, rightConstraint, topConstraint, heightConstraint]];
                    }
                    else
                    {
                        [self.dateTimeLabelContainer addConstraint:leftConstraint];
                        [self.dateTimeLabelContainer addConstraint:rightConstraint];
                        [self.dateTimeLabelContainer addConstraint:topConstraint];
                        [dateTimeLabel addConstraint:heightConstraint];
                    }
                }
            }
        }
    }
}

+ (CGFloat)heightForCellData:(MXKCellData*)cellData withMaximumWidth:(CGFloat)maxWidth
{
    return [self originalHeightForCellData:cellData withMaximumWidth:maxWidth];
}

+ (CGFloat)originalHeightForCellData:(MXKCellData *)cellData withMaximumWidth:(CGFloat)maxWidth
{
    // Sanity check: accept only object of MXKRoomBubbleCellData classes or sub-classes
    NSParameterAssert([cellData isKindOfClass:[MXKRoomBubbleCellData class]]);
    
    MXKRoomBubbleCellData *bubbleData = (MXKRoomBubbleCellData*)cellData;
    // Compute height of message content (The maximum width available for the textview must be updated dynamically)
    bubbleData.maxTextViewWidth = maxWidth - (self.class.cellWithOriginalXib.msgTextViewLeadingConstraint.constant + self.class.cellWithOriginalXib.msgTextViewTrailingConstraint.constant);
    CGFloat rowHeight = bubbleData.contentSize.height;
    
    // Add top margin
    if (bubbleData.dataType == MXKRoomBubbleCellDataTypeText)
    {
        rowHeight += self.cellWithOriginalXib.msgTextViewTopConstraint.constant;
    }
    else
    {
        rowHeight += self.cellWithOriginalXib.attachViewTopConstraint.constant ;
    }
    
    return rowHeight;
}

- (void)didEndDisplay
{
    bubbleData = nil;
    
    // Remove all gesture recognizer
    while (self.attachmentView.gestureRecognizers.count)
    {
        [self.attachmentView removeGestureRecognizer:self.attachmentView.gestureRecognizers[0]];
    }
    
    // Remove potential dateTime (or unsent) label(s)
    if (self.dateTimeLabelContainer.subviews.count > 0)
    {
        if ([NSLayoutConstraint respondsToSelector:@selector(deactivateConstraints:)])
        {
            [NSLayoutConstraint deactivateConstraints:self.dateTimeLabelContainer.constraints];
        }
        else
        {
            [self.dateTimeLabelContainer removeConstraints:self.dateTimeLabelContainer.constraints];
        }
        for (UIView *view in self.dateTimeLabelContainer.subviews)
        {
            [view removeFromSuperview];
        }
    }
    
    [self stopProgressUI];
    
    // Remove long tap gesture on the progressView
    while (self.progressView.gestureRecognizers.count)
    {
        [self.progressView removeGestureRecognizer:self.progressView.gestureRecognizers[0]];
    }
    
    delegate = nil;
}

- (void)updateProgressUI:(NSDictionary*)statisticsDict
{
    self.progressView.hidden = !statisticsDict;
    
    NSString* downloadRate = [statisticsDict valueForKey:kMXKMediaLoaderProgressRateKey];
    NSString* remaingTime = [statisticsDict valueForKey:kMXKMediaLoaderProgressRemaingTimeKey];
    NSString* progressString = [statisticsDict valueForKey:kMXKMediaLoaderProgressStringKey];
    
    NSMutableString* text = [[NSMutableString alloc] init];
    
    if (progressString)
    {
        [text appendString:progressString];
    }
    
    if (downloadRate)
    {
        [text appendFormat:@"\n%@", downloadRate];
    }
    
    if (remaingTime)
    {
        [text appendFormat:@"\n%@", remaingTime];
    }
    
    self.statsLabel.text = text;
    
    NSNumber* progressNumber = [statisticsDict valueForKey:kMXKMediaLoaderProgressValueKey];
    
    if (progressNumber)
    {
        self.progressChartView.progress = progressNumber.floatValue;
    }
}

- (void)onMediaDownloadProgress:(NSNotification *)notif
{
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]])
    {
        NSString* url = notif.object;
        
        if ([url isEqualToString:bubbleData.attachmentURL])
        {
            [self updateProgressUI:notif.userInfo];
        }
    }
}

- (void)onMediaDownloadEnd:(NSNotification *)notif
{
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]])
    {
        NSString* url = notif.object;
        
        if ([url isEqualToString:bubbleData.attachmentURL])
        {
            [self stopProgressUI];
            
            // the job is really over
            if ([notif.name isEqualToString:kMXKMediaDownloadDidFinishNotification])
            {
                // remove any pending observers
                [[NSNotificationCenter defaultCenter] removeObserver:self];
            }
        }
    }
}

- (void)startProgressUI
{
    BOOL isHidden = YES;
    
    // remove any pending observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // there is an attachment URL
    if (bubbleData.attachmentURL)
    {
        // check if there is a download in progress
        MXKMediaLoader *loader = [MXKMediaManager existingDownloaderWithOutputFilePath:bubbleData.attachmentCacheFilePath];
        
        NSDictionary *dict = loader.statisticsDict;
        
        if (dict)
        {
            isHidden = NO;
            
            // defines the text to display
            [self updateProgressUI:dict];
        }
        
        // anyway listen to the progress event
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMXKMediaDownloadDidFinishNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMXKMediaDownloadDidFailNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadProgress:) name:kMXKMediaDownloadProgressNotification object:nil];
    }
    
    self.progressView.hidden = isHidden;
}

- (void)stopProgressUI
{
    self.progressView.hidden = YES;
    
    // do not remove the observer here
    // the download could restart without recomposing the cell
}

#pragma mark - Original Xib values

/**
 `childClasses` hosts one instance of each child classes of `MXKRoomBubbleTableViewCell`.
 The key is the child class name. The value, the instance.
 */
static NSMutableDictionary *childClasses;

+ (MXKRoomBubbleTableViewCell*)cellWithOriginalXib
{
    MXKRoomBubbleTableViewCell *cellWithOriginalXib;
    
    @synchronized(self)
    {
        if(childClasses == nil)
        {
            childClasses = [NSMutableDictionary dictionary];
        }
        
        // To save memory, use only one original instance per child class
        cellWithOriginalXib = childClasses[NSStringFromClass(self.class)];
        if (nil == cellWithOriginalXib)
        {
            cellWithOriginalXib = [self roomBubbleTableViewCell];
            
            childClasses[NSStringFromClass(self.class)] = cellWithOriginalXib;
        }
    }
    return cellWithOriginalXib;
}

#pragma mark - User actions
- (IBAction)onAvatarTap:(UITapGestureRecognizer*)sender
{
    if (delegate)
    {
        [delegate cell:self didRecognizeAction:kMXKRoomBubbleCellTapOnAvatarView userInfo:@{kMXKRoomBubbleCellUserIdKey: bubbleData.senderId}];
    }
}

- (IBAction)onAttachmentTap:(UITapGestureRecognizer*)sender
{
    if (delegate)
    {
        [delegate cell:self didRecognizeAction:kMXKRoomBubbleCellTapOnAttachmentView userInfo:nil];
    }
}

- (IBAction)showHideDateTime:(id)sender
{
    if (delegate)
    {
        [delegate cell:self didRecognizeAction:kMXKRoomBubbleCellTapOnDateTimeContainer userInfo:nil];
    }
}

- (IBAction)onLongPressGesture:(UILongPressGestureRecognizer*)longPressGestureRecognizer
{
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan && delegate)
    {
        UIView* view = longPressGestureRecognizer.view;
        
        // Check the view on which long press has been detected
        if (view == self.progressView)
        {
            [delegate cell:self didRecognizeAction:kMXKRoomBubbleCellLongPressOnProgressView userInfo:nil];
        }
        else if (view == self.messageTextView || view == self.attachmentView)
        {
            MXEvent *selectedEvent = nil;
            if (bubbleData.bubbleComponents.count == 1)
            {
                MXKRoomBubbleComponent *component = [bubbleData.bubbleComponents firstObject];
                selectedEvent = component.event;
            }
            else if (bubbleData.bubbleComponents.count)
            {
                // Here the selected view is a textView (attachment has no more than one component)
                
                // Look for the selected component
                CGPoint longPressPoint = [longPressGestureRecognizer locationInView:view];
                for (MXKRoomBubbleComponent *component in bubbleData.bubbleComponents)
                {
                    if (longPressPoint.y < component.position.y)
                    {
                        break;
                    }
                    selectedEvent = component.event;
                }
            }
            
            if (selectedEvent)
            {
                [delegate cell:self didRecognizeAction:kMXKRoomBubbleCellLongPressOnEvent userInfo:@{kMXKRoomBubbleCellEventKey:selectedEvent}];
            }
        }
    }
}

@end
