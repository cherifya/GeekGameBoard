//
//  GGBLayer.h
//  GGB-iPhone
//
//  Created by Jens Alfke on 3/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//


#if TARGET_OS_IPHONE
#import <QuartzCore/QuartzCore.h>
#else
#import <Quartz/Quartz.h>
#endif


extern NSString* const GGBLayerStyleChangedNotification;


@interface GGBLayer : CALayer <NSCopying>
{
    CABasicAnimation *_curAnimation;
    NSMutableDictionary *_styleDict;

#if ! TARGET_OS_IPHONE
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

/** Change a property in this layer's 'style' dictionary (if it has one),
    and update every other layer that shares the same style dictionary. */
- (void) setValue: (id)value ofStyleProperty: (NSString*)prop;

/** Send a message to all sublayers in my tree */
- (void) makeSublayersPerformSelector: (SEL)selector withObject: (id)object;

@property (readonly) CATransform3D aggregateTransform;

/** Call this to notify all sublayers that their aggregate transform has changed. */
- (void) changedTransform;

/** Called to notify that a superlayer's transform has changed. */
- (void) aggregateTransformChanged;

@end


/** Moves a layer from one superlayer to another, without changing its position onscreen. */
void ChangeSuperlayer( CALayer *layer, CALayer *newSuperlayer, int index );

/** Removes a layer from its superlayer without any fade-out animation. */
void RemoveImmediately( CALayer *layer );

/** Disables animations until EndDisableAnimations is called. */
void BeginDisableAnimations(void);
void EndDisableAnimations(void);

CGColorRef GetEffectiveBackground( CALayer *layer );

NSString* StringFromTransform3D( CATransform3D xform );
