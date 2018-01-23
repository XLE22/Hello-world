/*
 * Webcom iOS Client SDK
 * Build realtime apps. Share and sync data instantly between your clients
 *
 * Copyright (C) <2015> Orange
 *
 * This software is confidential and proprietary information of Orange.
 * You shall not disclose such Confidential Information and shall use it only in
 * accordance with the terms of the agreement you entered into.
 * Unauthorized copying of this file, via any medium is strictly prohibited.
 *
 * If you are Orange employee you shall use this software in accordance with
 * the Orange Source Charter (http://opensource.itn.ftgroup/index.php/Orange_Source_Charter)
 */

//
//  WCDataSnapshot.h
//  Webcom
//
//  Created by Christophe Azemar.
//
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
@class WCWebcom;

/**
 A `WCDataSnapshot` is used to read data from a specific Webcom location.
 
 Callbacks passed to `onEventType(_:withCallback:)` and `onceEventType(_:withCallback:)` methods from `WCQuery` are called with an instance of `WCDataSnapshot` as the first parameter.
 
 To get the data, use the `value` property.
 
 To update the data, use the `set(_:)`, `update(_:)`, `push(_:)` or `remove(_:)` methods from `WCWebcom`.
 
 Instances of `WCDataSnapshot` are immutables.
 */
@interface WCDataSnapshot : NSObject

/**
 @name Accessing the Data
 */

/**
 Retrieves the value object with priority data for this data snapshot.
 
 @return The value object with priority data.
 */
- (nullable id)exportVal;

/**
 Indicates if the data snapshot has at least one child.
 
 `true` if the data snapshot has any children, `false` it has no children.
 */
@property(nonatomic, readonly) BOOL hasChildren;

/**
 The name of the Webcom location targeted by this data snapshot.
 */
@property(nonatomic, readonly, nullable) NSString * name;

/**
 The number of children for this data snapshot.
 */
@property(nonatomic, readonly, nullable) NSNumber * numChildren;

/**
 The Webcom reference for the location of this data snapshot.
 */
@property(nonatomic, readonly, nullable) WCWebcom * ref;

/**
 The value object for this data snapshot.
 
 Value can be one of the following types:
 
 - `NSDictionary`
 - `NSArray`
 - `NSNumber`
 - `NSString`
 */
@property(nonatomic, readonly, nullable) id value;

/**
 @name Accessing the Children
 */

/**
 Retrieves the child data snapshot corresponding to the specified relative path.

 @param childPathString The path of the child relative to the data snapshot. For instance "friends" or "friends/fred".
 
 @return The child data snapshot for the location.
 */
- (nullable WCDataSnapshot *)child:(NSString *) childPathString;

/**
 Executes a given block using each children of the data snapshot.

 @param action The block to apply to the children. The child is passed as the parameter of this block. You can return `true` to stop the loop.
 @return `true` if the loop was stopped intentionally, `false` otherwise.
 */
- (BOOL)forEach:(BOOL(^)(WCDataSnapshot *child))action;

/**
 Indicates if a child data snapshot exists at the specified relative path.

 @param childPathString The path of the child relative to the data snapshot (for instance "friends" or "friends/fred").
 @return `true` if the child exists, `false` otherwise.
 */
- (BOOL)hasChild:(NSString *)childPathString;

@end
NS_ASSUME_NONNULL_END
