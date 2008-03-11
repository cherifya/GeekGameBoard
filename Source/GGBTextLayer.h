//
//  GGBTextLayer.h
//  GGB-iPhone
//
//  Created by Jens Alfke on 3/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GGBLayer.h"


#if TARGET_OS_ASPEN
@interface GGBTextLayer : GGBLayer
{
    NSString *_string;
    CGFloat _fontSize;
    CGColorRef _foregroundColor;
    NSString *_alignmentMode;
}

@property(copy) id string;
@property CGFloat fontSize;
@property CGColorRef foregroundColor;
@property (copy) NSString *alignmentMode;

#else
@interface GGBTextLayer : CATextLayer
#endif

+ (GGBTextLayer*) textLayerInSuperlayer: (CALayer*)superlayer
                               withText: (NSString*)text
                               fontSize: (float) fontSize
                              alignment: (enum CAAutoresizingMask) align;

@end


