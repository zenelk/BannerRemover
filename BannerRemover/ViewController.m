//
//  ViewController.m
//  BannerRemover
//
//  Created by Zenel Kazushi on 7/16/15.
//  Copyright (c) 2015 Zenel Kazushi. All rights reserved.
//

#import "ViewController.h"
#import "BRBannerRemoverManager.h"

static NSString *ViewControllerFileChooserOptionsCanChooseFiles = @"ViewController_FileChooserOptions_CanChooseFiles";
static NSString *ViewControllerFileChooserOptionsCanChooseDirectories = @"ViewController_FileChooserOptions_CanChooseDirectories";
static NSString *ViewControllerFileChooserOptionsCanChooseMultiple = @"ViewController_FileChooserOptions_CanChooseMultiple";


@interface ViewController() <BRBannerRemoverManagerDelegate>

@property (weak) IBOutlet NSTextField *inputDirectoryLabel;
@property (weak) IBOutlet NSTextField *outputDirectoryLabel;
@property (weak) IBOutlet NSButton *removeBannersButton;
@property (nonatomic, strong) BRBannerRemoverManager *bannerRemoverManager;
@property (nonatomic, strong) NSArray *inputFiles;
@property (nonatomic, strong) NSURL *outputDirectory;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSTextField *progressLabel;
@property (weak) IBOutlet NSButton *debugDetectionCheckbox;
@property (weak) IBOutlet NSButton *chooseInputFilesButton;
@property (weak) IBOutlet NSButton *chooseOutputDirectoryButton;
@property (weak) IBOutlet NSTextField *processingQueuesTextField;
@property (weak) IBOutlet NSTextField *savingQueuesTextField;
@property (weak) IBOutlet NSStepper *processingQueueSizeStepper;
@property (weak) IBOutlet NSStepper *savingQueueSizeStepper;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _bannerRemoverManager = [[BRBannerRemoverManager alloc] initWithDelegate:self];
    [[[self view] window] setInitialFirstResponder:_chooseInputFilesButton];
    [self setProcessingQueueSize:[_bannerRemoverManager numberOfAllowedProcessingOperations]];
    [self setSavingQueueSize:[_bannerRemoverManager numberOfAllowedSavingOperations]];
}

- (IBAction)onChooseInputFilesClicked:(id)sender {
    _inputFiles = [self openFileChooserDialogueWithOptions:@{ ViewControllerFileChooserOptionsCanChooseFiles       : @YES,
                                                                        ViewControllerFileChooserOptionsCanChooseDirectories : @YES,
                                                                        ViewControllerFileChooserOptionsCanChooseMultiple    : @YES }];
    if (_inputFiles) {
        NSString *stringToSet = [_inputFiles count] > 1 ? @"Multiple Selected" : [_inputFiles[0] path];
        [_inputDirectoryLabel setStringValue:stringToSet];
    }
    [self evaluateReady];
}

- (IBAction)onChooseOutputFolderClicked:(id)sender {
    _outputDirectory = [[self openFileChooserDialogueWithOptions:@{ ViewControllerFileChooserOptionsCanChooseDirectories : @YES }] objectAtIndex:0];
    if (_outputDirectory) {
        NSString *stringToSet = [_outputDirectory path];
        [_outputDirectoryLabel setStringValue:stringToSet];
    }
    [self evaluateReady];
}

- (NSArray *)openFileChooserDialogueWithOptions:(NSDictionary *)optionsDictionary {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSNumber *canChooseFiles;
    NSNumber *canChooseDirectories;
    NSNumber *canChooseMultiple;
    if (optionsDictionary) {
        canChooseFiles = [optionsDictionary objectForKey:ViewControllerFileChooserOptionsCanChooseFiles];
        canChooseDirectories = [optionsDictionary objectForKey:ViewControllerFileChooserOptionsCanChooseDirectories];
        canChooseMultiple = [optionsDictionary objectForKey:ViewControllerFileChooserOptionsCanChooseMultiple];
    }
    
    [panel setCanChooseFiles:[canChooseFiles boolValue]];
    [panel setCanChooseDirectories:[canChooseDirectories boolValue]];
    [panel setAllowsMultipleSelection:[canChooseMultiple boolValue]];
    
    NSInteger clicked = [panel runModal];
    
    switch (clicked) {
        case NSFileHandlingPanelOKButton:
            return [panel URLs];
        default:
            return nil;
    }
}

- (void)evaluateReady {
    [_removeBannersButton setEnabled:(_inputFiles && _outputDirectory)];
}

- (IBAction)onRemoveBannersClicked:(id)sender {
    [_removeBannersButton setEnabled:NO];
    [_chooseInputFilesButton setEnabled:NO];
    [_chooseOutputDirectoryButton setEnabled:NO];
    [_progressBar setDoubleValue:0.0];
    [_progressBar setHidden:NO];
    [_progressLabel setStringValue:@"0%"];
    [_progressLabel setHidden:NO];
    [_bannerRemoverManager setDebugDetection:[_debugDetectionCheckbox state] == NSOnState];
    [_bannerRemoverManager removeBannersOnURLs:_inputFiles withOutputDirectory:_outputDirectory];
}

- (void)setProcessingQueueSize:(NSUInteger)size {
    if (size > [_bannerRemoverManager maxNumberOfAllowedProcessingOperations]) {
        size = [_bannerRemoverManager maxNumberOfAllowedProcessingOperations];
    }
    [_processingQueuesTextField setStringValue:[NSString stringWithFormat:@"%lu", size]];
    [_processingQueueSizeStepper setIntegerValue:size];
    [_bannerRemoverManager setNumberOfAllowedProcessingOperations:size];
}

- (void)setSavingQueueSize:(NSUInteger)size {
    if (size > [_bannerRemoverManager maxNumberOfAllowedSavingOperations]) {
        size = [_bannerRemoverManager maxNumberOfAllowedSavingOperations];
    }
    [_savingQueuesTextField setStringValue:[NSString stringWithFormat:@"%lu", size]];
    [_savingQueueSizeStepper setIntegerValue:size];
    [_bannerRemoverManager setNumberOfAllowedSavingOperations:size];
}

- (IBAction)onProcessingQueuesSizeChanged:(id)sender {
    [self setProcessingQueueSize:[sender integerValue]];
}

- (IBAction)onSavingQueuesSizeChanged:(id)sender {
    [self setSavingQueueSize:[sender integerValue]];
}

#pragma mark - BRBannerRemoverManagerDelegate Implementation

- (void)bannerRemoverManager:(BRBannerRemoverManager *)manager didFinishProcessSuccessfully:(BOOL)success withError:(NSError *)error {
    [_chooseInputFilesButton setEnabled:YES];
    [_chooseOutputDirectoryButton setEnabled:YES];
    [_removeBannersButton setEnabled:YES];
    [_progressBar setHidden:YES];
    [_progressLabel setHidden:YES];
}

- (void)bannerRemoverManager:(BRBannerRemoverManager *)manager didUpdateProgress:(float)progress {
    [_progressBar setDoubleValue:progress];
    [_progressLabel setStringValue:[NSString stringWithFormat:@"%.02f%%", progress * 100]];
}

@end