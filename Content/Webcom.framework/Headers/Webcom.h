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
//  Webcom.h
//  Webcom
//
//  Created by Christophe Azemar
//

#import <UIKit/UIKit.h>

//! Project version number for Webcom.
FOUNDATION_EXPORT double WebcomVersionNumber;

//! Project version string for Webcom.
FOUNDATION_EXPORT const unsigned char WebcomVersionString[];

//This file is used for 'jazzy' as an 'umbrellaHeader' that describes all the '.h' to be documented.
#import "NSCharacterSet+Webcom.h"
#import "WCAuthInfo.h"
#import "WCDataSnapshot.h"
#import "WCOAuth2UserInfoFromProvider.h"
#import "WCOnDisconnect.h"
#import "WCQuery.h"
#import "WCWebcom.h"
#import "WCWebcomError.h"
