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
#import <QuartzCore/QuartzCore.h>
#import "Piece.h"
#import "GGBUtils.h"


CGColorRef kBlackColor, kWhiteColor, 
           kTranslucentGrayColor, kTranslucentLightGrayColor,
           kTranslucentWhiteColor, kAlmostInvisibleWhiteColor,
           kHighlightColor;


__attribute__((constructor))        // Makes this function run when the app loads
static void InitQuartzUtils()
{
    kBlackColor = CreateGray(0.0, 1.0);
    kWhiteColor = CreateGray(1.0, 1.0);
    kTranslucentGrayColor = CreateGray(0.0, 0.5);
    kTranslucentLightGrayColor = CreateGray(0.0, 0.25);
    kTranslucentWhiteColor = CreateGray(1, 0.25);
    kAlmostInvisibleWhiteColor = CreateGray(1, 0.05);
    kHighlightColor = CreateRGB(1, 1, 0, 0.5);
}


#if TARGET_OS_IPHONE
CGColorRef CreateGray(CGFloat gray, CGFloat alpha)
{
    CGColorSpaceRef graySpace = CGColorSpaceCreateDeviceGray();
    CGFloat components[2] = {gray,alpha};
    CGColorRef color = CGColorCreate(graySpace, components);
    CGColorSpaceRelease(graySpace);
    return color;
}

CGColorRef CreateRGB(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha)
{
    CGColorSpaceRef rgbSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat components[4] = {red,green,blue,alpha};
    CGColorRef color = CGColorCreate(rgbSpace, components);
    CGColorSpaceRelease(rgbSpace);
    return color;
}
#endif


CGImageRef CreateCGImageFromFile( NSString *path )
{
#if TARGET_OS_IPHONE
    UIImage *uiImage = [UIImage imageWithContentsOfFile: path];
    if(!uiImage) Warn(@"UIImage imageWithContentsOfFile failed on file %@",path);
    return CGImageRetain(uiImage.CGImage);
#else
    CGImageRef image = NULL;
    CFURLRef url = (CFURLRef) [NSURL fileURLWithPath: path];
    CGImageSourceRef src = CGImageSourceCreateWithURL(url, NULL);
    if( src ) {
        image = CGImageSourceCreateImageAtIndex(src, 0, NULL);
        CFRelease(src);
        if(!image) Warn(@"CGImageSourceCreateImageAtIndex failed on file %@ (ptr size=%lu)",path,sizeof(void*));
    }
    return image;
#endif
}


CGImageRef GetCGImageNamed( NSString *name )
{
#if TARGET_OS_IPHONE
    name = name.lastPathComponent;
    UIImage *uiImage = [UIImage imageNamed: name];
    NSCAssert1(uiImage,@"Couldn't find bundle image resource '%@'",name);
    return uiImage.CGImage;
#else
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
            NSString *dir = [name stringByDeletingLastPathComponent];
            name = [name lastPathComponent];
            NSString *ext = name.pathExtension;
            name = [name stringByDeletingPathExtension];
            path = [[NSBundle mainBundle] pathForResource: name ofType: ext inDirectory: dir];
            NSCAssert3(path,@"Couldn't find bundle image resource '%@' type '%@' in '%@'",name,ext,dir);
        }
        image = CreateCGImageFromFile(path);
        NSCAssert1(image,@"Failed to load image from %@",path);
        [sMap setObject: (id)image forKey: name];
        CGImageRelease(image);
    }
    return image;
#endif
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


#if ! TARGET_OS_IPHONE

BOOL CanGetCGImageFromPasteboard( NSPasteboard *pb )
{
    return [NSImage canInitWithPasteboard: pb] 
        || [[pb types] containsObject: @"PixadexIconPathPboardType"];

    /*if( [[pb types] containsObject: NSFilesPromisePboardType] ) {
     NSArray *fileTypes = [pb propertyListForType: NSFilesPromisePboardType];
     NSLog(@"Got file promise! Types = %@",fileTypes);
     //FIX: Check file types
     return NSDragOperationCopy;
     }*/
}    

CGImageRef GetCGImageFromPasteboard( NSPasteboard *pb, id<NSDraggingInfo>dragInfo )
{
    CGImageSourceRef src = NULL;
    NSArray *paths = [pb propertyListForType: NSFilenamesPboardType];
    if( paths.count==1 ) {
        // If a file is being dragged, read it:
        CFURLRef url = (CFURLRef) [NSURL fileURLWithPath: [paths objectAtIndex: 0]];
        src = CGImageSourceCreateWithURL(url, NULL);
/*
    } else if( dragInfo && [[pb types] containsObject:NSFilesPromisePboardType] ) {
        NSString *dropDir = NSTemporaryDirectory();
        NSArray *filenames = [dragInfo namesOfPromisedFilesDroppedAtDestination: [NSURL fileURLWithPath: dropDir]];
        NSLog(@"promised files are %@ / %@", dropDir,filenames);
        src = nil; */
    } else if( [[pb types] containsObject: @"PixadexIconPathPboardType"] ) {
        // Candybar 3 (nee Pixadex) doesn't drag out icons in any normal image type.
        // It does support file-promises, but I couldn't get those to work using the Cocoa APIs.
        // So instead I'm using its custom type that provides the path(s) to its internal ".pxicon" files.
        // The icon is really easy to get from one of these: it's just file's custom icon.
        NSArray *files = [pb propertyListForType: @"PixadexIconPathPboardType"];
        if( files.count == 1 ) {
            NSString *path = [files objectAtIndex: 0];
            NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile: path];
            for( NSImageRep *rep in icon.representations ) {
                if( [rep isKindOfClass: [NSBitmapImageRep class]] ) {
                    [rep retain];   //FIX: This leaks; but if the rep goes away, the CGImage breaks...
                    return [(NSBitmapImageRep*)rep CGImage];
                }
            }
        }
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
#endif


CGImageRef CreateScaledImage( CGImageRef srcImage, CGFloat scale )
{
    int width = CGImageGetWidth(srcImage), height = CGImageGetHeight(srcImage);
    if( scale > 0 ) {
        if( scale >= 4.0 )
            scale /= MAX(width,height);             // interpret scale as target dimensions
        width = ceil( width * scale);
        height= ceil( height* scale);
    }

    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 4*width, space,
                                             kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(space);
    CGContextSetInterpolationQuality(ctx,kCGInterpolationHigh);
    CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), srcImage);
    CGImageRef dstImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    return dstImage;
}


CGImageRef GetScaledImageNamed( NSString *imageName, CGFloat scale )
{
    // For efficiency, loaded images are cached in a dictionary by name.
    static NSMutableDictionary *sMap;
    if( ! sMap )
        sMap = [[NSMutableDictionary alloc] init];
    
    NSArray *key = [NSArray arrayWithObjects: imageName, [NSNumber numberWithFloat: scale], nil];
    CGImageRef image = (CGImageRef) [sMap objectForKey: key];
    if( ! image ) {
        // Hasn't been cached yet, so load it:
        image = CreateScaledImage(GetCGImageNamed(imageName), scale);
        [sMap setObject: (id)image forKey: key];
        CGImageRelease(image);
    }
    return image;
}


float GetPixelAlpha( CGImageRef image, CGSize imageSize, CGPoint pt )
{
    NSCParameterAssert(image);
#if TARGET_OS_IPHONE
    // iPhone uses "flipped" (i.e. normal) coords, so images are wrong-way-up
    pt.y = imageSize.height - pt.y;
#endif
    
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
                                             (CGBitmapInfo)kCGImageAlphaOnly);
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


#pragma mark -
#pragma mark PATHS:


void AddRoundRect( CGContextRef ctx, CGRect rect, CGFloat radius )
{
    radius = MIN(radius, floorf(rect.size.width/2));
    float x0 = CGRectGetMinX(rect), y0 = CGRectGetMinY(rect),
    x1 = CGRectGetMaxX(rect), y1 = CGRectGetMaxY(rect);
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx,x0+radius,y0);
    CGContextAddArcToPoint(ctx,x1,y0, x1,y1, radius);
    CGContextAddArcToPoint(ctx,x1,y1, x0,y1, radius);
    CGContextAddArcToPoint(ctx,x0,y1, x0,y0, radius);
    CGContextAddArcToPoint(ctx,x0,y0, x1,y0, radius);
    CGContextClosePath(ctx);
}

