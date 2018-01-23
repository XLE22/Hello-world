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
//  WCWebcomError.h
//  Webcom
//
//  Created by Florent Maitre.
//

#import <Foundation/Foundation.h>

/**
 `WCWebcomErrorDomain` indicates a Webcom error.
 */
FOUNDATION_EXPORT NSErrorDomain const WCWebcomErrorDomain;

/**
 Constants used by NSError to indicate errors in the Webcom domain.
 */
NS_ENUM(NSInteger)
{
    /**
     *  Unknown error.
     */
    WCWebcomErrorUnknown = -1,
};
