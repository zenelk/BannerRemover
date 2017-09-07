//
//  BRBannerRemoverManagerErrorFactory.h
//  BannerRemover
//
//  Created by Zenel Kazushi on 7/18/15.
//  Copyright (c) 2015 Zenel Kazushi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(int, BRBannerRemoverManagerErrorCode)
{
    BRBannerRemoverManagerErrorCodeNoInputFiles = 1,
    BRBannerRemoverManagerErrorCodeNoOutputDirectory = 2,
    BRBannerRemoverManagerErrorCodeFileManagerFailure = 3,
    BRBannerRemoverManagerErrorCodeOutputIsNotADirectory = 4
};

@interface BRBannerRemoverManagerErrorFactory : NSObject

+ (NSError *)errorFromErrorCode:(BRBannerRemoverManagerErrorCode)errorCode;

@end
