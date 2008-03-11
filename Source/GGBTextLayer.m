//
//  GGBTextLayer.m
//  GGB-iPhone
//
//  Created by Jens Alfke on 3/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GGBTextLayer.h"
#import "QuartzUtils.h"


@implementation GGBTextLayer


+ (GGBTextLayer*) textLayerInSuperlayer: (CALayer*)superlayer
                               withText: (NSString*)text
                               fontSize: (float) fontSize
                              alignment: (enum CAAutoresizingMask) align
{
    GGBTextLayer *label = [[self alloc] init];
    label.string = text;

#if TARGET_OS_ASPEN
    UIFont *font = [UIFont systemFontOfSize: fontSize];
#else
    NSFont *font = [NSFont systemFontOfSize: fontSize];
    label.font = font;
#endif
    
    label.fontSize = fontSize;
    label.foregroundColor = kBlackColor;
    
    NSString *mode;
    if( align & kCALayerWidthSizable )
        mode = @"center";
    else if( align & kCALayerMinXMargin )
        mode = @"right";
    else
        mode = @"left";
    align |= kCALayerWidthSizable;
    label.alignmentMode = mode;
    
    CGFloat inset = 3;
    if( [superlayer respondsToSelector: @selector(borderWidth)] )
        inset += ((GGBLayer*)superlayer).borderWidth;
    CGRect bounds = CGRectInset(superlayer.bounds, inset, inset);
    CGFloat height = font.ascender;
    CGFloat y = bounds.origin.y;
    if( align & kCALayerHeightSizable )
        y += (bounds.size.height-height)/2.0;
    else if( align & kCALayerMinYMargin )
        y += bounds.size.height - height;
    align &= ~kCALayerHeightSizable;
    label.bounds = CGRectMake(0, font.descender,
                              bounds.size.width, height - font.descender);
    label.position = CGPointMake(bounds.origin.x,y+font.descender);
    label.anchorPoint = CGPointMake(0,0);
    
    label.autoresizingMask = align;
    [superlayer addSublayer: label];
    [label release];
    return label;
}


#if TARGET_OS_ASPEN
@synthesize string=_string, fontSize=_fontSize, 
            foregroundColor=_foregroundColor, alignmentMode=_alignmentMode;
#endif


@end
