//
//  BRBannerRemoverManagerErrorFactory.m
//  BannerRemover
//
//  Created by Zenel Kazushi on 7/18/15.
//  Copyright (c) 2015 Zenel Kazushi. All rights reserved.
//

#import "BRBannerRemoverManagerErrorFactory.h"

static NSDictionary *errorDomainsForCodes;
static NSDictionary *errorDescriptionsForCodes;

@implementation BRBannerRemoverManagerErrorFactory

+ (NSError *)errorFromErrorCode:(BRBannerRemoverManagerErrorCode)errorCode {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self setupDictionaries];
    });
    return [NSError errorWithDomain:[errorDomainsForCodes objectForKey:@(errorCode)] code:errorCode userInfo:@{NSLocalizedDescriptionKey : [errorDescriptionsForCodes objectForKey:@(errorCode)]}];
}

+ (void)setupDictionaries {
    errorDomainsForCodes = @{ @(BRBannerRemoverManagerErrorCodeNoInputFiles) : @"com.zenel.BRBannerRemoverManager.NoInputFiles",
                              @(BRBannerRemoverManagerErrorCodeNoOutputDirectory) : @"com.zenel.BRBannerRemoverManager.NoOutputDirectory",
                              @(BRBannerRemoverManagerErrorCodeFileManagerFailure) : @"com.zenel.BRBannerRemoverManager.FileManagerFailure",
                              @(BRBannerRemoverManagerErrorCodeOutputIsNotADirectory) : @"com.zenel.BRBannerRemoverManager.OutputIsNotADirectory" };
    
    
    errorDescriptionsForCodes = @{ @(BRBannerRemoverManagerErrorCodeNoInputFiles) : @"User provided no input files to have their banners removed",
                                   @(BRBannerRemoverManagerErrorCodeNoOutputDirectory) : @"User provided no output directory to place completed files in",
                                   @(BRBannerRemoverManagerErrorCodeFileManagerFailure) : @"NSFileManager encountered an error attempting to access the one or more provided files",
                                   @(BRBannerRemoverManagerErrorCodeOutputIsNotADirectory) : @"Provided output URL is not a directory" };
}

@end
