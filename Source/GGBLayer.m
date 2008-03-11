//
//  GGBLayer.m
//  GGB-iPhone
//
//  Created by Jens Alfke on 3/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GGBLayer.h"
#import "QuartzUtils.h"


@implementation GGBLayer


- (NSString*) description
{
    return [NSString stringWithFormat: @"%@[(%g,%g)]", self.class,self.position.x,self.position.y];
}


#if TARGET_OS_ASPEN

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
    clone.autoresizingMask = self.autoresizingMask;
    
    for( GGBLayer *sublayer in self.sublayers ) {
        sublayer = [sublayer copyWithZone: zone];
        [clone addSublayer: sublayer];
    }
    return clone;
}


@synthesize autoresizingMask=_autoresizingMask;

- (CGFloat) cornerRadius    {return _cornerRadius;}
- (CGFloat) borderWidth     {return _borderWidth;}
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
