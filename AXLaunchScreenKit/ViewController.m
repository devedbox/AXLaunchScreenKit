//
//  ViewController.m
//  AXLaunchScreenKit
//
//  Created by devedbox on 2017/4/7.
//  Copyright © 2017年 devedbox. All rights reserved.
//

#import "ViewController.h"
#import "AXLaunchScreenViewController.h"
#import <AXResponderSchemaKit/AXResponderSchemaKit.h>

@interface ViewController () <AXLaunchScreenViewControllerDelegate>

@end
static NSString *const kESLauncherPageDidShowKey = @"kESLauncherPageDidShowKey";
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)show:(id)sender {
    NSDictionary *param = @{};
    AXLaunchScreenViewController *vc = [AXLaunchScreenViewController viewControllerForSchemaWithParams:&param];
    vc.delegate = self;
    vc.hidesOnScrollingAwayLastPage = YES;
    vc.showsPageControl = YES;
    vc.showsSkippingElements = NO;
    
    BOOL didReviewPages = [[NSUserDefaults standardUserDefaults] boolForKey:kESLauncherPageDidShowKey];
    BOOL shouldAddLauncher = YES;
    didReviewPages = YES;
    
    if (!didReviewPages) {
        vc.mode = AXLaunchScreenViewControllerLaunchPage;
        vc.pageImages = @[[UIImage imageNamed:@"launch1"], [UIImage imageNamed:@"launch2"], [UIImage imageNamed:@"launch3"], [UIImage imageNamed:@"launch4"], [UIImage imageNamed:@"launch5"]];
        vc.duration = 20;
    } else {
        vc.mode = AXLaunchScreenViewControllerLauncher;
        vc.urlForImage = @"https://camo.githubusercontent.com/42bbb3315ca1ed1edc42dd3cc7f451c3e78e2bad/687474703a2f2f7777332e73696e61696d672e636e2f6c617267652f6432323937626432677731663577706e69657a7170673230396f3068343471722e676966";
        vc.duration = 20.0;
    }
    if (!shouldAddLauncher) return;
    
    [self.view addSubview:vc.view];
    [self addChildViewController:vc];
    [vc beginAppearanceTransition:YES animated:YES];
    [vc didMoveToParentViewController:self];
    [vc endAppearanceTransition];
}

#pragma mark - AXLaunchScreenViewControllerDelegate
- (void)launcherControllerWillShow:(AXLaunchScreenViewController *)launcher {
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)launcherControllerDidHide:(AXLaunchScreenViewController *)launcher {
    [UIView animateWithDuration:0.25 animations:^{
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}

- (void)launcherControllerDidReviewPages:(AXLaunchScreenViewController *)launcher {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kESLauncherPageDidShowKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)launcherControllerDidInteractiveWithImage:(AXLaunchScreenViewController *)launcher {
//    [kAXPracticalHUD showSimpleInView:self.view text:@"加载中..." detail:nil configuration:AXPracticalHUDBreachedLockBackground()];
}

- (void)launcherControllerDidPreview:(AXLaunchScreenViewController *)launcher {
//    [kAXPracticalHUD hide:YES afterDelay:kAXHudViewGraceTimeinternal completion:^{
//        ESFlashScreenObject *flashScreen = launcher.context;
//        switch (flashScreen.type) {
//            case ESBannerTypePeriodProduct:
//                if (flashScreen.referenceId.length > 0) [kAXResponderSchemaManager openURL:[NSURL URLWithString:[NSString stringWithFormat:@"exchangestreet://viewcontroller/productdetail?productId=%@&force=1&lastest=1", flashScreen.referenceId]]];
//                break;
//            case ESBannerTypeNormalProduct:
//                if (flashScreen.referenceId.length > 0) [kAXResponderSchemaManager openURL:[NSURL URLWithString:[NSString stringWithFormat:@"exchangestreet://viewcontroller/exchange?productId=%@&force=1&lastest=1", flashScreen.referenceId]]];
//                break;
//            case ESBannerTypeLink:
//            default:
//                if (flashScreen.url.length > 0) [kAXResponderSchemaManager openURL:[NSURL URLWithString:[NSString stringWithFormat:@"exchangestreet://viewcontroller/esweb?url=%@", [flashScreen.url?:@"" encodeToPercentEscapeString]]]];
//                break;
//        }
//    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
