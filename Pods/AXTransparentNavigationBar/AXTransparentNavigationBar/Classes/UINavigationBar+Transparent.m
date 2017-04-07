//
//  UINavigationBar+Transparent.m
//  AXTransparentNavigationBar
//
//  Created by devedbox on 16/9/2.
//  Copyright © 2016年 devedbox. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "UINavigationBar+Transparent.h"
#import <objc/runtime.h>

@interface UINavigationBar (Transparent_Private)
/// Translucent original value .
@property(assign, nonatomic) BOOL originalTranslucent;
/// Original background color.
@property(strong, nonatomic) UIColor *originalBackgroundColor;
@end

@implementation UINavigationBar (Transparent)
- (BOOL)isTransparent {
    return [self transparent];
}

- (BOOL)transparent {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setTransparent:(BOOL)transparent {
    [self setTransparent:transparent animated:NO];
}

- (void)setTransparent:(BOOL)transparent animated:(BOOL)animated {
    objc_setAssociatedObject(self, @selector(transparent), @(transparent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (transparent) {
        self.originalBackgroundColor = self.backgroundColor;
        self.backgroundColor = [UIColor clearColor];
    }
    
    // Get subviews.
    NSArray<UIView *> *subviews = [self subviews];
    for (UIView *view in subviews) {
        if ([view isKindOfClass:NSClassFromString(@"_UINavigationBarBackIndicatorView")]) continue;
        if (([view isKindOfClass:NSClassFromString(@"_UINavigationBarBackground")] || [view isKindOfClass:NSClassFromString(@"_UIBarBackground")]) || [[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] '_'"] evaluateWithObject:NSStringFromClass(view.class)]) {
            if (animated) {
                [UIView animateWithDuration:0.25 animations:^{
                    view.alpha = transparent?.0:1.0;
                } completion:^(BOOL finished) {
                    if (finished && !transparent) {
                        self.backgroundColor = self.originalBackgroundColor;
                    }
                }];
            } else {
                view.alpha = transparent?.0:1.0;
            }
        }
    }
}
@end

@implementation UINavigationBar (Transparent_Private)
- (BOOL)originalTranslucent {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setOriginalTranslucent:(BOOL)originalTranslucent {
    objc_setAssociatedObject(self, @selector(originalTranslucent), @(originalTranslucent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIColor *)originalBackgroundColor {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setOriginalBackgroundColor:(UIColor *)originalBackgroundColor {
    objc_setAssociatedObject(self, @selector(originalBackgroundColor), originalBackgroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@implementation UIViewController(NavigationBarTransparent)
- (BOOL)isNavigationBarTransparent {
    return self.navigationController.navigationBar.isTransparent;
}

- (void)setNavigationBarTransparent:(BOOL)navigationBarTransparent {
    [self setNavigationBarTransparent:navigationBarTransparent animated:NO];
}

- (void)setNavigationBarTransparent:(BOOL)navigationBarTransparent animated:(BOOL)animated {
    [self.navigationController.navigationBar setTransparent:navigationBarTransparent animated:animated];
}
@end
