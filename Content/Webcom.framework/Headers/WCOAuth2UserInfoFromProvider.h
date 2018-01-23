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
//  WCOAuth2AccessToken.h
//  Webcom
//
//  Created by Xavier LELEU.
//
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
/**
 An instance of `WCOAuth2UserInfoFromProvider` is returned after a successful OAuth2 authentication with a provider.
 */
@interface WCOAuth2UserInfoFromProvider : NSObject
/**
 @name Accessing OAuth2 User Information
 */

/**
 The OAuth2.0 access token got from the provider.
 May be further used by the application to invoke some provider's APIs.
 */
@property(nonatomic, readonly, nullable) NSString * accessToken;

/**
 The date the account has been created to the provider in milliseconds since the Unix epoch time.
 */
@property(nonatomic, readonly) CGFloat creationDate;

/**
 A human-readable description of the authenticated end user extracted from the previous profile data.
 It can be missing if no description can be found.
 */
@property(nonatomic, readonly, nullable) NSString * userDisplayName;

/**
 The expiration date of the authentication in seconds since the Unix epoch time.
 */
@property(nonatomic, readonly) CGFloat expires;

/**
 The name of the provider.
 */
@property(nonatomic, readonly, nullable) NSString * providerName;

/**
 Dictionary containing user's profile given by the provider.
 */
@property(nonatomic, readonly, nullable) NSDictionary * providerProfile;

/**
 The internal identifier of the authenticated end user used by the OAuth2.0 provider.
 */
@property(nonatomic, readonly, nullable) NSString * providerUID;

/**
 The user's unique identifier to log in to Webcom.
 */
@property(nonatomic, readonly, nullable) NSString * uid;

/**
 The Webcom authentication token.
 */
@property(nonatomic, readonly, nullable) NSString * authToken;
@end
NS_ASSUME_NONNULL_END
