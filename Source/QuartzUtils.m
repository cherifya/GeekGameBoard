/*  This code is based on Apple's "GeekGameBoard" sample code, version 1.0.
    http://developer.apple.com/samplecode/GeekGameBoard/
    Copyright © 2007 Apple Inc. Copyright © 2008 Jens Alfke. All Rights Reserved.

    Redistribution and use in source and binary forms, with or without modification, are permitted
    provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions
      and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of
      conditions and the following disclaimer in the documentation and/or other materials provided
      with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
    IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
    FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRI-
    BUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
    THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#import "QuartzUtils.h"


CGColorRef kBlackColor, kWhiteColor, 
           kTranslucentGrayColor, kTranslucentLightGrayColor,
           kAlmostInvisibleWhiteColor,
           kHighlightColor;


__attribute__((constructor))        // Makes this function run when the app loads
static void InitQuartzUtils()
{
    kBlackColor = CGColorCreateGenericGray(0.0, 1.0);
    kWhiteColor = CGColorCreateGenericGray(1.0, 1.0);
    kTranslucentGrayColor = CGColorCreateGenericGray(0.0, 0.5);
    kTranslucentLightGrayColor = CGColorCreateGenericGray(0.0, 0.25);
    kAlmostInvisibleWhiteColor = CGColorCreateGenericGray(1, 0.05);
    kHighlightColor = CGColorCreateGenericRGB(1, 1, 0, 0.5);
}


void ChangeSuperlayer( CALayer *layer, CALayer *newSuperlayer, int index )
{
    // Disable actions, else the layer will move to the wrong place and then back!
    [CATransaction flush];
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];

    CGPoint pos = [newSuperlayer convertPoint: layer.position 
                      fromLayer: layer.superlayer];
    [layer retain];
    [layer removeFromSuperlayer];
    if( index >= 0 )
        [newSuperlayer insertSublayer: layer atIndex: index];
    else
        [newSuperlayer addSublayer: layer];
    layer.position = pos;
    [layer release];

    [CATransaction commit];
}


void RemoveImmediately( CALayer *layer )
{
    [CATransaction flush];
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    [layer removeFromSuperlayer];
    [CATransaction commit];
}    


CATextLayer* AddTextLayer( CALayer *superlayer,
                           NSString *text, NSFont* font,
                           enum CAAutoresizingMask align )
{
    CATextLayer *label = [[CATextLayer alloc] init];
    label.string = text;
    label.font = font;
    label.fontSize = font.pointSize;
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
    
    CGFloat inset = superlayer.borderWidth + 3;
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


CGImageRef CreateCGImageFromFile( NSString *path )
{
    CGImageRef image = NULL;
    CFURLRef url = (CFURLRef) [NSURL fileURLWithPath: path];
    CGImageSourceRef src = CGImageSourceCreateWithURL(url, NULL);
    if( src ) {
        image = CGImageSourceCreateImageAtIndex(src, 0, NULL);
        CFRelease(src);
        if(!image) NSLog(@"Warning: CGImageSourceCreateImageAtIndex failed on file %@ (ptr size=%u)",path,sizeof(void*));
    }
    return image;
}


CGImageRef GetCGImageNamed( NSString *name )
{
    // For efficiency, loaded images are cached in a dictionary by name.
    static NSMutableDictionary *sMap;
    if( ! sMap )
        sMap = [[NSMutableDictionary alloc] init];
    
    CGImageRef image = (CGImageRef) [sMap objectForKey: name];
    if( ! image ) {
        // Hasn't been cached yet, so load it:
        NSString *path;
        if( [name hasPrefix: @"/"] )
            path = name;
        else {
            path = [[NSBundle mainBundle] pathForResource: name ofType: nil];
            NSCAssert1(path,@"Couldn't find bundle image resource '%@'",name);
        }
        image = CreateCGImageFromFile(path);
        NSCAssert1(image,@"Failed to load image from %@",path);
        [sMap setObject: (id)image forKey: name];
        CGImageRelease(image);
    }
    return image;
}


CGColorRef GetCGPatternNamed( NSString *name )         // can be resource name or abs. path
{
    // For efficiency, loaded patterns are cached in a dictionary by name.
    static NSMutableDictionary *sMap;
    if( ! sMap )
        sMap = [[NSMutableDictionary alloc] init];
    
    CGColorRef pattern = (CGColorRef) [sMap objectForKey: name];
    if( ! pattern ) {
        pattern = CreatePatternColor( GetCGImageNamed(name) );
        [sMap setObject: (id)pattern forKey: name];
        CGColorRelease(pattern);
    }
    return pattern;
}


CGImageRef GetCGImageFromPasteboard( NSPasteboard *pb )
{
    CGImageSourceRef src = NULL;
    NSArray *paths = [pb propertyListForType: NSFilenamesPboardType];
    if( paths.count==1 ) {
        // If a file is being dragged, read it:
        CFURLRef url = (CFURLRef) [NSURL fileURLWithPath: [paths objectAtIndex: 0]];
        src = CGImageSourceCreateWithURL(url, NULL);
    } else {
        // Else look for an image type:
        NSString *type = [pb availableTypeFromArray: [NSImage imageUnfilteredPasteboardTypes]];
        if( type ) {
            NSData *data = [pb dataForType: type];
            src = CGImageSourceCreateWithData((CFDataRef)data, NULL);
        }
    }
    if(src) {
        CGImageRef image = CGImageSourceCreateImageAtIndex(src, 0, NULL);
        CFRelease(src);
        return image;
    } else
        return NULL;
}    


float GetPixelAlpha( CGImageRef image, CGSize imageSize, CGPoint pt )
{
    // Trivial reject:
    if( pt.x<0 || pt.x>=imageSize.width || pt.y<0 || pt.y>=imageSize.height )
        return 0.0;
    
    // sTinyContext is a 1x1 CGBitmapContext whose pixmap stores only alpha.
    static UInt8 sPixel[1];
    static CGContextRef sTinyContext;
    if( ! sTinyContext ) {
        sTinyContext = CGBitmapContextCreate(sPixel, 1, 1, 
                                             8, 1,     // bpp, rowBytes
                                             NULL,
                                             kCGImageAlphaOnly);
        CGContextSetBlendMode(sTinyContext, kCGBlendModeCopy);
    }
    
    // Draw the image into sTinyContext, positioned so the desired point is at
    // (0,0), then examine the alpha value in the pixmap:
    CGContextDrawImage(sTinyContext, 
                       CGRectMake(-pt.x,-pt.y, imageSize.width,imageSize.height),
                       image);
    return sPixel[0] / 255.0;
}


#pragma mark -
#pragma mark PATTERNS:


// callback for CreateImagePattern.
static void drawPatternImage (void *info, CGContextRef ctx)
{
    CGImageRef image = (CGImageRef) info;
    CGContextDrawImage(ctx, 
                       CGRectMake(0,0, CGImageGetWidth(image),CGImageGetHeight(image)),
                       image);
}

// callback for CreateImagePattern.
static void releasePatternImage( void *info )
{
    CGImageRelease( (CGImageRef)info );
}


CGPatternRef CreateImagePattern( CGImageRef image )
{
    NSCParameterAssert(image);
    int width = CGImageGetWidth(image);
    int height = CGImageGetHeight(image);
    static const CGPatternCallbacks callbacks = {0, &drawPatternImage, &releasePatternImage};
    return CGPatternCreate (image,
                            CGRectMake (0, 0, width, height),
                            CGAffineTransformMake (1, 0, 0, 1, 0, 0),
                            width,
                            height,
                            kCGPatternTilingConstantSpacing,
                            true,
                            &callbacks);
}


CGColorRef CreatePatternColor( CGImageRef image )
{
    CGPatternRef pattern = CreateImagePattern(image);
    CGColorSpaceRef space = CGColorSpaceCreatePattern(NULL);
    CGFloat components[1] = {1.0};
    CGColorRef color = CGColorCreateWithPattern(space, pattern, components);
    CGColorSpaceRelease(space);
    CGPatternRelease(pattern);
    return color;
}
