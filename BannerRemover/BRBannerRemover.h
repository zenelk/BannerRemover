//
//  BRBannerRemover.h
//  BannerRemover
//
//  Created by Zenel Kazushi on 7/17/15.
//  Copyright (c) 2015 Zenel Kazushi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BRBannerRemover : NSObject

+ (NSImage *)removeBanner:(NSImage *)banner fromImage:(NSImage *)image;

@end
