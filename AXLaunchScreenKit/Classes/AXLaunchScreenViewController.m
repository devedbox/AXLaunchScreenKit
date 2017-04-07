//
//  AXLaunchScreenViewController.m
//  AXLaunchScreenKit
//
//  Created by devedbox on 2016/11/13.
//  Copyright © 2016年 jiangyou. All rights reserved.
//

#import "AXLaunchScreenViewController.h"
#import <AXTransparentNavigationBar/UINavigationBar+Transparent.h>
#import <objc/runtime.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/SDWebImageManager.h>
#import <AXResponderSchemaKit/AXResponderSchemaKit.h>

typedef NS_ENUM(int64_t, AXLaunchScreenShowType) {
    AXLaunchScreenShowByPresented,
    AXLaunchScreenShowByPresentedInNavigationController,
    AXLaunchScreenShowByPushed,
    AXLaunchScreenShowByAdded,
    AXLaunchScreenShowByAddedInNavigationController
};

@interface AXLaunchScreenViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
{
    /// Show type.
    AXLaunchScreenShowType _showType;
    /// View did appear.
    BOOL _viewDidAppear;
    /// Interactive form image.
    BOOL _interactiveFromImage;
    
    BOOL _viewControllerBasedStatusBarAppearance;
    
    NSArray<NSLayoutConstraint *> *_contraintsOfPageControl;
}
/// Launch page collection view.
@property(strong, nonatomic) IBOutlet UICollectionView *collectionView;
/// Launcher image view.
@property(strong, nonatomic) IBOutlet UIImageView *imageView;
/// Skip button item.
@property(strong, nonatomic) IBOutlet UIButton *skipButonItem;
/// Dismiss button item.
@property(strong, nonatomic) IBOutlet UIButton *dismissButtonItem;
/// Time intervel labal.
@property(strong, nonatomic) IBOutlet UILabel *countingLabel;
/// Page control.
@property(strong, nonatomic) IBOutlet UIPageControl *pageControl;
@end

#define kAXLaunchSkipButtonSize CGSizeMake(100, 38)
#define kAXLaunchDismissButtonSize CGSizeMake(172, 53)

typedef void(^AXSDWebImageCompletionBlock)(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL);
static AXSDWebImageCompletionBlock AXSDWebImageCompletionHandler() {
    return ^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (!error && image) {
            if (cacheType != SDImageCacheTypeDisk) {
                [[SDWebImageManager sharedManager] saveImageToCache:image forURL:imageURL];
            }
        }
    };
}

@implementation AXLaunchScreenViewController
#pragma mark - Schema.
+ (Class)classForSchemaIdentifier:(NSString *)schemaIdentifier {
    if ([[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'launchscreen'"] evaluateWithObject:schemaIdentifier]) {
        return self.class;
    }
    return [super classForSchemaIdentifier:schemaIdentifier];
}

+ (instancetype)viewControllerForSchemaWithParams:(NSDictionary *__autoreleasing  _Nullable *)params {
    AXLaunchScreenViewController *viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:NSBundle.mainBundle] instantiateViewControllerWithIdentifier:[NSString stringWithFormat:@"k%@Identifier", NSStringFromClass(self.class)]];
    viewController.duration = [(*params)[@"duration"] doubleValue];
    return viewController;
}

#pragma mark - Override.
- (instancetype)init {
    if (self = [super init]) {
        [self initializer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initializer];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self initializer];
    }
    return self;
}

- (void)initializer {
    _showsPageControl = YES;
    _showsSkippingElements = YES;
    
    _viewControllerBasedStatusBarAppearance = [[NSBundle.mainBundle infoDictionary][@"UIViewControllerBasedStatusBarAppearance"] boolValue];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Hide the navigation bar if needed.
    if (self.navigationController != nil) {
        [self.navigationController.navigationBar setTransparent:YES];
    }
    
    [self _updateViewsForCurrentMode];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    _collectionView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Sut up show types.
    [self _setupShowTypeWhileViewWillAppear];
    
    if ([_delegate respondsToSelector:@selector(launcherControllerWillShow:)]) {
        [_delegate launcherControllerWillShow:self];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _viewDidAppear = YES;
    [self performSelector:@selector(_hideViewController) withObject:nil afterDelay:_duration];
    [[NSRunLoop currentRunLoop] addTimer:[NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES] forMode:NSRunLoopCommonModes];
    
    if (_viewControllerBasedStatusBarAppearance) {
        [self setNeedsStatusBarAppearanceUpdate];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [UIApplication.sharedApplication setStatusBarHidden:YES animated:YES];
#pragma clang diagnostic pop
    }
    
    if ([_delegate respondsToSelector:@selector(launcherControllerDidShow:)]) {
        [_delegate launcherControllerDidShow:self];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([_delegate respondsToSelector:@selector(launcherControllerWillHide:)]) {
        [_delegate launcherControllerWillHide:self];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

#pragma mark - Setter.
- (void)setMode:(AXLaunchScreenViewControllerMode)mode {
    _mode = mode;
    
    if (_viewDidAppear) [self _updateViewsForCurrentMode];
}

- (void)setPageImages:(NSArray<UIImage *> *)pageImages {
    _pageImages = [pageImages copy];
    
    if (_mode == AXLaunchScreenViewControllerLaunchPage && _viewDidAppear) {
        [_collectionView reloadData];
    }
    
    [self _setupPageControl];
}

- (void)setShowsPageControl:(BOOL)showsPageControl {
    _showsPageControl = showsPageControl;
    
    if (self.viewLoaded) [self _setupPageControl];
}

- (void)setShowsSkippingElements:(BOOL)showsSkippingElements {
    _showsSkippingElements = showsSkippingElements;
    
    [self _updateViewsForCurrentMode];
}

#pragma mark - Getters
- (UICollectionView *)collectionView {
    if (_collectionView) return _collectionView;
    AXPreviewingFlowLayout *layout = [[AXPreviewingFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.backgroundColor = [UIColor blackColor];
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.bounces = YES;
    _collectionView.alwaysBounceHorizontal = YES;
    _collectionView.pagingEnabled = YES;
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"_cell"];
    return _collectionView;
}

- (UIImageView *)imageView {
    if (_imageView) return _imageView;
    _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _imageView.backgroundColor = [UIColor clearColor];
    _imageView.clipsToBounds = YES;
    _imageView.userInteractionEnabled = YES;
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [_imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImagePreview:)]];
    return _imageView;
}

- (UIButton *)skipButonItem {
    if (_skipButonItem) return _skipButonItem;
    _skipButonItem = [UIButton buttonWithType:UIButtonTypeSystem];
    _skipButonItem.titleLabel.font = [UIFont systemFontOfSize:14];
    _skipButonItem.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    _skipButonItem.tintColor = [UIColor whiteColor];
    [_skipButonItem addTarget:self action:@selector(handleSkip:) forControlEvents:UIControlEventTouchUpInside];
    [_skipButonItem setTitle:@"" forState:UIControlStateNormal];
    [_skipButonItem setFrame:CGRectMake(CGRectGetWidth(self.view.frame)-100-15, CGRectGetHeight(self.view.frame)-44-25, 100, 44)];
    _skipButonItem.layer.cornerRadius = 2.0;
    _skipButonItem.layer.masksToBounds = YES;
    _skipButonItem.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    _skipButonItem.clipsToBounds = YES;
    return _skipButonItem;
}

- (UILabel *)countingLabel {
    if (_countingLabel) return _countingLabel;
    _countingLabel = [UILabel new];
    _countingLabel.textColor = [UIColor whiteColor];
    _countingLabel.backgroundColor = [UIColor clearColor];
    _countingLabel.font = [UIFont systemFontOfSize:14];
    _countingLabel.textAlignment = NSTextAlignmentCenter;
    if (_duration>0) {
        _countingLabel.text = [NSString stringWithFormat:@"跳过 %@秒 >>", @((int)_duration)];
    } else {
        _countingLabel.text = [NSString stringWithFormat:@"跳过 >>"];
    }
    return _countingLabel;
}

- (UIButton *)dismissButtonItem {
    if (_dismissButtonItem) return _dismissButtonItem;
    _dismissButtonItem = [UIButton buttonWithType:UIButtonTypeSystem];
    _dismissButtonItem.titleLabel.font = [UIFont systemFontOfSize:14];
    _dismissButtonItem.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    _dismissButtonItem.tintColor = [UIColor whiteColor];
    [_dismissButtonItem addTarget:self action:@selector(handleDismiss:) forControlEvents:UIControlEventTouchUpInside];
    [_dismissButtonItem setTitle:@"开启" forState:UIControlStateNormal];
    _dismissButtonItem.layer.cornerRadius = 2.0;
    _dismissButtonItem.layer.masksToBounds = YES;
    _dismissButtonItem.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    return _dismissButtonItem;
}

- (UIPageControl *)pageControl {
    if (_pageControl) return _pageControl;
    _pageControl = [UIPageControl new];
    _pageControl.numberOfPages = _pageImages.count;
    return _pageControl;
}

#pragma mark - Actions.
- (IBAction)handleImagePreview:(UITapGestureRecognizer *)sender {
    if (!_allowsImageInteraction) return;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_hideViewController) object:nil];
    _interactiveFromImage = YES;
    [self _hideViewController];
    
    if ([_delegate respondsToSelector:@selector(launcherControllerDidInteractiveWithImage:)]) {
        [_delegate launcherControllerDidInteractiveWithImage:self];
    }
}

- (IBAction)handleSkip:(UIButton *)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_hideViewController) object:nil];
    [self _hideViewController];
    
    if (_mode == AXLaunchScreenViewControllerLaunchPage && [_delegate respondsToSelector:@selector(launcherControllerDidReviewPages:)]) {
        [_delegate launcherControllerDidReviewPages:self];
    }
}

- (IBAction)handleDismiss:(UIButton *)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_hideViewController) object:nil];
    [self _hideViewController];
    
    if (_mode == AXLaunchScreenViewControllerLaunchPage && [_delegate respondsToSelector:@selector(launcherControllerDidReviewPages:)]) {
        [_delegate launcherControllerDidReviewPages:self];
    }
}

- (void)handleTimer:(NSTimer *)timer {
    _duration = MAX(--_duration, 0);
    if (_duration == 0) {
        [timer invalidate];
        timer = nil;
        [_countingLabel setText:@"跳过>>"];
    } else {
        [_countingLabel setText:[NSString stringWithFormat:@"跳过 %@秒 >>", @((int)_duration)]];
    }
}

#pragma mark - AXCollectionView Definition

#define kAXCollectionViewItemLayoutCount 1
#define kAXCollectionViewItemTopEdge 0
#define kAXCollectionViewItemLeftEdge 0
#define kAXCollectionViewItemBottomEdge 0
#define kAXCollectionViewItemRightEdge 0
#define kAXCollectionViewInset (UIEdgeInsetsMake(kAXCollectionViewItemTopEdge, kAXCollectionViewItemLeftEdge, kAXCollectionViewItemBottomEdge, kAXCollectionViewItemRightEdge))
#define kAXCollectionViewItemMinimumLineSpacing 0
#define kAXCollectionViewItemMinimumInteritemSpacing 0

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _pageImages.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"_cell" forIndexPath:indexPath];
    UIImageView *imageView;
    for (UIView *view in cell.contentView.subviews) {
        if ([view isKindOfClass:[UIImageView class]]) {
            imageView = (UIImageView*)view;
        }
    }
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithFrame:cell.bounds];
        imageView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:imageView];
    }
    UIImage *image = _pageImages[indexPath.item];
    if ([image isKindOfClass:[UIImage class]]) {
        imageView.image = image;
    }
    return cell;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint contentOffset = scrollView.contentOffset;
    NSInteger index = contentOffset.x/scrollView.bounds.size.width;
    
    if (_showsPageControl) [_pageControl setCurrentPage:index];
    
    if (index == _pageImages.count-1) {
        if (_dismissButtonItem.hidden) {
            _dismissButtonItem.alpha = 0.0;
            _dismissButtonItem.hidden = NO;
            [UIView animateWithDuration:0.25 animations:^{
                _dismissButtonItem.alpha = 1.0;
            } completion:NULL];
        }
    } else {
        if (!_dismissButtonItem.hidden) {
            [UIView animateWithDuration:0.25 animations:^{
                _dismissButtonItem.alpha = 0.0;
            } completion:^(BOOL finished) {
                if (finished) {
                    _dismissButtonItem.hidden = YES;
                }
            }];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGPoint contentOffset = scrollView.contentOffset;
    NSUInteger index = contentOffset.x / scrollView.bounds.size.width;
    
    if (index == _pageImages.count - 1) {
        CGFloat offset = (NSInteger)contentOffset.x%(NSInteger)scrollView.bounds.size.width;
        if (offset > 10 && _hidesOnScrollingAwayLastPage && _mode == AXLaunchScreenViewControllerLaunchPage) {
            [self _hideViewController];
        }
        // NSLog(@"Offset: %@", @(offset));
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return collectionView.bounds.size;
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return kAXCollectionViewInset;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return kAXCollectionViewItemMinimumLineSpacing;
}
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return kAXCollectionViewItemMinimumInteritemSpacing;
}

#pragma mark - Private.
- (void)_setupShowTypeWhileViewWillAppear {
    if (self.navigationController != nil) {
        if (self.navigationController.isBeingPresented) {
            _showType = AXLaunchScreenShowByPresentedInNavigationController;
        } else if (self.navigationController.viewControllers.count > 1 && self.navigationController.topViewController == self) {
            _showType = AXLaunchScreenShowByPushed;
        } else {
            _showType = AXLaunchScreenShowByAddedInNavigationController;
        }
    } else {
        if (self.isBeingPresented) {
            _showType = AXLaunchScreenShowByPresented;
        } else {
            _showType = AXLaunchScreenShowByAdded;
        }
    }
}

- (void)_hideViewController {
    switch (_showType) {
        case AXLaunchScreenShowByPresented:
            [self _transitionPlacehodlerSanpshotInKeyWindowByAnimatedWithView:self.view];
            [self dismissViewControllerAnimated:NO completion:NULL];
            break;
        case AXLaunchScreenShowByPushed:
            [self _transitionPlacehodlerSanpshotInKeyWindowByAnimatedWithView:self.view];
            [self.navigationController popViewControllerAnimated:NO];
            break;
        case AXLaunchScreenShowByPresentedInNavigationController:
            [self _transitionPlacehodlerSanpshotInKeyWindowByAnimatedWithView:self.navigationController.view];
            [self.navigationController dismissViewControllerAnimated:NO completion:NULL];
            break;
        case AXLaunchScreenShowByAddedInNavigationController:
            [self _hideViewControllerWithInstance:self.navigationController];
            break;
        default:
            [self _hideViewControllerWithInstance:self];
            break;
    }
}

- (void)_hideViewControllerWithInstance:(UIViewController *)instance {
    [instance willMoveToParentViewController:nil];
    [UIView animateWithDuration:0.35 animations:^{
        instance.view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if (finished) {
            [instance.view removeFromSuperview];
            [instance removeFromParentViewController];
            [instance didMoveToParentViewController:nil];
            if (_interactiveFromImage) {
                if ([_delegate respondsToSelector:@selector(launcherControllerDidPreview:)]) {
                    [_delegate launcherControllerDidPreview:self];
                }
            }
            if ([_delegate respondsToSelector:@selector(launcherControllerDidHide:)]) {
                [_delegate launcherControllerDidHide:self];
            }
        }
    }];
}

- (void)_transitionPlacehodlerSanpshotInKeyWindowByAnimatedWithView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 2);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:view.bounds];
    imageView.image = image;
    [[[UIApplication sharedApplication] keyWindow] addSubview:imageView];
    [UIView animateWithDuration:0.35 animations:^{
        imageView.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            [imageView removeFromSuperview];
            if (_interactiveFromImage) {
                if ([_delegate respondsToSelector:@selector(launcherControllerDidPreview:)]) {
                    [_delegate launcherControllerDidPreview:self];
                }
            }
            if ([_delegate respondsToSelector:@selector(launcherControllerDidHide:)]) {
                [_delegate launcherControllerDidHide:self];
            }
        }
    }];
}

- (void)_updateViewsForCurrentMode {
    if (_mode != AXLaunchScreenViewControllerLauncher && _mode != AXLaunchScreenViewControllerLaunchPage) return;
    switch (_mode) {
        case AXLaunchScreenViewControllerLaunchPage: {
            [_imageView removeFromSuperview];
            if (_showsPageControl && _pageControl.superview) {
                [self.view insertSubview:self.collectionView belowSubview:self.pageControl];
            } else {
                [self.view addSubview:self.collectionView];
            }
            if (_showsSkippingElements) [self.view addSubview:self.skipButonItem];
            [self.view addSubview:self.dismissButtonItem];
            if (_collectionView.contentOffset.x/_collectionView.bounds.size.width < _pageImages.count-1) {
                _dismissButtonItem.hidden=YES;
            }
        }
            break;
        case AXLaunchScreenViewControllerLauncher: {
            [_collectionView removeFromSuperview];
            [_pageControl removeFromSuperview];
            [self.view addSubview:self.imageView];
            UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:_urlForImage];
            if (image) {
                _imageView.image = image;
            } else {
                [_imageView sd_setImageWithURL:[NSURL URLWithString:_urlForImage?:@""] placeholderImage:nil options:SDWebImageHighPriority completed:AXSDWebImageCompletionHandler()];
            }
            if (_showsSkippingElements) [self.view addSubview:self.skipButonItem];
        }
            break;
        default:{}
            break;
    }
    if (_showsSkippingElements) [self.skipButonItem addSubview:self.countingLabel];
    [self _updateFrameOfButtons];
}

- (void)_updateFrameOfButtons {
    switch (_mode) {
        case AXLaunchScreenViewControllerLaunchPage:
            [_skipButonItem setFrame:CGRectMake(CGRectGetWidth(self.view.frame)-kAXLaunchSkipButtonSize.width-15, 25, kAXLaunchSkipButtonSize.width, kAXLaunchSkipButtonSize.height)];
            _skipButonItem.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleRightMargin;
            [_dismissButtonItem setFrame:CGRectMake(CGRectGetWidth(self.view.frame)*.5-kAXLaunchDismissButtonSize.width*.5, CGRectGetHeight(self.view.frame)-44-56, kAXLaunchDismissButtonSize.width, kAXLaunchDismissButtonSize.height)];
            _dismissButtonItem.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
            break;
        case AXLaunchScreenViewControllerLauncher:
            [_skipButonItem setFrame:CGRectMake(CGRectGetWidth(self.view.frame)-kAXLaunchSkipButtonSize.width-15, CGRectGetHeight(self.view.frame)-kAXLaunchSkipButtonSize.height-25, kAXLaunchSkipButtonSize.width, kAXLaunchSkipButtonSize.height)];
            _skipButonItem.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin;
            break;
        default:
            break;
    }
    
    _countingLabel.frame = _skipButonItem.bounds;
    _countingLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
}
     
- (void)_setupPageControl {
    [self.view removeConstraints:_contraintsOfPageControl];
    [_pageControl removeFromSuperview];
    _contraintsOfPageControl = nil;
    if (!_showsPageControl || _mode != AXLaunchScreenViewControllerLaunchPage) { return; }
    
    [self.view addSubview:self.pageControl];
    _pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSMutableArray *contraints = [NSMutableArray array];
    [contraints addObject:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_pageControl attribute:NSLayoutAttributeBottom multiplier:1.0 constant:20]];
    [contraints addObject:[NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_pageControl attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [_pageControl setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [_pageControl setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    
    _contraintsOfPageControl = [contraints copy];
    [self.view addConstraints:_contraintsOfPageControl];
}
@end

@implementation AXPreviewingFlowLayout
- (instancetype)init {
    if (self = [super init]) {
        [self initializer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initializer];
    }
    return self;
}

- (void)initializer {
}

#pragma mark - Override
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)oldBounds
{
    return YES;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray* array = [super layoutAttributesForElementsInRect:rect];
    CGRect visibleRect;
    visibleRect.origin = self.collectionView.contentOffset;
    visibleRect.size = self.collectionView.bounds.size;
    
    NSMutableArray *modifiedArray = [@[] mutableCopy];
    
    
    for (UICollectionViewLayoutAttributes* attributes in array) {
        UICollectionViewLayoutAttributes* modifiedAttributes = [attributes copy];
        if (CGRectIntersectsRect(modifiedAttributes.frame, rect)) {
            CGFloat distance = CGRectGetMidX(visibleRect) - modifiedAttributes.center.x;
            CGFloat normalizedDistance = distance / modifiedAttributes.size.width;
            
            CGSize itemSize = [self.collectionView.delegate respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)]?[((id<UICollectionViewDelegateFlowLayout>)self.collectionView.delegate) collectionView:self.collectionView layout:self sizeForItemAtIndexPath:modifiedAttributes.indexPath]:self.itemSize;
            
            if (ABS(distance) < modifiedAttributes.size.width) {
                CGFloat zoom = 1 - 0.08 * ABS(normalizedDistance);
                modifiedAttributes.size = CGSizeMake(itemSize.width*zoom, itemSize.height);
                /*
                CGFloat zoom = 1 - 0.6 * ABS(normalizedDistance);
                modifiedAttributes.transform = CGAffineTransformMakeScale(zoom, 1);
                 */
            }
        }
        [modifiedArray addObject:modifiedAttributes];
    }
    return modifiedArray;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGFloat offsetAdjustment = MAXFLOAT;
    CGFloat horizontalCenter = proposedContentOffset.x + (CGRectGetWidth(self.collectionView.bounds) / 2.0);
    
    CGRect targetRect = CGRectMake(proposedContentOffset.x, 0.0, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    NSArray* array = [super layoutAttributesForElementsInRect:targetRect];
    
    for (UICollectionViewLayoutAttributes* layoutAttributes in array) {
        CGFloat itemHorizontalCenter = layoutAttributes.center.x;
        if (ABS(itemHorizontalCenter - horizontalCenter) < ABS(offsetAdjustment)) {
            offsetAdjustment = itemHorizontalCenter - horizontalCenter;
        }
    }
    return CGPointMake(proposedContentOffset.x + offsetAdjustment, proposedContentOffset.y);
}
@end
