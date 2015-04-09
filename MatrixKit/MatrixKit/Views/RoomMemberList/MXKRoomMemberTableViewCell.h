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

#import "MXKImageView.h"
#import "MXKPieChartView.h"

#import "MXKCellRendering.h"

/**
 `MXKRoomMemberTableViewCell` instances display a room in the context of the recents list.
 */
@interface MXKRoomMemberTableViewCell : UITableViewCell <MXKCellRendering>

@property (strong, nonatomic) IBOutlet MXKImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UIView *powerContainer;
@property (weak, nonatomic) IBOutlet UIImageView *typingBadge;

@end
