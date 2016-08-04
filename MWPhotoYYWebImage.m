//
//  MWPhotoYYWebImage.m
//
//  Created by LinXi on 6/1/16.
//  Copyright © 2016 All rights reserved.
//

#import "MWPhotoYYWebImage.h"
#import "YYWebImageManager.h"

@interface MWPhoto ()

- (void)imageLoadingComplete;
- (void)cancelImageRequest;
- (void)cancelVideoRequest;

@end

@interface MWPhotoYYWebImage ()

@property(nonatomic, strong) YYWebImageOperation *imageDownloadOperation;

@end

@implementation MWPhotoYYWebImage

+ (MWPhoto *)photoWithImage:(UIImage *)image {
    return [[MWPhotoYYWebImage alloc] initWithImage:image];
}

+ (MWPhoto *)photoWithURL:(NSURL *)url {
    return [[MWPhotoYYWebImage alloc] initWithURL:url];
}

+ (MWPhoto *)photoWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize {
    return [[MWPhotoYYWebImage alloc] initWithAsset:asset targetSize:targetSize];
}

+ (MWPhoto *)videoWithURL:(NSURL *)url {
    return [[MWPhotoYYWebImage alloc] initWithVideoURL:url];
}

// Load from local file
- (void)_performLoadUnderlyingImageAndNotifyWithWebURL:(NSURL *)url {
    @try {
        YYWebImageManager *manager = [YYWebImageManager sharedManager];
        _imageDownloadOperation = [manager requestImageWithURL:url options:YYWebImageOptionShowNetworkActivity progress:^(NSInteger receivedSize, NSInteger expectedSize) {
          if (expectedSize > 0) {
              float progress = receivedSize / (float)expectedSize;
              NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     [NSNumber numberWithFloat:progress], @"progress",
                                                     self, @"photo", nil];
              [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_PROGRESS_NOTIFICATION object:dict];
          }
        }
            transform:nil
            completion:^(UIImage *_Nullable image, NSURL *_Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError *_Nullable error) {
              if (error) {
                  MWLog(@"SDWebImage failed to download image: %@", error);
              }
              _imageDownloadOperation = nil;
              self.underlyingImage = image;
              dispatch_async(dispatch_get_main_queue(), ^{
                [self imageLoadingComplete];
              });
            }];
    } @catch (NSException *e) {
        MWLog(@"Photo from web: %@", e);
        _imageDownloadOperation = nil;
        [self imageLoadingComplete];
    }
}

- (void)cancelAnyLoading {
    if (_imageDownloadOperation != nil) {
        [_imageDownloadOperation cancel];
        [self setValue:@(NO) forKey:@"_loadingInProgress"];
    }
    [self cancelImageRequest];
    [self cancelVideoRequest];
}

@end
