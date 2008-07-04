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
#import "GGBLayer.h"


/** Constants for various commonly used colors. */
extern CGColorRef kBlackColor, kWhiteColor, 
                  kTranslucentGrayColor, kTranslucentLightGrayColor, 
                  kTranslucentWhiteColor, kAlmostInvisibleWhiteColor,
                  kHighlightColor;

#if TARGET_OS_IPHONE
// These don't exist on iPhone, so I implement them:
CGColorRef CreateGray(CGFloat gray, CGFloat alpha);
CGColorRef CreateRGB(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha);
#else
#define CreateGray  CGColorCreateGenericGray
#define CreateRGB   CGColorCreateGenericRGB
#endif


/** Loads an image or pattern file into a CGImage or CGPattern.
    If the name begins with "/", it's interpreted as an absolute filesystem path.
    Otherwise, it's the name of a resource that's looked up in the app bundle.
    The image must exist, or an assertion-failure exception will be raised!
    Loaded images/patterns are cached in memory, so subsequent calls with the same name
    are very fast.
    The caller must NOT release the result, since it's retained in the cache. */
CGImageRef GetCGImageNamed( NSString *name );
CGColorRef GetCGPatternNamed( NSString *name );

#if ! TARGET_OS_IPHONE
/** Loads image data from the pasteboard into a CGImage. */
CGImageRef GetCGImageFromPasteboard( NSPasteboard *pb );
#endif

CGImageRef CreateScaledImage( CGImageRef srcImage, CGFloat scale );
CGImageRef GetScaledImageNamed( NSString *imageName, CGFloat scale );

/** Creates a CGPattern from a CGImage. Caller must release it. */
CGPatternRef CreateImagePattern( CGImageRef image );

/** Creates a CGColor that draws the given CGImage as a pattern. Caller must release it. */
CGColorRef CreatePatternColor( CGImageRef image );

/** Returns the alpha value of a single pixel in a CGImage, scaled to a particular size. */
float GetPixelAlpha( CGImageRef image, CGSize imageSize, CGPoint pt );

/** Returns the center point of a CGRect. */
static inline CGPoint GetCGRectCenter( CGRect rect ) {
    return CGPointMake(CGRectGetMidX(rect),CGRectGetMidY(rect));
}

void AddRoundRect( CGContextRef ctx, CGRect rect, CGFloat radius );
