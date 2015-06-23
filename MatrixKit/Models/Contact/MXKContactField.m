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

#import "MXKContactField.h"

#import "MXKMediaManager.h"
#import "MXKContactManager.h"

@interface MXKContactField()
{
    NSString* avatarURL;
}
@end

@implementation MXKContactField

- (void)initFields
{
    // init members
    _contactID = nil;
    _matrixID = nil;
    avatarURL = @"";
}

- (id)initWithContactID:(NSString*)contactID matrixID:(NSString*)matrixID
{
    self = [super init];
    
    if (self)
    {
        [self initFields];
        _contactID = contactID;
        _matrixID = matrixID;
    }
    
    return self;
}

- (void)loadAvatarWithSize:(CGSize)avatarSize
{
    // Check whether the avatar image is already set
    if (_avatarImage)
    {
        return;
    }
    
    // Sanity check
    if (_matrixID)
    {
        // nil -> there is no avatar
        if (!avatarURL)
        {
            return;
        }
        
        // Empty string means not yet initialized
        if (avatarURL.length > 0)
        {
            [self downloadAvatarImage];
        }
        else
        {
            // Consider here all sessions reported into contact manager
            NSArray* mxSessions = [MXKContactManager sharedManager].mxSessions;
            
            if (mxSessions.count)
            {
                // Check whether a matrix user is already known
                MXUser* user;
                
                for (MXSession *mxSession in mxSessions)
                {
                    user = [mxSession userWithUserId:_matrixID];
                    if (user)
                    {
                        avatarURL = [mxSession.matrixRestClient urlOfContentThumbnail:user.avatarUrl toFitViewSize:avatarSize withMethod:MXThumbnailingMethodCrop];
                        [self downloadAvatarImage];
                        break;
                    }
                }
                
                
                if (!user)
                {
                    MXSession *mxSession = mxSessions.firstObject;
                    [mxSession.matrixRestClient avatarUrlForUser:_matrixID
                                                         success:^(NSString *avatarUrl)
                    {
                        avatarURL = [mxSession.matrixRestClient urlOfContentThumbnail:avatarUrl toFitViewSize:avatarSize withMethod:MXThumbnailingMethodCrop];
                        [self downloadAvatarImage];
                    }
                                                         failure:^(NSError *error)
                    {
                        //
                    }];
                }
            }
        }
    }
}

- (void)downloadAvatarImage
{
    // the avatar image is already done
    if (_avatarImage)
    {
        return;
    }
    
    if (avatarURL.length > 0)
    {
        NSString *cacheFilePath = [MXKMediaManager cachePathForMediaWithURL:avatarURL andType:nil inFolder:kMXKMediaManagerAvatarThumbnailFolder];
        
        _avatarImage = [MXKMediaManager loadPictureFromFilePath:cacheFilePath];
        
        // the image is already in the cache
        if (_avatarImage)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactThumbnailUpdateNotification object:_contactID userInfo:nil];
            });
        }
        else
        {
            
            MXKMediaLoader* loader = [MXKMediaManager existingDownloaderWithOutputFilePath:cacheFilePath];
            
            if (!loader)
            {
                [MXKMediaManager downloadMediaFromURL:avatarURL andSaveAtFilePath:cacheFilePath];
            }
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMediaDownloadEnd:) name:kMXKMediaDownloadDidFinishNotification object:nil];
        }
    }
}

- (void)onMediaDownloadEnd:(NSNotification *)notif
{
    // sanity check
    if ([notif.object isKindOfClass:[NSString class]])
    {
        NSString* url = notif.object;
        NSString* cacheFilePath = notif.userInfo[kMXKMediaLoaderFilePathKey];
        
        if ([url isEqualToString:avatarURL] && cacheFilePath.length)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kMXKMediaDownloadDidFinishNotification object:nil];
            
            // update the image
            UIImage* image = [MXKMediaManager loadPictureFromFilePath:cacheFilePath];
            if (image)
            {
                _avatarImage = image;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kMXKContactThumbnailUpdateNotification object:_contactID userInfo:nil];
                });
            }
        }
    }
}

#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder
{
    if (self)
    {
        [self initFields];
        _contactID = [coder decodeObjectForKey:@"contactID"];
        _matrixID = [coder decodeObjectForKey:@"matrixID"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_contactID forKey:@"contactID"];
    [coder encodeObject:_matrixID forKey:@"matrixID"];
}

@end
