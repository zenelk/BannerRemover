//
//  BRFileListConstructor.h
//  BannerRemover
//
//  Created by Zenel Kazushi on 7/18/15.
//  Copyright (c) 2015 Zenel Kazushi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BRFileListConstructor : NSObject

+ (NSDictionary *)constructFileListFromURLs:(NSArray *)URLs outputDirectory:(NSURL *)outputDirectory error:(out NSError **)error;

@end
