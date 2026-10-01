/* 
    Copyright (C) 2025  Serge Alagon

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
*/

#import "FloatingButtonWindow.h"

@implementation FloatingButtonWindow {
    UIButton *floatingButton;
    CGPoint originalCenter;
}

+ (instancetype)sharedInstance {
    static FloatingButtonWindow *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FloatingButtonWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    });
    return sharedInstance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelAlert + 9999;
        self.backgroundColor = [UIColor clearColor];
        self.hidden = YES;

        // 恢复悬浮按钮
        floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        floatingButton.frame = CGRectMake(100, 100, 60, 60);
        floatingButton.layer.cornerRadius = 30;
        floatingButton.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
        
        // 设置沙漏图标
        UIImage *icon = [UIImage systemImageNamed:@"hourglass"];
        [floatingButton setImage:icon forState:UIControlStateNormal];
        [floatingButton tintColor:[UIColor systemRedColor]];

        // 点击悬浮球触发操作面板
        [floatingButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // 添加拖动手势（可以随意拖动悬浮球位置）
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [floatingButton addGestureRecognizer:panGesture];

        [self addSubview:floatingButton];
    }
    return self;
}

// 拖动悬浮窗逻辑
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self];
    UIView *button = gesture.view;
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        originalCenter = button.center;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        button.center = CGPointMake(originalCenter.x + translation.x, originalCenter.y + translation.y);
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        CGRect screenRect = [UIScreen mainScreen].bounds;
        CGPoint center = button.center;
        CGFloat margin = 35;
        
        if (center.x < margin) center.x = margin;
        if (center.x > screenRect.size.width - margin) center.x = screenRect.size.width - margin;
        if (center.y < margin + 40) center.y = margin + 40;
        if (center.y > screenRect.size.height - margin - 40) center.y = screenRect.size.height - margin - 40;
        
        [UIView animateWithDuration:0.3 animations:^{
            button.center = center;
        }];
    }
}

// 点击悬浮球时弹出操作面板
- (void)buttonTapped:(id)sender {
    UIViewController *rootVC = self.rootViewController;
    if (!rootVC) {
        rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Immortalizer 控制面板" 
                                                               message:@"请选择操作" 
                                                        preferredStyle:UIAlertControllerStyleAlert];
    
    // 切换防挂起开启/关闭状态
    [alert addAction:[UIAlertAction actionWithTitle:@"切换防挂起状态" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL currentState = [defaults boolForKey:@"immortalized"];
        [defaults setBool:!currentState forKey:@"immortalized"];
        [defaults synchronize];
        
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.sergy.immortalizerjailed.updateprefs"), NULL, NULL, YES);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [rootVC presentViewController:alert animated:YES completion:nil];
}

- (void)showButton {
    self.hidden = NO;
}

- (void)hideButton {
    self.hidden = YES;
}

// 触摸穿透：只有点在悬浮球上时才响应，其余空白地方不影响点 App
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint buttonPoint = [self convertPoint:point toView:floatingButton];
    if ([floatingButton pointInside:buttonPoint withEvent:event]) {
        return YES;
    }
    return NO;
}

@end
