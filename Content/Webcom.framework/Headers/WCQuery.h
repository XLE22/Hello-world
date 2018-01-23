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
//  WCQuery.h
//  Webcom
//
//  Created by Christophe Azemar.
//
//

#import <Foundation/Foundation.h>
#import "WCDataSnapshot.h"
#import "WCWebcomError.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The different types of events that can be observed at a Webcom location.
 */
typedef NS_ENUM(NSInteger, WCEventType) {
    /**
     A new child node is added to a location.
     */
    WCEventTypeChildAdded,
    /**
     A child node is removed from a location.
     */
    WCEventTypeChildRemoved,
    /**
     A child node changed at a location.
     */
    WCEventTypeChildChanged,
    /**
     A child node moved relative to the other child nodes at a location.
     */
    WCEventTypeChildMoved,
    /**
     Data changed at a location or at any child node recursively.
     */
    WCEventTypeValue
};

/**
 A `WCQuery` object sorts and filters data at a Webcom location.
 
 Can order and restrict data to a smallest subset.
 
 Queries can be chained easily with filter functions. They return `WCQuery` objects.
 */
@interface WCQuery : NSObject

/**
 @name Accessing Query Information
 */

/**
 The query reference for the location that generated this query.
 */
@property(nonatomic, readonly) WCQuery * ref;

/**
 The identifier of the query containing query criteria.
 */
@property(nonatomic, readonly) NSString * queryIdentifier;

/**
 The serialized query object.
 */
@property(nonatomic, readonly) NSDictionary * queryObject;

/**
 @name Observing Events at a Webcom Location
 */

/**
 Observes data changes only once at current Webcom reference location.
 
 @param type The type of event to be observed.
 @param callback A block called when the observed event occurs.
 */
- (void)onceEventType:(WCEventType)type withCallback:(void ( ^ ) (WCDataSnapshot * _Nullable snapshot , NSString * _Nullable prevKey))callback;

/**
 Observes data changes only once at current Webcom reference location.
 
 @param type The type of event to be observed.
 @param callback A block called when the observed event occurs.
 @param cancelCallback A block called when the user loses read permission at this location.
 */
- (void)onceEventType:(WCEventType)type withCallback:(void (^)(WCDataSnapshot * _Nullable snapshot , NSString * _Nullable prevKey))callback andCancelCallback:(nullable void ( ^ ) (NSError * _Nullable error))cancelCallback;

/**
 Observes data changes at current Webcom reference location.

 @param type The type of event to be observed.
 @param callback A block called when the observed event occurs.
 */
- (void)onEventType:(WCEventType)type withCallback:(void ( ^ ) (WCDataSnapshot * _Nullable snapshot , NSString * _Nullable prevKey))callback;

/**
 Observes data changes at current Webcom reference location.

 @param type The type of event to be observed.
 @param callback A block called when the observed event occurs.
 @param cancelCallback A block called when the user loses read permission at this location.
 */
- (void)onEventType:(WCEventType)type withCallback:(void (^)(WCDataSnapshot * _Nullable snapshot , NSString * _Nullable prevKey))callback andCancelCallback:(nullable void ( ^ ) (NSError * _Nullable error))cancelCallback;

/**
 @name Removing Observers
 */

/**
 Removes observers for data changes at current Webcom reference location.

 @param type The type of event observed.
 */
- (void)offEventType:(WCEventType)type;

@end

NS_ASSUME_NONNULL_END
