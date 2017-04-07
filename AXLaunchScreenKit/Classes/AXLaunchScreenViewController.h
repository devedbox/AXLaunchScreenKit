//
//  AXLaunchScreenViewController.h
//  ExchangeStreet
//
//  Created by devedbox on 2016/11/13.
//  Copyright © 2016年 jiangyou. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(int64_t, AXLaunchScreenViewControllerMode) {
    AXLaunchScreenViewControllerLaunchPage,
    AXLaunchScreenViewControllerLauncher
};

@class AXLaunchScreenViewController;

@protocol AXLaunchScreenViewControllerDelegate <NSObject>
@optional
/// Launch screen view controller will show.
- (void)launcherControllerWillShow:(AXLaunchScreenViewController *)launcher;
/// Launch screen view controller did show.
- (void)launcherControllerDidShow:(AXLaunchScreenViewController *)launcher;
/// Launch screen view controller will hide.
- (void)launcherControllerWillHide:(AXLaunchScreenViewController *)launcher;
/// Launch screen view controller did hide.
- (void)launcherControllerDidHide:(AXLaunchScreenViewController *)launcher;
/// Launch screen view controller did hide.
- (void)launcherControllerDidReviewPages:(AXLaunchScreenViewController *)launcher;
/// Launch screen view controller did hide.
- (void)launcherControllerDidInteractiveWithImage:(AXLaunchScreenViewController *)launcher;
/// Launch screen view controller did hide.
- (void)launcherControllerDidPreview:(AXLaunchScreenViewController *)launcher;
@end

@interface AXLaunchScreenViewController : UIViewController
/// Delegate.
@property(assign, nonatomic) id<AXLaunchScreenViewControllerDelegate> delegate;
/// Durantion.
@property(assign, nonatomic) NSTimeInterval duration;
/// Mode of AXLaunchScreenViewControllerMode.
@property(assign, nonatomic) AXLaunchScreenViewControllerMode mode;
/// Page images for mode LaunchPage.
@property(copy, nonatomic) NSArray<UIImage *> *pageImages;
/// Image url.
@property(copy, nonatomic) NSString *urlForImage;
/// Context.
@property(strong, nonatomic) id context;
@end

@interface AXPreviewingFlowLayout : UICollectionViewFlowLayout
@end
