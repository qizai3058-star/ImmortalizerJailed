/* 
    Copyright (C) 2025  Serge Alagon

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
*/

#import "FloatingButtonWindow.h"

@implementation FloatingButtonWindow {
    // 已取消可见悬浮按钮，改用全屏透明窗口监听双击手势
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
        // 设置窗口层级高于普通 App 界面
        self.windowLevel = UIWindowLevelAlert + 9999;
        self.backgroundColor = [UIColor clearColor];
        self.hidden = YES;

        // 添加双击手势监听（默认：双指双击唤出操作面板。如果想改成单指双击，请把 numberOfTouchesRequired 改为 1）
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTapGesture.numberOfTouchesRequired = 2; // 2 代表双指，若想单指改为 1
        doubleTapGesture.numberOfTapsRequired = 2;    // 2 代表双击
        
        // 关键：设为 NO，确保双击时不会拦截或卡死底层 App 的正常单点触摸
        doubleTapGesture.cancelsTouchesInView = NO;
        
        [self addGestureRecognizer:doubleTapGesture];
    }
    return self;
}

// 核心：双击触发时呼出操作面板
- (void)handleDoubleTap:(UITapGestureRecognizer * _Nonnull)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        UIViewController *rootVC = self.rootViewController;
        if (!rootVC) {
            rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        }
        
        // 弹出控制面板
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Immortalizer 控制面板" 
                                                                   message:@"检测到双击手势，已唤出操作面板。" 
                                                            preferredStyle:UIAlertControllerStyleAlert];
        
        // 动作 1：切换防挂起开启/关闭状态
        [alert addAction:[UIAlertAction actionWithTitle:@"切换防挂起状态" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            BOOL currentState = [defaults boolForKey:@"immortalized"];
            [defaults setBool:!currentState forKey:@"immortalized"];
            [defaults synchronize];
            
            // 通知插件更新状态
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.sergy.immortalizerjailed.updateprefs"), NULL, NULL, YES);
        }]];
        
        // 动作 2：关闭面板
        [alert addAction:[UIAlertAction actionWithTitle:@"关闭面板" style:UIAlertActionStyleCancel handler:nil]];
        
        [rootVC presentViewController:alert animated:YES completion:nil];
    }
}

// 触摸事件穿透：确保取消悬浮窗后，全屏透明窗口不会挡住你平时点 App 里的按钮
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden) return NO;
    // 返回 YES 允许整个屏幕捕获双击手势，配合 cancelsTouchesInView = NO 不影响平时的点击
    return YES; 
}

- (void)showButton {
    self.hidden = NO;
}

- (void)hideButton {
    self.hidden = YES;
}

@end
