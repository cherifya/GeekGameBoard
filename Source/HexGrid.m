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
#import "HexGrid.h"
#import "Game.h"


@implementation HexGrid


- (id) initWithRows: (unsigned)nRows columns: (unsigned)nColumns
            spacing: (CGSize)spacing
           position: (CGPoint)pos
{
    // Ignore given spacing.height; set it to make the hexagons regular.
    CGFloat capHeight = spacing.height / 2 * tan(M_PI/6);
    CGFloat side = spacing.height / 2 / cos(M_PI/6);
    spacing.height = side + capHeight;
    
    self = [super initWithRows: nRows columns: nColumns
                       spacing: spacing
                      position: pos];
    if( self ) {
        _capHeight = capHeight;
        _side = side;
        self.bounds = CGRectMake(-1, -1, 
                                 (nColumns+0.5)*spacing.width + 2,
                                 nRows*spacing.height+capHeight + 2);
        _cellClass = [Hex class];
    }
    return self;
}


- (id) initWithRows: (unsigned)nRows columns: (unsigned)nColumns
              frame: (CGRect)frame;
{
    // Compute the horizontal spacing:
    CGFloat s = floor(MIN( (frame.size.width -2.0)/nColumns,
                         (frame.size.height-2.0)/(nRows+0.5*tan(M_PI/6)) / (0.5*(tan(M_PI/6)+1/cos(M_PI/6))) ));
    self = [self initWithRows: nRows columns: nColumns
                      spacing: CGSizeMake(s,s)
                     position: frame.origin];
    if( self ) {
        // Center in frame:
        CGRect curFrame = self.frame;
        curFrame.origin.x = round( curFrame.origin.x + (frame.size.width - curFrame.size.width )/2.0f );
        curFrame.origin.y = round( curFrame.origin.y + (frame.size.height- curFrame.size.height)/2.0f );
        self.frame = curFrame;
    }
    return self;
}
    
    
- (void) dealloc
{
    CGPathRelease(_cellPath);
    [super dealloc];
}


- (void) addCellsInHexagon
{
    int size = _nRows - !(_nRows & 1);      // make it odd
    for( int row=0; row<_nRows; row++ ) {
        int n;                              // # of hexes remaining in this row
        if( row < size )
            n = size - abs(row-size/2);
        else
            n = 0;
        int c0 = floor(((int)_nRows+1-n -(row&1))/2.0);       // col of 1st remaining hex

        for( int col=0; col<_nColumns; col++ )
            if( col>=c0 && col<c0+n )
                [self addCellAtRow: row column: col];
    }
}


- (GridCell*) createCellAtRow: (unsigned)row column: (unsigned)col 
               suggestedFrame: (CGRect)frame
{
    // Overridden to stagger the odd-numbered rows
    if( row & 1 )
        frame.origin.x += _spacing.width/2;
    frame.size.height += _capHeight;
    return [super createCellAtRow: row column: col suggestedFrame: frame];
}


// Returns a hexagonal CG path defining a cell's outline. Used by cells when drawing & hit-testing.
- (CGPathRef) cellPath
{
    if( ! _cellPath ) {
        CGFloat x1 = _spacing.width/2;
        CGFloat x2 = _spacing.width;
        CGFloat y1 = _capHeight;
        CGFloat y2 = y1 + _side;
        CGFloat y3 = y2 + _capHeight;
        CGPoint p[6] = { {0,y1}, {x1,0}, {x2,y1}, {x2,y2}, {x1,y3}, {0,y2} };
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddLines(path, NULL, p, 6);
        CGPathCloseSubpath(path);
        _cellPath = path;
    }
    return _cellPath;
}


@end





#pragma mark -

@implementation Hex


- (void) drawInParentContext: (CGContextRef)ctx fill: (BOOL)fill
{
    CGContextSaveGState(ctx);
    CGPoint pos = self.position;
    CGContextTranslateCTM(ctx, pos.x, pos.y);
    CGContextBeginPath(ctx);
    CGContextAddPath(ctx, ((HexGrid*)_grid).cellPath);
    CGContextDrawPath(ctx, (fill ?kCGPathFill :kCGPathStroke));
    
    if( !fill && self.highlighted ) {
        // Highlight by drawing my outline in the highlight color:
        CGContextSetStrokeColorWithColor(ctx, self.borderColor);
        CGContextSetLineWidth(ctx,6);
        CGContextBeginPath(ctx);
        CGContextAddPath(ctx, ((HexGrid*)_grid).cellPath);
        CGContextDrawPath(ctx, kCGPathStroke);
    }
    CGContextRestoreGState(ctx);
}


- (BOOL)containsPoint:(CGPoint)p
{
    return [super containsPoint: p]
        && CGPathContainsPoint( ((HexGrid*)_grid).cellPath, NULL, p, NO );
}


- (void) setHighlighted: (BOOL)highlighted
{
    if( highlighted != self.highlighted ) {
        [super setHighlighted: highlighted];
        [_grid setNeedsDisplay];        // So I'll be asked to redraw myself
    }
}


#pragma mark -
#pragma mark NEIGHBORS:


- (NSArray*) neighbors
{
    NSMutableArray *neighbors = [NSMutableArray arrayWithCapacity: 6];
    Hex* n[6] = {self.nw, self.ne, self.w, self.e, self.sw, self.se};
    for( int i=0; i<6; i++ )
        if( n[i] )
            [neighbors addObject: n[i]];
    return neighbors;
}

- (Hex*) nw     {return (Hex*)[_grid cellAtRow: _row+1 column: _column - ((_row+1)&1)];}
- (Hex*) ne     {return (Hex*)[_grid cellAtRow: _row+1 column: _column + (_row&1)];}
- (Hex*) e      {return (Hex*)[_grid cellAtRow: _row   column: _column + 1];}
- (Hex*) se     {return (Hex*)[_grid cellAtRow: _row-1 column: _column + (_row&1)];}
- (Hex*) sw     {return (Hex*)[_grid cellAtRow: _row-1 column: _column - ((_row-1)&1)];}
- (Hex*) w      {return (Hex*)[_grid cellAtRow: _row   column: _column - 1];}

// Directions relative to the current player:
- (Hex*) fl     {return self.fwdIsN ?self.nw :self.se;}
- (Hex*) fr     {return self.fwdIsN ?self.ne :self.sw;}
- (Hex*) r      {return self.fwdIsN ?self.e  :self.w;}
- (Hex*) br     {return self.fwdIsN ?self.se :self.nw;}
- (Hex*) bl     {return self.fwdIsN ?self.sw :self.ne;}
- (Hex*) l      {return self.fwdIsN ?self.w  :self.e;}


@end
