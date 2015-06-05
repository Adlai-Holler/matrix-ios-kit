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
#import "MXKCellRendering.h"

/**
 List data source states.
 */
typedef enum : NSUInteger {
    /**
     Default value (used when all resources have been disposed).
     The instance cannot be used anymore.
     */
    MXKDataSourceStateUnknown,
    
    /**
     Initialisation is in progress.
     */
    MXKDataSourceStatePreparing,
    
    /**
     Something wrong happens during initialisation.
     */
    MXKDataSourceStateFailed,
    
    /**
     Data source is ready to be used.
     */
    MXKDataSourceStateReady
    
} MXKDataSourceState;

@protocol MXKDataSourceDelegate;

/**
 `MXKDataSource` is the base class for data sources managed by MatrixKit.
 */
@interface MXKDataSource : NSObject <MXKCellRenderingDelegate>
{
@protected
    MXKDataSourceState state;
}

/**
 The matrix session.
 */
@property (nonatomic, readonly) MXSession *mxSession;

/**
 The data source state
 */
@property (nonatomic, readonly) MXKDataSourceState state;

/**
 The delegate notified when the data has been updated.
 */
@property (nonatomic) id<MXKDataSourceDelegate> delegate;


#pragma mark - Life cycle
/**
 Base constructor of data source.

 @param mxSession the Matrix session to get data from.
 @return the newly created instance.
 */
- (instancetype)initWithMatrixSession:(MXSession*)mxSession;

/**
 Dispose all resources.
 */
- (void)destroy;

/**
 This method is called when the state of the attached Matrix session has changed.
 */
- (void)didMXSessionStateChange;


#pragma mark - MXKCellData classes
/**
 Register the MXKCellData class that will be used to process and store data for cells
 with the designated identifier.

 @param cellDataClass a MXKCellData-inherited class that will handle data for cells.
 @param identifier the identifier of targeted cell.
 */
- (void)registerCellDataClass:(Class)cellDataClass forCellIdentifier:(NSString *)identifier;

/**
 Return the MXKCellData class that handles data for cells with the designated identifier.

 @param identifier the cell identifier.
 @return the associated MXKCellData-inherited class.
 */
- (Class)cellDataClassForCellIdentifier:(NSString *)identifier;


#pragma mark - MXKCellRendering classes
/**
 Register the MXKCellRendering-compliant class and that will be used to display cells
 with the designated identifier.

 @param cellViewClass a class implementing the `MXKCellRendering` protocol.
 @param identifier the identifier of targeted cell.
 */
- (void)registerCellViewClass:(Class<MXKCellRendering>)cellViewClass forCellIdentifier:(NSString *)identifier;

/**
 Return the MXKCellRendering-compliant class that manages the display of cells with the designated identifier.

 @param identifier the cell identifier.
 @return the associated MXKCellData-inherited class.
 */
- (Class<MXKCellRendering>)cellViewClassForCellIdentifier:(NSString *)identifier;


#pragma mark - Pending HTTP requests 
/**
 Cancel all registered requests.
 */
- (void)cancelAllRequests;

@end


@protocol MXKDataSourceDelegate <NSObject>

/**
 Tells the delegate that some cell data/views have been changed.

 @param dataSource the involved data source.
 @param changes contains the index paths of objects that changed.
 */
- (void)dataSource:(MXKDataSource*)dataSource didCellChange:(id /* @TODO*/)changes;

@optional

/**
 Tells the delegate that data source state changed
 
 @param dataSource the involved data source.
 @param state the new data source state.
 */
- (void)dataSource:(MXKDataSource*)dataSource didStateChange:(MXKDataSourceState)state;

/**
 Relevant only for data source which support multi-sessions.
 Tells the delegate that a matrix session has been added.
 
 @param dataSource the involved data source.
 @param the new added session.
 */
- (void)dataSource:(MXKDataSource*)dataSource didAddMatrixSession:(MXSession*)mxSession;

/**
 Relevant only for data source which support multi-sessions.
 Tells the delegate that a matrix session has been removed.
 
 @param dataSource the involved data source.
 @param the removed session.
 */
- (void)dataSource:(MXKDataSource*)dataSource didRemoveMatrixSession:(MXSession*)mxSession;

/**
 Tells the delegate when a user action is observed inside a cell.
 
 @see `MXKCellRenderingDelegate` for more details.
 
 @param dataSource the involved data source.
 @param actionIdentifier an identifier indicating the action type (tap, long press...) and which part of the cell is concerned.
 @param cell the cell in which action has been observed.
 @param userInfo a dict containing additional information. It depends on actionIdentifier. May be nil.
 */
- (void)dataSource:(MXKDataSource*)dataSource didRecognizeAction:(NSString*)actionIdentifier inCell:(id<MXKCellRendering>)cell userInfo:(NSDictionary*)userInfo;

@end