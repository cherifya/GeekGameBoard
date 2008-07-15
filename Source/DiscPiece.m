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
#import "DiscPiece.h"
#import "QuartzUtils.h"


@implementation DiscPiece


- (void) _setImage: (CGImageRef)image
{
    CGFloat diameter = MAX(CGImageGetWidth(image),CGImageGetHeight(image));
    CGFloat outerDiameter = round(diameter * 1.1);
    self.bounds = CGRectMake(0,0,outerDiameter,outerDiameter);

    if( ! _imageLayer ) {
        _imageLayer = [[CALayer alloc] init];
        _imageLayer.contentsGravity = @"resizeAspect";
        _imageLayer.masksToBounds = YES;
        [self addSublayer: _imageLayer];
        [_imageLayer release]; // superlayer is holding onto it
    }
    _imageLayer.frame = CGRectInset(self.bounds, outerDiameter-diameter, outerDiameter-diameter);
#if !TARGET_OS_IPHONE
    _imageLayer.cornerRadius = diameter/2;
#endif
    _imageLayer.contents = (id) image;
    self.cornerRadius = outerDiameter/2;
    self.borderWidth = 3;
    self.borderColor = kTranslucentLightGrayColor;
    self.imageName = nil;
}


@end
