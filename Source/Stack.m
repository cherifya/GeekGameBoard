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
#import "Stack.h"
#import "QuartzUtils.h"


@implementation Stack


- (id) initWithStartPos: (CGPoint)startPos spacing: (CGSize)spacing
           wrapInterval: (int)wrapInterval wrapSpacing: (CGSize)wrapSpacing
{
    self = [super init];
    if (self != nil) {
        _startPos = startPos;
        _spacing = spacing;
        _wrapInterval = wrapInterval;
        _wrapSpacing = wrapSpacing;
        self.cornerRadius = 8;
        self.backgroundColor = kAlmostInvisibleWhiteColor;
        self.borderColor = kHighlightColor;
        _bits = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id) initWithStartPos: (CGPoint)startPos spacing: (CGSize)spacing;
{
    return [self initWithStartPos: startPos spacing: spacing 
                     wrapInterval: INT_MAX wrapSpacing: CGSizeZero];
}


- (void) dealloc
{
    [_bits release];
    [super dealloc];
}


@synthesize spacing=_spacing, wrapSpacing=_wrapSpacing, startPos=_startPos, wrapInterval=_wrapInterval;
@synthesize dragAsStacks=_dragAsStacks;
@synthesize bits=_bits;


- (Bit*) topBit
{
    return [_bits lastObject];
}


- (void) dump
{
    printf("Stack = ");
    for( CALayer *layer in self.sublayers )
        printf("%s @z=%g   ", [[layer description] UTF8String],layer.zPosition);
    printf("\n");
}


- (void) x_repositionBit: (Bit*)bit forIndex: (int)i
{
    bit.position = CGPointMake(_startPos.x + _spacing.width *(i%_wrapInterval) + _wrapSpacing.width *(i/_wrapInterval),
                               _startPos.y + _spacing.height*(i%_wrapInterval) + _wrapSpacing.height*(i/_wrapInterval));
}

- (void) addBit: (Bit*)bit
{
    if( [bit isKindOfClass: [DraggedStack class]] ) {
        for( Bit *subBit in [(DraggedStack*)bit bits] )
            [self addBit: subBit];
    } else {
        int n = _bits.count;
        [_bits addObject: bit];
        ChangeSuperlayer(bit, self, n);
        [self x_repositionBit: bit forIndex: n];
    }
}


- (void) setHighlighted: (BOOL)highlighted
{
    [super setHighlighted: highlighted];
    self.borderWidth = (highlighted ?6 :0);
}


- (Bit*) canDragBit: (Bit*)bit
{
    NSInteger index = [_bits indexOfObjectIdenticalTo: bit];
    if( index==NSNotFound )
        return nil;
    if( _dragAsStacks && index < _bits.count-1 ) {
        // Move bit and those above it into a temporary DraggedStack:
        NSRange r = NSMakeRange(index,_bits.count-index);
        NSArray *bitsToDrag = [_bits subarrayWithRange: r];
        [_bits removeObjectsInRange: r];
        DraggedStack *stack = [[DraggedStack alloc] initWithBits: bitsToDrag];
        [self addSublayer: stack];
        [stack release];
        stack.anchorPoint = CGPointMake( bit.position.x/stack.bounds.size.width,
                                         bit.position.y/stack.bounds.size.height );
        stack.position = bit.position;
        return stack;
    } else {
        [bit retain];
        [_bits removeObjectIdenticalTo: bit];
        return [bit autorelease];
    }
}


- (void) cancelDragBit: (Bit*)bit
{
    [self addBit: bit];
    if( [bit isKindOfClass: [DraggedStack class]] ) {
        [bit removeFromSuperlayer];
    }
}


- (void) draggedBit: (Bit*)bit to: (id<BitHolder>)dst
{
    int i=0;
    for( Bit *bit in self.sublayers )
        [self x_repositionBit: bit forIndex: i++];
}


- (BOOL) dropBit: (Bit*)bit atPoint: (CGPoint)point
{
    [self addBit: bit];
    return YES;
}

@end




@implementation DraggedStack


- (id) initWithBits: (NSArray*)bits
{
    self = [super init];
    if( self ) {
        CGRect bounds = CGRectZero;
        for( Bit *bit in bits ) {
            bounds = CGRectUnion(bounds, bit.frame);
            [self addSublayer: bit];
        }
        self.bounds = bounds;
        self.anchorPoint = CGPointZero;
        self.position = CGPointZero;
    }
    return self;
}

- (NSArray*) bits
{
    return [self.sublayers.copy autorelease];
}

@end
