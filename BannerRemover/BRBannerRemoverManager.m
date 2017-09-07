//
//  BRBannerRemoverManager.m
//  BannerRemover
//
//  Created by Zenel Kazushi on 7/16/15.
//  Copyright (c) 2015 Zenel Kazushi. All rights reserved.
//

#import "BRBannerRemoverManager.h"
#import "BRBannerDetector.h"
#import <AppKit/AppKit.h>
#import "BRBannerRemover.h"
#import "BRBannerRemoverManagerErrorFactory.h"
#import "BRFileListConstructor.h"

static NSUInteger MAX_PROCESSING_OPERATIONS_ALLOWED = 5;
static NSUInteger MAX_SAVING_OPERATIONS_ALLOWED = 10;

@interface BRBannerRemoverManager()

@property (nonatomic, strong) BRBannerDetector *detector;
@property (nonatomic, strong) BRBannerRemoverManagerCompletionHandler handler;
@property (nonatomic) NSUInteger totalOperations;
@property (nonatomic) NSUInteger operationsRemaining;
@property (nonatomic, strong) id<BRBannerRemoverManagerDelegate> delegate;
@property (nonatomic, strong) NSOperationQueue *processingOperationQueue;
@property (nonatomic, strong) NSOperationQueue *savingOperationQueue;

@end

@implementation BRBannerRemoverManager

- (instancetype)initWithDelegate:(id<BRBannerRemoverManagerDelegate>)delegate {
    if (self = [super init]) {
        if (!delegate) {
            @throw [NSException exceptionWithName:@"APIMisuseException" reason:@"Parameter \"Delegate\" cannot be null" userInfo:nil];
        }
        _delegate = delegate;
        _processingOperationQueue = [[NSOperationQueue alloc] init];
        _savingOperationQueue = [[NSOperationQueue alloc] init];
        [self setNumberOfAllowedProcessingOperations:MAX_PROCESSING_OPERATIONS_ALLOWED];
        [self setNumberOfAllowedSavingOperations:MAX_SAVING_OPERATIONS_ALLOWED];
        _detector = [[BRBannerDetector alloc] init];
    }
    return self;
}

- (void)removeBannersOnURLs:(NSArray *)URLs withOutputDirectory:(NSURL *)outputDirectory {
    NSError *error;
    
    NSLog(@"Starting up, performing startup checks...");
    BOOL success = [self performStartupChecks:URLs outputDirectory:outputDirectory error:&error];
    if (!success) {
        NSLog(@"One or more startup checks failed. Stopping...");
        [self finish:error];
        return;
    }
    
    NSLog(@"Startup checks passed, getting file list...");
    NSDictionary *fileList = [BRFileListConstructor constructFileListFromURLs:URLs outputDirectory:outputDirectory error:&error];
    if (!fileList) {
        NSLog(@"Could not get file list. Stopping...");
        [self finish:error];
        return;
    }
    NSLog(@"File list retrieved successfully, processing all files...");
    _totalOperations = [fileList count];
    _operationsRemaining = _totalOperations;
    for (NSURL *inputURL in [fileList allKeys]) {
        [_processingOperationQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
            if (_debugDetection) {
                NSLog(@"Starting on file %@", [inputURL path]);
            }
            [self performOperationWithInputURL:inputURL outputURL:[fileList objectForKey:inputURL]];
        }]];
    }
}

- (BOOL)performStartupChecks:(NSArray *)URLs outputDirectory:(NSURL *)outputDirectory error:(out NSError **)error {
    if (!URLs) {
        if (error) {
            *error = [BRBannerRemoverManagerErrorFactory errorFromErrorCode:BRBannerRemoverManagerErrorCodeNoInputFiles];
        }
        NSLog(@"No input files provided!");
        return NO;
    }
    
    if (!outputDirectory) {
        if (error) {
            *error = [BRBannerRemoverManagerErrorFactory errorFromErrorCode:BRBannerRemoverManagerErrorCodeNoOutputDirectory];
        }
        NSLog(@"No output directory provided!");
        return NO;
    }
    
    NSNumber *isDirectory;
    BOOL success = [outputDirectory getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:error];
    if (!success) {
        NSLog(@"Could not determine if output is a directory");
        return NO;
    }
    if (![isDirectory boolValue]) {
        *error = [BRBannerRemoverManagerErrorFactory errorFromErrorCode:BRBannerRemoverManagerErrorCodeOutputIsNotADirectory];
        NSLog(@"Selected output is not a directory");
        return NO;
    }
    return YES;
}

- (void)performOperationWithInputURL:(NSURL *)inputURL outputURL:(NSURL *)outputURL {
    @autoreleasepool {
        NSData *imageData = [NSData dataWithContentsOfURL:inputURL];
        char c;
        [imageData getBytes:&c length:1];
        if (c == 0x47) {
            NSLog(@"%@ is a gif and will be left untouched", [inputURL path]);
        }
        else {
            NSImage *image = [[NSImage alloc] initWithData:imageData];
            NSImage *bannerMatch = [_detector detectBannerOnImage:image];
            
            if (bannerMatch) {
                NSLog(@"Image at %@ has a banner!", [inputURL path]);
                image = [BRBannerRemover removeBanner:bannerMatch fromImage:image];
            }
            
            imageData = [self generateDataForImage:image];
        }
        [_savingOperationQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
            [self performCleanupWithImageData:imageData outputPath:outputURL];
        }]];
    }
}

- (void)performCleanupWithImageData:(NSData *)imageData outputPath:(NSURL *)outputURL {
    NSString *correctExtension = [self getCorrectExtensionForImageData:imageData];
    if (!correctExtension) {
        correctExtension = [[outputURL path] pathExtension];
    }
    NSString *editedOutputPath = [[[outputURL path] stringByDeletingPathExtension] stringByAppendingPathExtension:correctExtension];
    [self writeImageData:imageData toOutputPath:editedOutputPath];
    
    [self markOperationDone];
    if ([self checkForDone]) {
        [self finish:nil];
    }
}

- (NSString *)getCorrectExtensionForImageData:(NSData *)imageData {
    uint8_t c;
    [imageData getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"jpg";
        case 0x89:
            return @"png";
        case 0x47:
            return @"gif";
        case 0x49:
        case 0x4D:
            return @"tiff";
    }
    return nil;
}

- (NSData *)generateDataForImage:(NSImage *)image {
    NSBitmapImageRep *bitmapRepresentation = [image representations][0];
    if (![bitmapRepresentation respondsToSelector:@selector(representationUsingType:properties:)]) {
            bitmapRepresentation = [[NSBitmapImageRep alloc]
                                    initWithBitmapDataPlanes:NULL
                                    pixelsWide:image.size.width
                                    pixelsHigh:image.size.height
                                    bitsPerSample:8
                                    samplesPerPixel:4
                                    hasAlpha:YES
                                    isPlanar:NO
                                    colorSpaceName:[bitmapRepresentation colorSpaceName]
                                    bytesPerRow:0
                                    bitsPerPixel:0];
            bitmapRepresentation.size = image.size;
            
            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:
            [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmapRepresentation]];
            
            [image drawAtPoint:NSMakePoint(0, 0)
                     fromRect:NSZeroRect
                    operation:NSCompositeSourceOver
                     fraction:1.0];
            
            [NSGraphicsContext restoreGraphicsState];
    }
    return [bitmapRepresentation representationUsingType:NSPNGFileType properties:nil];
}

- (void)writeImageData:(NSData *)imageData toOutputPath:(NSString *)outputPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *containingOutputDirectory = [outputPath stringByDeletingLastPathComponent];
    NSError *error;
    [fileManager createDirectoryAtPath:containingOutputDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    [imageData writeToFile:outputPath atomically:YES];
}

- (void)markOperationDone {
    float progress;
    @synchronized (self) {
        --_operationsRemaining;
        float completedOperations = _totalOperations - _operationsRemaining;
        progress = completedOperations / _totalOperations;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_delegate bannerRemoverManager:self didUpdateProgress:progress];
    });
}

- (BOOL)checkForDone {
    NSUInteger remaining;
    @synchronized (self) {
        remaining = _operationsRemaining;
    }
    return remaining < 1;
}

- (void)finish:(NSError *)error {
    [_delegate bannerRemoverManager:self didFinishProcessSuccessfully:!error withError:error];
}

- (void)setDebugDetection:(BOOL)debugDetection {
    _debugDetection = debugDetection;
    [_detector setDebug:_debugDetection];
}

- (NSUInteger)maxNumberOfAllowedProcessingOperations {
    return MAX_PROCESSING_OPERATIONS_ALLOWED;
}

- (NSUInteger)maxNumberOfAllowedSavingOperations {
    return MAX_SAVING_OPERATIONS_ALLOWED;
}

- (void)setNumberOfAllowedProcessingOperations:(NSUInteger)numberOfAllowedProcessingOperations {
    if (numberOfAllowedProcessingOperations > [self maxNumberOfAllowedProcessingOperations]) {
        NSLog(@"Cannot set number of allowed processing operations higher than the max (%lu)", [self maxNumberOfAllowedProcessingOperations]);
        return;
    }
    [_processingOperationQueue setMaxConcurrentOperationCount:numberOfAllowedProcessingOperations];
}

- (void)setNumberOfAllowedSavingOperations:(NSUInteger)numberOfAllowedSavingOperations {
    if (numberOfAllowedSavingOperations > [self maxNumberOfAllowedSavingOperations]) {
        NSLog(@"Cannot set number of allowed saving operatins higher than the max (%lu)", [self maxNumberOfAllowedSavingOperations]);
        return;
    }
    [_savingOperationQueue setMaxConcurrentOperationCount:numberOfAllowedSavingOperations];
}

- (NSUInteger)numberOfAllowedProcessingOperations {
    return [_processingOperationQueue maxConcurrentOperationCount];
}

- (NSUInteger)numberOfAllowedSavingOperations {
    return [_savingOperationQueue maxConcurrentOperationCount];
}

@end
