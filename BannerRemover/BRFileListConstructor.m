//
//  BRFileListConstructor.m
//  BannerRemover
//
//  Created by Zenel Kazushi on 7/18/15.
//  Copyright (c) 2015 Zenel Kazushi. All rights reserved.
//

#import "BRFileListConstructor.h"
#import "BRBannerRemoverManagerErrorFactory.h"

static NSString *BRFileListConstructorKeyInputURL = @"Input";
static NSString *BRFileListConstructorKeyOutputURL = @"Output";

@implementation BRFileListConstructor

+ (NSDictionary *)constructFileListFromURLs:(NSArray *)URLs outputDirectory:(NSURL *)outputDirectory error:(out NSError **)error {
    NSMutableDictionary *fileList = [NSMutableDictionary dictionary];
    for (NSURL *url in URLs) {
        NSNumber *isDirectory;
        BOOL success = [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:error];
        if (!success) {
            NSLog(@"Could not determine if URL %@ is a directory", url);
            return nil;
        }
        if ([isDirectory boolValue]) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSArray *directoryEnumerationSuccess = [fileManager contentsOfDirectoryAtPath:[url path] error:error];
            if (!directoryEnumerationSuccess)
            {
                return nil;
            }
            NSMutableArray *contentsURLs = [NSMutableArray array];
            for (NSString *file in directoryEnumerationSuccess) {
                [contentsURLs addObject:[NSURL fileURLWithPath:[[url path] stringByAppendingPathComponent:file]]];
            }
            
            NSURL *subDirOutputURL = [NSURL fileURLWithPath:[[outputDirectory path] stringByAppendingPathComponent:[[url path] lastPathComponent]]];
            NSDictionary *subDirFileList = [self constructFileListFromURLs:contentsURLs outputDirectory:subDirOutputURL error:error];
            if (!subDirFileList) {
                return nil;
            }
            for (NSURL *innerURL in [subDirFileList allKeys]) {
                [fileList setObject:[subDirFileList objectForKey:innerURL] forKey:innerURL];
            }
        }
        else {
            NSString *outputFilePath = [[outputDirectory absoluteString] stringByAppendingPathComponent:[[url absoluteString] lastPathComponent]];
            NSURL *outputFileURL = [NSURL URLWithString:outputFilePath];
            [fileList setObject:outputFileURL forKey:url];
        }
    }
    return [fileList copy];
}

@end
