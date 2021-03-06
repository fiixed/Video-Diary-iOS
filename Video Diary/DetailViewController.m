//
//  DetailViewController.m
//  Video Diary
//
//  Created by Andrew Bell on 1/27/15.
//  Copyright (c) 2015 FiixedMobile. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>

#import "DetailViewController.h"
#import "Video.h"
#import "VideoStore.h"
#import "FileStore.h"

@interface DetailViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *commentTextField;
@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (strong, nonatomic) MPMoviePlayerController *videoController;
@property (strong, nonatomic) NSURL *videoURL;
@property (strong, nonatomic) UIImage *tempImage;
@property (strong, nonatomic) NSData *videoData;

@end

@implementation DetailViewController

static NSDateFormatter *dateFormatter;

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
    }
    return self;
}

//- (void)setVideo:(Video *)video
//{
//    _video = video;
//    
//    // Use NSDateFormatter to turn a date into a date string
//    if (!dateFormatter) {
//        dateFormatter = [[NSDateFormatter alloc] init];
//        dateFormatter.dateStyle = NSDateIntervalFormatterMediumStyle;
//        dateFormatter.timeStyle = NSDateFormatterShortStyle;
//    }
//    self.navigationItem.title = [dateFormatter stringFromDate:video.dateCreated];
//    
//}

#pragma mark - App lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *cancelVideo = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                 target:self
                                                                                 action:@selector(delete:)];
    self.navigationItem.rightBarButtonItem = cancelVideo;
    
    self.videoController = [[MPMoviePlayerController alloc] init];
    
    [self.videoController.view setFrame:self.videoView.bounds];
    self.videoController.view.contentMode = UIViewContentModeScaleAspectFit;
    self.videoController.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.videoView addSubview: self.videoController.view];
    
    // The videoController should always match its superview constraints
    NSLayoutConstraint *width =[NSLayoutConstraint
                                constraintWithItem:self.videoController.view
                                attribute:NSLayoutAttributeWidth
                                relatedBy:0
                                toItem:self.videoView
                                attribute:NSLayoutAttributeWidth
                                multiplier:1.0
                                constant:0];
    NSLayoutConstraint *height =[NSLayoutConstraint
                                 constraintWithItem:self.videoController.view
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:0
                                 toItem:self.videoView
                                 attribute:NSLayoutAttributeHeight
                                 multiplier:1.0
                                 constant:0];
    NSLayoutConstraint *top = [NSLayoutConstraint
                               constraintWithItem:self.videoController.view
                               attribute:NSLayoutAttributeTop
                               relatedBy:NSLayoutRelationEqual
                               toItem:self.videoView
                               attribute:NSLayoutAttributeTop
                               multiplier:1.0f
                               constant:0.f];
    NSLayoutConstraint *leading = [NSLayoutConstraint
                                   constraintWithItem:self.videoController.view
                                   attribute:NSLayoutAttributeLeading
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.videoView
                                   attribute:NSLayoutAttributeLeading
                                   multiplier:1.0f
                                   constant:0.f];
    [self.videoView addConstraint:width];
    [self.videoView addConstraint:height];
    [self.videoView addConstraint:top];
    [self.videoView addConstraint:leading];
    
    // Register for thumbnail resquest notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(movieThumbnailLoadComplete:)
                                                 name:MPMoviePlayerThumbnailImageRequestDidFinishNotification
                                               object:self.videoController];
    
    // Register for dynamic type notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateFonts)
                                                 name:UIContentSizeCategoryDidChangeNotification object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = YES;
    
    [self.toolbar setBarStyle:UIBarStyleBlack];
    
    self.commentTextField.delegate = self;
    
    if (self.video) {
        self.commentTextField.text = self.video.comment;
        NSString *fileKey = self.video.fileKey;
        
        // Get the NSString for the video NSURL from the image store
        NSURL *URL = [[FileStore sharedStore] videoURLForKey:fileKey];
        
        self.videoURL = URL;
        
        
        [self.videoController setContentURL:self.videoURL];
        
        [self.videoController prepareToPlay];
        
        
        // Get thumbnail image from self.videoController
        
        [self.videoController requestThumbnailImagesAtTimes:@[@1.0f] timeOption:MPMovieTimeOptionExact];
    }
    
    
    
    
    
    
    
    [self updateFonts];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Clear first responder
    [self.view endEditing:YES];
    
    
    
    // Save changes to video
    self.video.comment = self.commentTextField.text;
    self.video.thumbnail = self.tempImage;
    
    
    
    
    // Only stop video playing if DetailViewController is popped off the stack (keeps playing if self.videoController goes fullscree
    NSArray *viewControllers = self.navigationController.viewControllers;
    if ([viewControllers indexOfObject:self] == NSNotFound) {
        [self.videoController stop];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)takeVideo:(id)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    NSArray *availableTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    
    // Make video the only media type allowed
    if ([availableTypes containsObject:(__bridge NSString *)kUTTypeMovie]) {
        [imagePicker setMediaTypes:@[(__bridge NSString *)kUTTypeMovie]];
    }
    
    // If the device has a camera, take a video, otherwise alert user the device has no camera
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    } else {
        //        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"No video camera!", @"Camera alert title")
                                                       message:NSLocalizedString(@"This device does not have a video camera", @"Camera alert message")
                                                      delegate:nil
                                             cancelButtonTitle:NSLocalizedString(@"OK", @"Camera alert cancel")
                                             otherButtonTitles: nil];
        [alert show];
        
        return;
    }
    
    imagePicker.delegate = self;
    
    // Place image picker on the screen
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    self.video = [[VideoStore sharedStore] createVideo];
    
    self.videoURL = info[UIImagePickerControllerMediaURL];
    
    // Find documents directory
    self.videoData = [NSData dataWithContentsOfURL:self.videoURL];
    
    NSString *tempPath = [[FileStore sharedStore] filePathForKey:self.video.fileKey];
    
    [self.videoData writeToFile:tempPath atomically:NO];
    
    [[NSFileManager defaultManager] removeItemAtPath:[self.videoURL path] error:nil];
    
    self.videoURL = [NSURL fileURLWithPath:tempPath];
    
    [[FileStore sharedStore] setVideoURL:self.videoURL forKey:self.video.fileKey];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


// UIControl resigns first responder

- (IBAction)backgroundTapped:(id)sender
{
    [self.view endEditing:YES];
    
    for (UIView *subview in self.view.subviews) {
        if ([subview hasAmbiguousLayout]) {
            [subview exerciseAmbiguityInLayout];
        }
    }
}

#pragma mark - MPMoviePlayer Notification

- (void)movieThumbnailLoadComplete:(NSNotification *)receive
{
    NSDictionary *receiveInfo = [receive userInfo];
    self.tempImage = [receiveInfo valueForKey:MPMoviePlayerThumbnailImageKey];
    
}

#pragma mark - Dynamic Type

- (void)updateFonts
{
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.commentTextField.font = font;
}

#pragma mark - delete button

- (void)delete:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Delete", @"Delete alert title")
                                                   message:NSLocalizedString(@"Are you sure want to delete this video?", @"Delete alert message")
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Cancel", @"Delete alert cancel")
                                         otherButtonTitles: nil];
    [alert addButtonWithTitle:NSLocalizedString(@"Yes", @"Delete alert yes")];
    [alert show];
    
    
}

#pragma mark - UIAlerView delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        return;
    } else if (buttonIndex == 1) {
        // If the user cancelled, then remoce the BNRItem from the store
        [[VideoStore sharedStore] removeVideo:self.video];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.video.fileKey forKey:@"video.fileKey"];
    
    // Save changes to video
    self.video.comment = self.commentTextField.text;
    self.video.thumbnail = self.tempImage;
    
    // Have store save changes to disk
    [[VideoStore sharedStore] saveChanges];
    
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSString *fileKey = [coder decodeObjectForKey:@"video.fileKey"];
    for (Video *video in [[VideoStore sharedStore] allVideos]) {
        if ([fileKey isEqualToString:video.fileKey]) {
            self.video = video;
            break;
        }
    }
    
    [super decodeRestorableStateWithCoder:coder];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



@end
