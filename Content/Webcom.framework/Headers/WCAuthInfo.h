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
//  WCAuthInfo.h
//  Webcom
//
//  Created by Christophe Azemar.
//
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
/**
 An instance of `WCAuthInfo` is returned after a successful Webcom authentication and contains information about it.
 */
@interface WCAuthInfo : NSObject

/**
 @name Accessing Authentication Information
 */

/**
 The authentication token.
 */
@property(nonatomic, readonly, nullable) NSString * authToken;

/**
 The user's email.
 */
@property(nonatomic, readonly, nullable) NSString * email;

/**
 The expiration date of the authentication in seconds since the Unix epoch.
 */
@property(nonatomic, readonly, nullable) NSNumber * expires;

/**
 The authentication provider.
 */
@property(nonatomic, readonly, nullable) NSString * provider;

/**
 The user's unique identifier.
 */
@property(nonatomic, readonly, nullable) NSString * uid;

@end
NS_ASSUME_NONNULL_END
