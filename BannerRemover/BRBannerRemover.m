//
//  BRBannerRemover.m
//  BannerRemover
//
//  Created by Zenel Kazushi on 7/17/15.
//  Copyright (c) 2015 Zenel Kazushi. All rights reserved.
//

#import "BRBannerRemover.h"
#import <AppKit/AppKit.h>

@implementation BRBannerRemover

+ (NSImage *)removeBanner:(NSImage *)banner fromImage:(NSImage *)image {
    CGFloat bannerHeight = [[banner representations][0] size].height;
    CGFloat sourceImageWidth = [image size].width;
    CGFloat sourceImageHeight = [image size].height;
    NSRect cropRect = NSMakeRect(0, 0, sourceImageWidth, sourceImageHeight - bannerHeight);
    if (!(int)cropRect.size.width || !(int)cropRect.size.height) {
        NSLog(@"Attempted to crop an image that would result in a 0 size image, not cropping");
        return image;
    }
    
    NSAffineTransform *affineTransform = [NSAffineTransform transform];
    [affineTransform translateXBy:0 yBy:-bannerHeight];
    NSSize canvasSize = [affineTransform transformSize:cropRect.size];
    NSImage *canvas = [[NSImage alloc] initWithSize:canvasSize];
    [canvas lockFocus];
    [affineTransform concat];
    NSImageRep *representation = [image representations][0];
    [representation drawAtPoint:NSZeroPoint];
    [canvas unlockFocus];
    return canvas;
}

@end
