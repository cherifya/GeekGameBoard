//
//  GGBLayer.h
//  GGB-iPhone
//
//  Created by Jens Alfke on 3/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#if TARGET_OS_ASPEN
#import <QuartzCore/QuartzCore.h>
#else
#import <Quartz/Quartz.h>
#endif


@interface GGBLayer : CALayer <NSCopying>
{
    CABasicAnimation *_curAnimation;

#if ! TARGET_OS_ASPEN
}
#else
// For some reason, the CALayer class on iPhone OS doesn't have these!
    CGFloat _cornerRadius, _borderWidth;
    CGColorRef _borderColor, _realBGColor;
    unsigned int _autoresizingMask;
}

@property CGFloat cornerRadius, borderWidth;
@property CGColorRef borderColor;
#endif

- (void) redisplayAll;

- (void) animateAndBlock: (NSString*)keyPath from: (id)from to: (id)to duration: (NSTimeInterval)duration;

@end
