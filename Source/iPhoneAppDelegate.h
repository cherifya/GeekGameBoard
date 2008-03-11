//
//  iPhoneAppDelegate.h
//  GGB-iPhone
//
//  Created by Jens Alfke on 3/7/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BoardUIView;

@interface GGB_iPhoneAppDelegate : NSObject <UIModalViewDelegate> {
    UIWindow *_window;
    BoardUIView *_contentView;
    UILabel *_headline;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) BoardUIView *contentView;
@property (nonatomic, retain) UILabel *headline;

- (void) startGameNamed: (NSString*)gameClassName;

@end
