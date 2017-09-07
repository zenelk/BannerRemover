//
//  BRBannerRemoverManager.h
//  BannerRemover
//
//  Created by Zenel Kazushi on 7/16/15.
//  Copyright (c) 2015 Zenel Kazushi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^BRBannerRemoverManagerCompletionHandler)(BOOL success, NSError *error);

@class BRBannerRemoverManager;

@protocol BRBannerRemoverManagerDelegate <NSObject>

- (void)bannerRemoverManager:(BRBannerRemoverManager *)manager didFinishProcessSuccessfully:(BOOL)success withError:(NSError *)error;
- (void)bannerRemoverManager:(BRBannerRemoverManager *)manager didUpdateProgress:(float)progress;

@end

@interface BRBannerRemoverManager : NSObject

@property (nonatomic) BOOL debugDetection;
@property (nonatomic) NSUInteger numberOfAllowedProcessingOperations;
@property (nonatomic) NSUInteger numberOfAllowedSavingOperations;
@property (readonly) NSUInteger maxNumberOfAllowedProcessingOperations;
@property (readonly) NSUInteger maxNumberOfAllowedSavingOperations;

- (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDelegate:(id<BRBannerRemoverManagerDelegate>)delegate;


- (void)removeBannersOnURLs:(NSArray *)URLs withOutputDirectory:(NSURL *)outputDirectory;

@end
