//
//  GGBTextLayer.h
//  GGB-iPhone
//
//  Created by Jens Alfke on 3/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GGBLayer.h"


#if TARGET_OS_IPHONE
@interface GGBTextLayer : GGBLayer
{
    NSString *_string;
    UIFont *_font;
    CGColorRef _foregroundColor;
    NSString *_alignmentMode;
}

@property(copy) id string;
@property (retain) UIFont *font;
@property CGColorRef foregroundColor;
@property (copy) NSString *alignmentMode;

#else
@interface GGBTextLayer : CATextLayer
#endif

+ (GGBTextLayer*) textLayerInSuperlayer: (CALayer*)superlayer
                               withText: (NSString*)text
                               fontSize: (float) fontSize
                              alignment: (enum CAAutoresizingMask) align;
+ (GGBTextLayer*) textLayerInSuperlayer: (CALayer*)superlayer
                               withText: (NSString*)text
                                   font: (id)inputFont
                              alignment: (enum CAAutoresizingMask) align;

@end


#if TARGET_OS_IPHONE
/* Bit definitions for `autoresizingMask' property. */

enum CAAutoresizingMask
{
    kCALayerNotSizable	= 0,
    kCALayerMinXMargin	= 1U << 0,
    kCALayerWidthSizable	= 1U << 1,
    kCALayerMaxXMargin	= 1U << 2,
    kCALayerMinYMargin	= 1U << 3,
    kCALayerHeightSizable	= 1U << 4,
    kCALayerMaxYMargin	= 1U << 5
};

enum
{
    kCALayerBottomMargin = kCALayerMaxYMargin,
    kCALayerTopMargin    = kCALayerMinYMargin
};

#else
enum
{
    kCALayerBottomMargin = kCALayerMinYMargin,
    kCALayerTopMargin    = kCALayerMaxYMargin
};
#endif
