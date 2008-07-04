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
#import "Bit.h"
#import "Game.h"
#import "Player.h"
#import "QuartzUtils.h"


#ifdef TARGET_OS_IPHONE
#define kPickedUpScale   2.0      // more magnification, so piece shows up underneath fingertip
#define kPickedUpOpacity 0.6
#else
#define kPickedUpScale   1.2
#define kPickedUpOpacity 0.9
#endif


@implementation Bit


- (id) copyWithZone: (NSZone*)zone
{
    Bit *clone = [super copyWithZone: zone];
    clone->_owner = _owner;
    return clone;
}

- (void) dealloc
{
    [super dealloc];
}


@synthesize owner=_owner;

- (BOOL) isFriendly         {return _owner.friendly;}
- (BOOL) isUnfriendly       {return _owner.unfriendly;}

/*
- (NSString*) identifier
{
    if( _identifier )
        return _identifier;
    // Defaults to just identifying the owner:
    return [NSString stringWithFormat: @"p%i", _owner.index+1];
}
*/

- (CGFloat) scale
{
    NSNumber *scale = [self valueForKeyPath: @"transform.scale"];
    return scale.floatValue;
}

- (void) setScale: (CGFloat)scale
{
    [self setValue: [NSNumber numberWithFloat: scale]
        forKeyPath: @"transform.scale"];
}


- (int) rotation
{
    NSNumber *rot = [self valueForKeyPath: @"transform.rotation"];
    return round( rot.doubleValue * 180.0 / M_PI );
}

- (void) setRotation: (int)rotation
{
    [self setValue: [NSNumber numberWithDouble: rotation*M_PI/180.0]
        forKeyPath: @"transform.rotation"];
}


- (BOOL) pickedUp
{
    return _pickedUp;
}

- (void) setPickedUp: (BOOL)up
{
    if( up != _pickedUp ) {
        CGFloat shadow, offset, radius, opacity, z, scale;
        if( up ) {
            shadow = 0.8;
            offset = 2;
            radius = 8;
            opacity = kPickedUpOpacity;
            scale = kPickedUpScale;
            z = kPickedUpZ;
            _restingZ = self.zPosition;
        } else {
            shadow = offset = radius = 0.0;
            opacity = 1.0;
            scale = 1.0/kPickedUpScale;
            z = _restingZ;
        }

        //self.zPosition = z;
#if !TARGET_OS_IPHONE
        self.shadowOpacity = shadow;
        self.shadowOffset = CGSizeMake(offset,-offset);
        self.shadowRadius = radius;
#endif
        self.opacity = opacity;
        self.scale *= scale;
        _pickedUp = up;
    }
}


- (BOOL)containsPoint:(CGPoint)p
{
    // Make picked-up pieces invisible to hit-testing.
    // Otherwise, while dragging a Bit, hit-testing the cursor position would always return
    // that Bit, since it's directly under the cursor...
    if( self.pickedUp )
        return NO;
    else
        return [super containsPoint: p];
}


-(id<BitHolder>) holder
{
    // Look for my nearest ancestor that's a BitHolder:
    for( CALayer *layer=self.superlayer; layer; layer=layer.superlayer ) {
        if( [layer conformsToProtocol: @protocol(BitHolder)] )
            return (id<BitHolder>)layer;
        else if( [layer isKindOfClass: [Bit class]] )
            return nil;
    }
    return nil;
}


- (void) destroy
{
    // "Pop" the Bit by expanding it 5x as it fades away:
    self.scale = 5;
    self.opacity = 0.0;
    // Removing the view from its superlayer right now would cancel the animations.
    // Instead, defer the removal until sometime shortly after the animations finish:
    [self performSelector: @selector(removeFromSuperlayer) withObject: nil afterDelay: 1.0];
}


@end
