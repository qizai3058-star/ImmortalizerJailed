/* 
    Copyright (C) 2025  Serge Alagon

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>. 
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

        floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        floatingButton.frame = CGRectMake(100, 100, 50, 50);
        floatingButton.layer.cornerRadius = 25;
        floatingButton.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.6];
        
        UIImage *icon = [UIImage systemImageNamed:@"hourglass"];
        [floatingButton setImage:icon forState:UIControlStateNormal];
        floatingButton.tintColor = [UIColor whiteColor];

        [floatingButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [floatingButton addGestureRecognizer:panGesture];

        [self addSubview:floatingButton];
    }
    return self;
}

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
        CGFloat margin = 30;
        
        if (center.x < margin) center.x = margin;
        if (center.x > screenRect.size.width - margin) center.x = screenRect.size.width - margin;
        if (center.y < margin + 30) center.y = margin + 30;
        if (center.y > screenRect.size.height - margin - 30) center.y = screenRect.size.height - margin - 30;
        
        [UIView animateWithDuration:0.3 animations:^{
            button.center = center;
        }];
    }
}

- (void)buttonTapped:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL currentState = [defaults boolForKey:@"immortalized"];
    [defaults setBool:!currentState forKey:@"immortalized"];
    [defaults synchronize];
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.sergy.immortalizerjailed.updateprefs"), NULL, NULL, YES);
    
    [UIView animateWithDuration:0.1 animations:^{
        self->floatingButton.transform = CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self->floatingButton.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (void)showButton {
    self.hidden = NO;
}

- (void)hideButton {
    self.hidden = YES;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint buttonPoint = [self convertPoint:point toView:floatingButton];
    if ([floatingButton pointInside:buttonPoint withEvent:event]) {
        return YES;
    }
    return NO;
}

@end
