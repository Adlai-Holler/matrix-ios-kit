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

#import <Foundation/Foundation.h>

#import <MatrixSDK/MatrixSDK.h>

#import "MXKSectionedContacts.h"
#import "MXKContact.h"

/**
 Posted when the contact list is loaded and updated.
 The notification object is nil.
 */
extern NSString *const kMXKContactManagerDidUpdateContactsNotification;

/**
 Posted when contact matrix ids is updated.
 The notification object is a contact Id or nil when all contacts are concerned.
 */
extern NSString *const kMXKContactManagerDidUpdateContactMatrixIDsNotification;

/**
 Posted when the presence of a matrix user linked at least to one contact has changed.
 The notification object is the matrix Id. The `userInfo` dictionary contains an `MXPresenceString` object under the `kMXKContactManagerMatrixPresenceKey` key, representing the matrix user presence.
 */
extern NSString *const kMXKContactManagerMatrixUserPresenceChangeNotification;
extern NSString *const kMXKContactManagerMatrixPresenceKey;

/**
 Posted when all phonenumbers have been internationalized.
 The notification object is nil.
 */
extern NSString *const kMXKContactManagerDidInternationalizeNotification;

/**
 This manager handles 2 kinds of contact list:
 - The local contacts retrieved from the device phonebook.
 - The matrix users retrieved from the matrix one-to-one rooms.
 
 Note: The local contacts handling depends on the 'syncLocalContacts' and 'phonebookCountryCode' properties
 of the shared application settings object '[MXKAppSettings standardAppSettings]'.
 */
@interface MXKContactManager : NSObject

/**
 The shared instance of contact manager.
 */
+ (MXKContactManager*)sharedManager;

/**
 The identity server URL used to link matrix ids to the contacts according to their 3PIDs (email, phone number...).
 This property is nil by default.
 
 If this property is not set whereas some matrix sessions are added, the identity server of the first available matrix session is used.
 */
@property (nonatomic) NSString *identityServer;

/**
 Associated matrix sessions (empty by default).
 */
@property (nonatomic, readonly) NSArray *mxSessions;

/**
 The current contact list (nil by default until the device contacts are loaded).
 */
@property (nonatomic, readonly) NSArray *contacts;

/**
 No by default. Set YES to update matrix ids for all the contacts in only one request when contact are loaded and an identity server is available.
 */
@property (nonatomic) BOOL enableFullMatrixIdSyncOnContactsDidLoad;

/**
 Add/remove matrix session.
 */
- (void)addMatrixSession:(MXSession*)mxSession;
- (void)removeMatrixSession:(MXSession*)mxSession;

/**
 Load and refresh the contact list. See kMXKContactManagerDidUpdateContactsNotification posted when contact list is available.
 */
- (void)loadContacts;

/**
 Delete contacts info
 */
- (void)reset;

/**
 Refresh matrix IDs for a specific contact. See kMXKContactManagerDidUpdateContactMatrixIDsNotification
 posted when update is done.
 
 @param contact the contact to refresh.
 */
- (void)updateMatrixIDsForContact:(MXKContact*)contact;

/**
 Refresh matrix IDs for all listed contacts. See kMXKContactManagerDidUpdateContactMatrixIDsNotification
 posted when update for all contacts is done.
 */
- (void)updateContactsMatrixIDs;

/**
 Sort the contacts in sectioned arrays to be displayable in a UITableview
 */
- (MXKSectionedContacts*)getSectionedContacts:(NSArray*)contactList;

/**
 Refresh the international phonenumber of the contacts (See kMXKContactManagerDidInternationalizeNotification).
 
 @param countryCode
 */
- (void)internationalizePhoneNumbers:(NSString*)countryCode;

@end
