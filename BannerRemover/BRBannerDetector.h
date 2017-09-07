//
//  BRBannerDetector.h
//  BannerRemover
//
//  Created by Zenel Kazushi on 7/16/15.
//  Copyright (c) 2015 Zenel Kazushi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BRBannerDetector : NSObject

@property (nonatomic) BOOL debug;

- (NSImage *)detectBannerOnImage:(NSImage *)image;

@end
