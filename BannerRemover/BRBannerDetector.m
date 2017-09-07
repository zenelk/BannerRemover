//
//  BRBannerDetector.m
//  BannerRemover
//
//  Created by Zenel Kazushi on 7/16/15.
//  Copyright (c) 2015 Zenel Kazushi. All rights reserved.
//

#import "BRBannerDetector.h"
#import <AppKit/AppKit.h>

static int RGBA_TOLERANCE = 70;

@interface BRBannerDetector()

@property (nonatomic, strong) NSArray *bannerTags;

@end

@implementation BRBannerDetector

- (instancetype)init {
    if (self = [super init]) {
        NSString *oldBannerPath = [[NSBundle mainBundle] pathForResource:@"oldBannerTag" ofType:@"png"];
        NSData *oldBannerData = [NSData dataWithContentsOfFile:oldBannerPath];
        NSImage *oldBannerTag = [[NSImage alloc] initWithData:oldBannerData];
        
        NSString *oldBannerCoTagPath = [[NSBundle mainBundle] pathForResource:@"oldBannerCoTag" ofType:@"png"];
        NSData *oldBannerCoTagData = [NSData dataWithContentsOfFile:oldBannerCoTagPath];
        NSImage *oldBannerCoTag = [[NSImage alloc] initWithData:oldBannerCoTagData];
        
        NSString *bannerPath = [[NSBundle mainBundle] pathForResource:@"bannerTag" ofType:@"png"];
        NSData *bannerData = [NSData dataWithContentsOfFile:bannerPath];
        NSImage *bannerTag = [[NSImage alloc] initWithData:bannerData];
        
        _bannerTags = @[oldBannerTag, oldBannerCoTag, bannerTag];
    }
    return self;
}

- (NSImage *)detectBannerOnImage:(NSImage *)image {
    for (NSImage *bannerTag in _bannerTags) {
        if ([self doesBannerTag:bannerTag appearInLowerRightCornerOfImage:image]) {
            return bannerTag;
        }
    }
    return nil;
}

- (BOOL)doesBannerTag:(NSImage *)bannerTag appearInLowerRightCornerOfImage:(NSImage *)sourceImage {
    CGFloat sourceImageHeight = [sourceImage size].height;
    CGFloat sourceImageWidth = [sourceImage size].width;
    CGFloat bannerTagHeight = [bannerTag size].height;
    CGFloat bannerTagWidth = [bannerTag size].width;
    NSBitmapImageRep *bannerTagImageRep = [bannerTag representations][0];
    NSBitmapImageRep *sourceImageRep = [sourceImage representations][0];
    if (!sourceImageRep) {
        NSLog(@"Image does not have a representation and is likely not an image");
        return NO;
    }
    
    NSUInteger bytesPerPixel = [sourceImageRep bitsPerPixel] >> 3;
    unsigned char *sourceImageData = [sourceImageRep bitmapData];
    unsigned char *bannerTagData = [bannerTagImageRep bitmapData];
    BOOL matches = true;
    for (int y = 0; y < [bannerTag size].height && matches; ++y) {
        NSUInteger sourceImageY = (sourceImageHeight - bannerTagHeight) + y;
    
        NSUInteger sourceImageStartRowOffset = sourceImageY * [sourceImageRep bytesPerRow];
        NSUInteger bannerTagStartRowOffset = y * [bannerTagImageRep bytesPerRow];
        
        for (int x = 0; x < bannerTagWidth; ++x) {
            NSUInteger sourceImageX = (sourceImageWidth - bannerTagWidth) + x;
            
            NSUInteger sourceImageStartColumnOffset = sourceImageX * bytesPerPixel;
            NSUInteger bannerTagStartColumnOffset = x * bytesPerPixel;
            
            NSUInteger sourceImageOffset = sourceImageStartRowOffset + sourceImageStartColumnOffset;
            NSUInteger bannerTagOffset = bannerTagStartRowOffset + bannerTagStartColumnOffset;
            
            unsigned char *sourceImagePixelStart = (unsigned char *)(sourceImageData + sourceImageOffset);
            unsigned char *bannerTagPixelStart = (unsigned char *)(bannerTagData + bannerTagOffset);
            
            if (_debug) {
                NSLog(@"(%d, %d) vs (%lu, %lu)", x, y, sourceImageX, sourceImageY);
            }
            
            if (![self comparePixel:sourceImagePixelStart withPixel:bannerTagPixelStart length:3]) { // Ignoring the alpha channel
                matches = false;
                break;
            }
            
        }
    }
    return matches;
}

- (BOOL)comparePixel:(unsigned char *)left withPixel:(unsigned char *)right length:(NSUInteger)length {
    NSUInteger difference = 0;
    for (int i = 0; i < length; ++i) {
        int16_t leftValue = *left;
        int16_t rightValue = *right;
        difference += abs(leftValue - rightValue);
        if (_debug) {
            *left = 0xFF;
            *right = 0xFF;
        }
        ++left;
        ++right;
    }
    return difference <= 3 * RGBA_TOLERANCE;
}

@end
