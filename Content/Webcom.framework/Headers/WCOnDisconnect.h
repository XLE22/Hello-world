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
//  WCOnDisconnect.h
//  Webcom
//
//  Created by Christophe Azemar.
//
//

#import <Foundation/Foundation.h>
#import "WCWebcomError.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An instance of `WCOnDisconnect` is useful to write and remove data if the user lost connection with the server. This can happen if there is a connection problem or if the app crashes.
 
 Registered actions are executed only once. Register your actions again if you need to.
 
 Managing presence is a common use case. You can prevent other friends if you are connected or not.
 
 Set actions as soon as possible to catch early connection problems.
 */
@interface WCOnDisconnect : NSObject

/**
 @name Cancelling Registration
 */

/**
 Cancels any action previously registered at the current location with the `set(_:)`, `update(_:)` or `remove(_:)` methods.
 */
- (void)cancel;

/**
 Cancels any action previously registered at the current location with the `set(_:)`, `update(_:)` or `remove(_:)` methods.

 @param completeCallback A block called when the server has cancelled the actions. An error can be passed as the parameter if something went wrong.
 */
- (void)cancelOnComplete:(nullable void ( ^ ) (NSError * __nullable error))completeCallback;

/**
 @name Registering Actions to Disconnection Events
 */

/**
 Removes the data at current location when a disconnection event occurs.
 */
- (void)remove;

/**
 Removes the data at current location when a disconnection event occurs.

 @param completeCallback A block called when the server has registered the remove action. An error can be passed as the parameter if something went wrong.
 */
- (void)removeOnComplete:(nullable void ( ^ ) (NSError * __nullable error))completeCallback;

/**
 Sets the data at current location when a disconnection event occurs.

 @param object The data to be set.
 */
- (void)set:(nullable NSObject *)object;

/**
 Sets the data at current location when a disconnection event occurs.

 @param object The data to be set.
 @param completeCallback A block called when the server has registered the set action. An error can be passed as the parameter if something went wrong.
 */
- (void)set:(nullable NSObject *)object onComplete:(nullable void ( ^ ) (NSError * __nullable error))completeCallback;

/**
 Updates the data at current location when a disconnection event occurs.
 
 @param object The children to be added.
 */
- (void)update:(NSObject *)object;

/**
 Updates the data at current location when a disconnection event occurs.

 @param object The children to be added.
 @param completeCallback A block called when the server has registered the update action. An error can be passed as the parameter if something went wrong.
 */
- (void)update:(NSObject *)object onComplete:(nullable void ( ^ ) (NSError * __nullable error))completeCallback;

@end

NS_ASSUME_NONNULL_END
