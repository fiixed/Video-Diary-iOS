//
//  DetailViewController.m
//  Video Diary
//
//  Created by Andrew Bell on 1/27/15.
//  Copyright (c) 2015 FiixedMobile. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>

#import "DetailViewController.h"
#import "Video.h"
#import "FileStore.h"

@interface DetailViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *commentTextView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@end

@implementation DetailViewController

static NSDateFormatter *dateFormatter;

- (void)setVideo:(Video *)video
{
    _video = video;
    
    // Use NSDateFormatter to turn a date into a date string
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateIntervalFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    self.navigationItem.title = [dateFormatter stringFromDate:video.dateCreated];
}

#pragma mark - App lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    Video *video = self.video;
    
    self.commentTextView.text = video.comment;
    
    NSString *fileKey = self.video.fileKey;
    
    // Get the image for its image key from the image store
    UIImage *imageToDisplay = [[FileStore sharedStore] fileForKey:fileKey];
    
    // Use that image to put on the screen in the imageView
    self.imageView.image = imageToDisplay;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Clear first responder
    [self.view endEditing:YES];
    
    // Save changes to video
    Video *video = self.video;
    video.comment = self.commentTextView.text;
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
    
    // If the device has a camera, take a picture, otherwise just pick from photo library
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    } else {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    imagePicker.delegate = self;
    
    // Place image picker on the screen
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSURL *mediaURL = info[UIImagePickerControllerMediaURL];
    
    if (mediaURL) {
        // Make sure this device supports videos in its photo album
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([mediaURL path])) {
            // Save the video to the photos album
            UISaveVideoAtPathToSavedPhotosAlbum([mediaURL path], nil, nil, nil);
            
            // Remove the video from the temporary directory
//            [[NSFileManager defaultManager] removeItemAtPath:[mediaURL path] error:nil];
        }
    }
    
    
    
    
    
//    // Get picked image from info directory
//    UIImage *image = info[UIImagePickerControllerOriginalImage];
//    
//    // Store the file in the FileStore for this key
//    [[FileStore sharedStore] setFile:image forKey:self.video.fileKey];
//    
//    // Put that image onto the screen in our image view
//    self.imageView.image = image;
    
    // Take the image picker off the screen
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}
- (IBAction)backgroundTapped:(id)sender
{
    [self.view endEditing:YES];
}




@end
