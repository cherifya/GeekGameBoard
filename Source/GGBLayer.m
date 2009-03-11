//
//  GGBLayer.m
//  GGB-iPhone
//
//  Created by Jens Alfke on 3/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GGBLayer.h"
#import "QuartzUtils.h"
#import "GGBUtils.h"


NSString* const GGBLayerStyleChangedNotification = @"GGBLayerStyleChanged";


@implementation GGBLayer


- (NSString*) description
{
    return [NSString stringWithFormat: @"%@[(%g,%g)]", self.class,self.position.x,self.position.y];
}


- (void) redisplayAll
{
    [self setNeedsDisplay];
    for( CALayer *layer in self.sublayers )
        if( [layer isKindOfClass: [GGBLayer class]] )
            ((GGBLayer*)layer).redisplayAll;
        else
            [layer setNeedsDisplay];
}


/*
- (void)addAnimation:(CAAnimation *)anim forKey:(NSString *)key 
{
    NSLog(@"%@[%p] addAnimation: %p forKey: %@",[self class],self,anim,key);
    [super addAnimation: anim forKey: key];
}
*/


- (void) animateAndBlock: (NSString*)keyPath from: (id)from to: (id)to duration: (NSTimeInterval)duration
{
    //WARNING: This code works, but is a mess. I hope to find a better way to do this. --Jens 3/16/08
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath: keyPath];
    anim.duration= duration;
    anim.fromValue = from;
    anim.toValue = to;
    anim.removedOnCompletion = YES;
    anim.delegate = self;
    [self addAnimation:anim forKey: @"animateAndBlock:"];
    _curAnimation = (id)[self animationForKey: @"animateAndBlock:"];
    [self setValue: to forKeyPath: keyPath];    // animation doesn't update the property value

    if( self.presentationLayer ) {
        // Now wait for it to finish:
        while( _curAnimation ) {
            [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode//NSEventTrackingRunLoopMode
                                     beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.1]];
        }
    } else {
        _curAnimation = nil;
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if( anim==_curAnimation ) {
        _curAnimation = nil;
    }
}


- (void) setStyle: (NSDictionary*)style
{
    if( style != _styleDict ) {
        if( _styleDict )
            [[NSNotificationCenter defaultCenter] removeObserver: self 
                                                            name: GGBLayerStyleChangedNotification
                                                          object: _styleDict];
        if( style )
            [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(_styleChanged)
                                                         name: GGBLayerStyleChangedNotification
                                                       object: style];
        setObj(&_styleDict,style);
    }
    [super setStyle: style];
}

- (void) _styleChanged
{
    // Reapply the style, so any changes in the dict will take effect.
    [super setStyle: _styleDict];
}

- (void) dealloc
{
    if( _styleDict )
        [[NSNotificationCenter defaultCenter] removeObserver: self
                                                        name: GGBLayerStyleChangedNotification
                                                      object: _styleDict];
    [super dealloc];
}


- (void) setValue: (id)value ofStyleProperty: (NSString*)prop
{
    if( _styleDict ) {
        id oldValue = [_styleDict objectForKey: prop];
        if( oldValue != value ) {
            if( value )
                [_styleDict setObject: value forKey: prop];
            else
                [_styleDict removeObjectForKey: prop];
            [[NSNotificationCenter defaultCenter] postNotificationName: GGBLayerStyleChangedNotification
                                                                object: _styleDict];
        }
    } else
        [self setValue: value forKey: prop];
}


- (void) makeSublayersPerformSelector: (SEL)selector withObject: (id)object
{
    for( GGBLayer *layer in self.sublayers ) {
        [layer performSelector: selector withObject: object withObject: nil];
        [layer makeSublayersPerformSelector: selector withObject: object];
    }
}

- (void) changedTransform
{
    [self makeSublayersPerformSelector: @selector(aggregateTransformChanged) withObject: nil];
}

- (void) aggregateTransformChanged
{
}


- (CATransform3D) aggregateTransform
{
    CATransform3D xform = CATransform3DIdentity;
    for( CALayer *layer=self; layer; layer=layer.superlayer ) {
        xform = CATransform3DConcat(layer.transform,xform);
        xform = CATransform3DConcat(layer.sublayerTransform,xform);
    }
    return xform;
}


NSString* StringFromTransform3D( CATransform3D xform )
{
    NSMutableString *str = [NSMutableString string];
    const CGFloat *np = (const CGFloat*)&xform;
    for( int i=0; i<16; i++ ) {
        if( i>0 && (i%4)==0 )
            [str appendString: @"\n"];
        [str appendFormat: @"%7.2f ", *np++];
    }
    return str;
}


#if TARGET_OS_IPHONE

#pragma mark -
#pragma mark IPHONE VERSION:


- (id) copyWithZone: (NSZone*)zone
{
    GGBLayer *clone = [[[self class] alloc] init];
    clone.bounds = self.bounds;
    clone.position = self.position;
    clone.zPosition = self.zPosition;
    clone.anchorPoint = self.anchorPoint;
    clone.transform = self.transform;
    clone.hidden = self.hidden;
    clone.doubleSided = self.doubleSided;
    clone.sublayerTransform = self.sublayerTransform;
    clone.masksToBounds = self.masksToBounds;
    clone.contents = self.contents;                 // doesn't copy contents (shallow-copy)
    clone.contentsRect = self.contentsRect;
    clone.contentsGravity = self.contentsGravity;
    clone.minificationFilter = self.minificationFilter;
    clone.magnificationFilter = self.magnificationFilter;
    clone.opaque = self.opaque;
    clone.needsDisplayOnBoundsChange = self.needsDisplayOnBoundsChange;
    clone.edgeAntialiasingMask = self.edgeAntialiasingMask;
    clone.backgroundColor = self.backgroundColor;
    clone.opacity = self.opacity;
    clone.compositingFilter = self.compositingFilter;
    clone.filters = self.filters;
    clone.backgroundFilters = self.backgroundFilters;
    clone.actions = self.actions;
    clone.name = self.name;
    clone.style = self.style;
    
    clone.cornerRadius = self.cornerRadius;
    clone.borderWidth = self.borderWidth;
    clone.borderColor = self.borderColor;
    
    for( GGBLayer *sublayer in self.sublayers ) {
        sublayer = [sublayer copyWithZone: zone];
        [clone addSublayer: sublayer];
    }
    return clone;
}


- (CGFloat) cornerRadius    {return _cornerRadius;}
- (CGFloat) borderWidth     {return _borderWidth;}
- (CGColorRef) backgroundColor {return _realBGColor;}
- (CGColorRef) borderColor  {return _borderColor;}

- (void) setCornerRadius: (CGFloat)r
{
    if( r != _cornerRadius ) {
        _cornerRadius = r;
        [self setNeedsDisplay];
    }
}


- (void) setBorderWidth: (CGFloat)w
{
    if( w != _borderWidth ) {
        _borderWidth = w;
        self.needsDisplayOnBoundsChange = (_borderWidth>0.0 && _borderColor!=NULL);
        [self setNeedsDisplay];
    }
}


- (void) setBackgroundColor: (CGColorRef)color
{
    if( color != _realBGColor ) {
        CGColorRelease(_realBGColor);
        _realBGColor = CGColorRetain(color);
        [self setNeedsDisplay];
    }
}


- (void) setBorderColor: (CGColorRef)color
{
    if( color != _borderColor ) {
        CGColorRelease(_borderColor);
        _borderColor = CGColorRetain(color);
        self.needsDisplayOnBoundsChange = (_borderWidth>0.0 && _borderColor!=NULL);
        [self setNeedsDisplay];
    }
}


- (void)drawInContext:(CGContextRef)ctx
{
    [super drawInContext: ctx];
    
    CGContextSaveGState(ctx);

    if( _realBGColor ) {
        CGRect interior = CGRectInset(self.bounds, _borderWidth,_borderWidth);
        CGContextSetFillColorWithColor(ctx, _realBGColor);
        if( _cornerRadius <= 0.0 ) {
            CGContextFillRect(ctx,interior);
        } else {
            CGContextBeginPath(ctx);
            AddRoundRect(ctx,interior,_cornerRadius);
            CGContextFillPath(ctx);
        }
    }
    
    if( _borderWidth > 0.0 && _borderColor!=NULL ) {
        CGRect border = CGRectInset(self.bounds, _borderWidth/2.0, _borderWidth/2.0);
        CGContextSetStrokeColorWithColor(ctx, _borderColor);
        CGContextSetLineWidth(ctx, _borderWidth);
        
        if( _cornerRadius <= 0.0 ) {
            CGContextStrokeRect(ctx,border);
        } else {
            CGContextBeginPath(ctx);
            AddRoundRect(ctx,border,_cornerRadius);
            CGContextStrokePath(ctx);
        }
    }
    
    CGContextRestoreGState(ctx);
}


#else

#pragma mark -
#pragma mark MAC OS VERSION:


- (id) copyWithZone: (NSZone*)zone
{
    // NSLayer isn't copyable, but it is archivable. So create a copy by archiving to
    // a temporary data block, then unarchiving a new layer from that block.
    
    // One complication is that, due to a bug in Core Animation, CALayer can't archive
    // a pattern-based CGColor. So as a workaround, clear the background before archiving,
    // then restore it afterwards.
    
    // Also, archiving a CALayer with an image in it leaks memory. (Filed as rdar://5786865 )
    // As a workaround, clear the contents before archiving, then restore.
    
    CGColorRef bg = CGColorRetain(self.backgroundColor);
    self.backgroundColor = NULL;
    id contents = [self.contents retain];
    self.contents = nil;
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject: self];
    
    self.backgroundColor = bg;
    self.contents = contents;

    GGBLayer *clone = [NSKeyedUnarchiver unarchiveObjectWithData: data];
    clone.backgroundColor = bg;
    clone.contents = contents;
    CGColorRelease(bg);
    [contents release];

    return [clone retain];
}


#endif


@end



#pragma mark -
#pragma mark UTILITIES:


void BeginDisableAnimations(void)
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
}

void EndDisableAnimations(void)
{
    [CATransaction commit];
} 


void ChangeSuperlayer( CALayer *layer, CALayer *newSuperlayer, int index )
{
    // Disable actions, else the layer will move to the wrong place and then back!
    [CATransaction flush];
    BeginDisableAnimations();
    
    CGPoint pos = layer.position;
    if( layer.superlayer )
        pos = [newSuperlayer convertPoint: pos fromLayer: layer.superlayer];
    [layer retain];
    [layer removeFromSuperlayer];
    layer.position = pos;
    if( index >= 0 )
        [newSuperlayer insertSublayer: layer atIndex: index];
    else
        [newSuperlayer addSublayer: layer];
    [layer release];
    
    EndDisableAnimations();
}


void RemoveImmediately( CALayer *layer )
{
    [CATransaction flush];
    BeginDisableAnimations();
    [layer removeFromSuperlayer];
    EndDisableAnimations();
}    


CGColorRef GetEffectiveBackground( CALayer *layer )
{
    for( ; layer; layer=layer.superlayer ) {
        CGColorRef bg = layer.backgroundColor;
        if( bg )
            return bg;
    }
    return nil;
}
