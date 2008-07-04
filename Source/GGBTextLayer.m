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
#if TARGET_OS_IPHONE
    UIFont *font = [UIFont systemFontOfSize: fontSize];
#else
    NSFont *font = [NSFont systemFontOfSize: fontSize];
#endif
    return [self textLayerInSuperlayer: superlayer
                              withText: text
                                  font: font
                             alignment: align];
}


+ (GGBTextLayer*) textLayerInSuperlayer: (CALayer*)superlayer
                               withText: (NSString*)text
                                   font: (id)inputFont
                              alignment: (enum CAAutoresizingMask) align
{
    GGBTextLayer *label = [[self alloc] init];
    label.string = text;

#if TARGET_OS_IPHONE
    UIFont *font = inputFont;
    [label setNeedsDisplay];
    label.needsDisplayOnBoundsChange = YES;
#else
    NSFont *font = inputFont;
    label.fontSize = font.pointSize;
#endif
    
    label.font = font;
    label.foregroundColor = kBlackColor;
    
    NSString *mode;
    if( (align & (kCALayerMinXMargin | kCALayerMaxXMargin)) == (kCALayerMinXMargin | kCALayerMaxXMargin) )
        mode = @"center";
    else {
        if( align & kCALayerWidthSizable )
            mode = @"center";
        else if( align & kCALayerMinXMargin )
            mode = @"right";
        else
            mode = @"left";
        align |= kCALayerWidthSizable;
    }
    label.alignmentMode = mode;
    
    // Get the bounds of the interior of the superlayer:
    CGFloat yinset = 0;
    if( [superlayer respondsToSelector: @selector(borderWidth)] )
        yinset += ((GGBLayer*)superlayer).borderWidth;
    CGFloat xinset;
    if( mode==@"center" )
        xinset = 0;
    else
        xinset = yinset + round(font.pointSize/3.0);
    CGRect bounds = CGRectInset(superlayer.bounds, xinset,yinset);
    
    // Compute y position of bottom of layer's frame. (Remember, descender is negative!)
    CGFloat y = bounds.origin.y;
    CGFloat descender=font.descender, height=font.ascender-descender;
    if( align & kCALayerHeightSizable ) {
        // Vertical centering:
        y += (bounds.size.height-height)/2.0;
#if ! TARGET_OS_IPHONE
        y += descender/2.0;
#endif
        align &= ~kCALayerHeightSizable;
    } else if( align & kCALayerMinYMargin ) {
        // Top alignment (Mac) or bottom (iPhone):
        y += bounds.size.height - height;
    }
    
    // Compute label's geometry:
    label.bounds = CGRectMake(0, descender,
                              bounds.size.width, height);
    label.anchorPoint = CGPointMake(0,0);
    label.position = CGPointMake(bounds.origin.x,y);
    
#if ! TARGET_OS_IPHONE
    label.autoresizingMask = align;
#endif
    [superlayer addSublayer: label];
    [label release];
    
#if 0 // for debugging layout, border the view
    label.borderWidth = 1;
    label.borderColor = kBlackColor;
#endif
    
    return label;
}


#if TARGET_OS_IPHONE
@synthesize string=_string, font=_font, 
            foregroundColor=_foregroundColor, alignmentMode=_alignmentMode;


- (id) copyWithZone: (NSZone*)zone
{
    GGBTextLayer *clone = [super copyWithZone: zone];
    clone.string = _string;
    clone.font = _font;
    clone.foregroundColor = _foregroundColor;
    clone.alignmentMode = _alignmentMode;
    return clone;
}


- (void)drawInContext:(CGContextRef)ctx
{
    [super drawInContext: ctx];
    
    if( _string.length > 0 ) {
        CGContextSaveGState(ctx);
        UIGraphicsPushContext(ctx);
        
        if( _foregroundColor )
            CGContextSetFillColorWithColor(ctx, _foregroundColor);
        
        UITextAlignment align;
        if( [_alignmentMode isEqualToString: @"center"] )
            align = UITextAlignmentCenter;
        else if( [_alignmentMode isEqualToString: @"right"] )
            align = UITextAlignmentRight;
        else
            align = UITextAlignmentLeft;
        
        CGRect bounds = self.bounds;
        //float ascender=_font.ascender, descender=_font.descender, leading=_font.leading;
        //bounds.size.height -= ascender-descender - leading;
        
        [_string drawInRect: bounds 
                   withFont: _font
              lineBreakMode: UILineBreakModeClip
                  alignment: align];
        
        UIGraphicsPopContext();
        CGContextRestoreGState(ctx);
    }
}


#endif


@end


/*
 .times lt mm: (TimesLTMM)
 times new roman: (TimesNewRomanBoldItalic, TimesNewRomanItalic, TimesNewRoman, TimesNewRomanBold)
 phonepadtwo: (PhonepadTwo)
 hiragino kaku gothic pron w3: (HiraKakuProN-W3)
 helvetica neue: (HelveticaNeueBold, HelveticaNeue)
 trebuchet ms: (TrebuchetMSItalic, TrebuchetMSBoldItalic, TrebuchetMSBold, TrebuchetMS)
 courier new: (CourierNewBoldItalic, CourierNewBold, CourierNewItalic, CourierNew)
 arial unicode ms: (arialuni)
 georgia: (Georgia, GeorgiaBold, GeorgiaBoldItalic, GeorgiaItalic)
 zapfino: (Zapfino)
 arial rounded mt bold: (ArialRoundedMTBold)
 db lcd temp: (DB_LCD_Temp-Black)
 verdana: (Verdana, VerdanaItalic, VerdanaBoldItalic, VerdanaBold)
 american typewriter: (AmericanTypewriterCondensedBold, AmericanTypewriter)
 helvetica: (HelveticaBoldOblique, Helvetica, HelveticaOblique, HelveticaBold)
 lock clock: (LockClock)
 courier: (CourierBoldOblique, CourierOblique)
 hiragino kaku gothic pron w6: (HiraKakuProN-W6)
 arial: (ArialItalic, ArialBold, Arial, ArialBoldItalic)
 .helvetica lt mm: (HelveticaLTMM)
 stheiti: (STHeiti, STXihei)
 applegothic: (AppleGothicRegular)
 marker felt: (MarkerFeltThin)
*/