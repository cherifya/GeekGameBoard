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
#import "Grid.h"
#import "Bit.h"
#import "Piece.h"
#import "Game+Protected.h"
#import "Player.h"
#import "QuartzUtils.h"


@interface GridCell ()
- (void) setBitTransform: (CATransform3D)bitTransform;
@end


@implementation Grid


- (id) initWithRows: (unsigned)nRows columns: (unsigned)nColumns
            spacing: (CGSize)spacing
           position: (CGPoint)pos
{
    NSParameterAssert(nRows>0 && nColumns>0);
    self = [super init];
    if( self ) {
        _nRows = nRows;
        _nColumns = nColumns;
        _spacing = spacing;
        _cellClass = [GridCell class];
        self.lineColor = kBlackColor;
        _allowsMoves = YES;
        _usesDiagonals = YES;
        _bitTransform = CATransform3DIdentity;

        self.bounds = CGRectMake(-1, -1, nColumns*spacing.width+2, nRows*spacing.height+2);
        self.position = pos;
        self.anchorPoint = CGPointMake(0,0);
        self.zPosition = kBoardZ;
        self.needsDisplayOnBoundsChange = YES;
        
        unsigned n = nRows*nColumns;
        _cells = [[NSMutableArray alloc] initWithCapacity: n];
        id null = [NSNull null];
        while( n-- > 0 )
            [_cells addObject: null];

        [self setNeedsDisplay];
    }
    return self;
}


- (id) initWithRows: (unsigned)nRows columns: (unsigned)nColumns
              frame: (CGRect)frame
{
    CGFloat spacing = floor(MIN( (frame.size.width -2)/(CGFloat)nColumns,
                               (frame.size.height-2)/(CGFloat)nRows) );
    CGSize size = CGSizeMake(nColumns*spacing+2, nRows*spacing+2);
    CGPoint position = frame.origin;
    position.x += round( (frame.size.width -size.width )/2.0 );
    position.y += round( (frame.size.height-size.height)/2.0 );

    return [self initWithRows: nRows columns: nColumns
                      spacing: CGSizeMake(spacing,spacing)
                     position: position];
}


- (void) dealloc
{
    CGColorRelease(_cellColor);
    CGColorRelease(_lineColor);
    [_cells release];
    [super dealloc];
}


static void setcolor( CGColorRef *var, CGColorRef color )
{
    if( color != *var ) {
        CGColorRelease(*var);
        *var = CGColorRetain(color);
    }
}

- (CGColorRef) cellColor                        {return _cellColor;}
- (void) setCellColor: (CGColorRef)cellColor    {setcolor(&_cellColor,cellColor);}

- (CGColorRef) lineColor                        {return _lineColor;}
- (void) setLineColor: (CGColorRef)lineColor    {setcolor(&_lineColor,lineColor);}

- (CGImageRef) backgroundImage                  {return _backgroundImage;}
- (void) setBackgroundImage: (CGImageRef)image
{
    if( image != _backgroundImage ) {
        CGImageRelease(_backgroundImage);
        _backgroundImage = CGImageRetain(image);
    }
}

@synthesize cellClass=_cellClass, rows=_nRows, columns=_nColumns, spacing=_spacing, reversed=_reversed,
            usesDiagonals=_usesDiagonals, allowsMoves=_allowsMoves, allowsCaptures=_allowsCaptures,
            bitTransform=_bitTransform;


#pragma mark -
#pragma mark GEOMETRY:


- (GridCell*) cellAtRow: (unsigned)row column: (unsigned)col
{
    if( row < _nRows && col < _nColumns ) {
        id cell = [_cells objectAtIndex: row*_nColumns+col];
        if( cell != [NSNull null] )
            return cell;
    }
    return nil;
}


/** Subclasses can override this, to change the cell's class or frame. */
- (GridCell*) createCellAtRow: (unsigned)row column: (unsigned)col 
               suggestedFrame: (CGRect)frame
{
    GridCell *cell = [[_cellClass alloc] initWithGrid: self 
                                                  row: row column: col
                                                frame: frame];
    cell.name = [NSString stringWithFormat: @"%c%u", ('A'+row),(1+col)];
    return [cell autorelease];
}


- (GridCell*) addCellAtRow: (unsigned)row column: (unsigned)col
{
    NSParameterAssert(row<_nRows);
    NSParameterAssert(col<_nColumns);
    unsigned index = row*_nColumns+col;
    GridCell *cell = [_cells objectAtIndex: index];
    if( (id)cell == [NSNull null] ) {
        unsigned effectiveRow=row, effectiveCol=col;
        if( _reversed ) {
            effectiveRow = _nRows-1    - effectiveRow;
            effectiveCol = _nColumns-1 - effectiveCol;
        }
        CGRect frame = CGRectMake(effectiveCol*_spacing.width, effectiveRow*_spacing.height,
                                  _spacing.width,_spacing.height);
        cell = [self createCellAtRow: row column: col suggestedFrame: frame];
        if( cell ) {
            [_cells replaceObjectAtIndex: index withObject: cell];
            //[self addSublayer: cell];
            [self insertSublayer: cell atIndex: 0];
            [self setNeedsDisplay];
        }
    }
    return cell;
}


- (void) addAllCells
{
    for( int row=_nRows-1; row>=0; row-- )                // makes 'upper' cells be in 'back'
        for( int col=0; col<_nColumns; col++ ) 
            [self addCellAtRow: row column: col];
}


- (void) removeCellAtRow: (unsigned)row column: (unsigned)col
{
    NSParameterAssert(row<_nRows);
    NSParameterAssert(col<_nColumns);
    unsigned index = row*_nColumns+col;
    id cell = [_cells objectAtIndex: index];
    if( cell != [NSNull null] )
        [cell removeFromSuperlayer];
    [_cells replaceObjectAtIndex: index withObject: [NSNull null]];
    [self setNeedsDisplay];
}


- (NSArray*) cells
{
    NSMutableArray *cells = [_cells mutableCopy];
    for( int i=cells.count-1; i>=0; i-- )
        if( [cells objectAtIndex: i] == [NSNull null] )
            [cells removeObjectAtIndex: i];
    return cells;
}


- (GridCell*) cellWithName: (NSString*)name
{
    for( CALayer *layer in self.sublayers )
        if( [layer isKindOfClass: [GridCell class]] )
            if( [name isEqualToString: ((GridCell*)layer).name] )
                return (GridCell*)layer;
    return nil;
}


- (NSCountedSet*) countPiecesByPlayer
{
    NSCountedSet *players = [NSCountedSet set];
    for( GridCell *cell in self.cells ) {
        Player *owner = cell.bit.owner;
        if( owner )
            [players addObject: owner];
    }
    return players;
}


- (CATransform3D) bitTransform
{
    return _bitTransform;
}

- (void) setBitTransform: (CATransform3D)t
{
    _bitTransform = t;
    for( GridCell *cell in self.cells )
        [cell setBitTransform: t];
}

- (void) updateCellTransform
{
    CATransform3D t = self.aggregateTransform;
    t.m41 = t.m42 = t.m43 = 0.0f;           // remove translation component
    t = CATransform3DInvert(t);
    self.bitTransform = t;
}


#pragma mark -
#pragma mark GAME STATE:


- (NSString*) stateString
{
    NSMutableString *state = [NSMutableString stringWithCapacity: _cells.count];
    for( GridCell *cell in self.cells ) {
        Bit *bit = cell.bit;
        NSString *name = bit ?bit.name :@"-";
        NSAssert(name.length==1,@"Missing or multicharacter name");
        [state appendString: name];
    }
    return state;
}

- (void) setStateString: (NSString*)state
{
    Game *game = self.game;
    int i = 0;
    for( GridCell *cell in self.cells )
        cell.bit = [game makePieceNamed: [state substringWithRange: NSMakeRange(i++,1)]];
}


- (BOOL) applyMoveString: (NSString*)move
{
    GridCell *src = nil;
    for( NSString *ident in [move componentsSeparatedByString: @"-"] ) {
        while( [ident hasSuffix: @"!"] || [ident hasSuffix: @"*"] )
            ident = [ident substringToIndex: ident.length-1];
        GridCell *dst = [self cellWithName: ident];
        if( dst == nil )
            return NO;
        if( src && ! [self.game animateMoveFrom: src to: dst] )
            return NO;
        src = dst;
    }
    return YES;
}


#pragma mark -
#pragma mark DRAWING:


- (void) drawCellsInContext: (CGContextRef)ctx fill: (BOOL)fill
{
    // Subroutine of -drawInContext:. Draws all the cells, with or without a fill.
    for( unsigned row=0; row<_nRows; row++ )
        for( unsigned col=0; col<_nColumns; col++ ) {
            GridCell *cell = [self cellAtRow: row column: col];
            if( cell )
                [cell drawInParentContext: ctx fill: fill];
        }
}

- (void) drawBackgroundInContext: (CGContextRef)ctx
{
    if( _backgroundImage ) {
        CGRect bounds = self.bounds;
        if( _reversed ) {
            CGContextSaveGState(ctx);
            CGContextRotateCTM(ctx, M_PI);
            CGContextTranslateCTM(ctx, -bounds.size.width, -bounds.size.height);
        }
        CGContextDrawImage(ctx, bounds, _backgroundImage);
        if( _reversed )
            CGContextRestoreGState(ctx);
    }
}


- (void)drawInContext:(CGContextRef)ctx
{
    // Custom CALayer drawing implementation. Delegates to the cells to draw themselves
    // in me; this is more efficient than having each cell have its own drawing.
    [super drawInContext: ctx];
    
    [self drawBackgroundInContext: ctx];
    
    if( _cellColor ) {
        CGContextSetFillColorWithColor(ctx, _cellColor);
        [self drawCellsInContext: ctx fill: YES];
    }
    if( _lineColor ) {
        CGContextSetStrokeColorWithColor(ctx,_lineColor);
        [self drawCellsInContext:ctx fill: NO];
    }
}


@end



#pragma mark -

@implementation GridCell


- (id) initWithGrid: (Grid*)grid 
                row: (unsigned)row column: (unsigned)col
              frame: (CGRect)frame
{
    self = [super init];
    if (self != nil) {
        _grid = grid;
        _row = row;
        _column = col;
        self.anchorPoint = CGPointMake(0,0);
        self.position = frame.origin;
        CGRect bounds = frame;
        bounds.origin.x -= floor(bounds.origin.x);  // make sure my coords fall on pixel boundaries
        bounds.origin.y -= floor(bounds.origin.y);
        self.bounds = bounds;
        self.borderColor = kHighlightColor;         // Used when highlighting (see -setHighlighted:)
        [self setBitTransform: grid.bitTransform];
    }
    return self;
}

- (NSString*) description
{
    return [NSString stringWithFormat: @"%@(%u,%u)", [self class],_column,_row];
}

@synthesize grid=_grid, row=_row, column=_column;


- (void) setBitTransform: (CATransform3D)bitTransform
{
    // To make the bitTransform relative to my center, I need to offset the center to the origin
    // first, and then back afterwards.
    CGSize size = self.bounds.size;
    CATransform3D x = CATransform3DMakeTranslation(-size.width/2, -size.height/2,0);
    x = CATransform3DConcat(x, bitTransform);
    x = CATransform3DConcat(x, CATransform3DMakeTranslation(size.width/2, size.height/2,0));
    self.sublayerTransform = x;    
}


- (void) drawInParentContext: (CGContextRef)ctx fill: (BOOL)fill
{
    // Default implementation just fills or outlines the cell.
    CGRect frame = self.frame;
    if( fill )
        CGContextFillRect(ctx,frame);
    else
        CGContextStrokeRect(ctx, frame);
}


- (void) setBit: (Bit*)bit
{
    if( bit != self.bit ) {
        [super setBit: bit];
        if( bit )
            bit.position = GetCGRectCenter(self.bounds);
    }
}

- (Bit*) canDragBit: (Bit*)bit
{
    if( _grid.allowsMoves && bit==self.bit )
        return [super canDragBit: bit];
    else
        return nil;
}

- (BOOL) canDropBit: (Bit*)bit atPoint: (CGPoint)point
{
    return self.bit == nil || _grid.allowsCaptures;
}


- (BOOL) fwdIsN 
{
    return self.game.currentPlayer.index == 0;
}


- (NSArray*) neighbors
{
    BOOL orthogonal = ! _grid.usesDiagonals;
    NSMutableArray *neighbors = [NSMutableArray arrayWithCapacity: 8];
    for( int dy=-1; dy<=1; dy++ )
        for( int dx=-1; dx<=1; dx++ )
            if( (dx || dy) && !(orthogonal && dx && dy) ) {
                GridCell *cell = [_grid cellAtRow: _row+dy column: _column+dx];
                if( cell )
                    [neighbors addObject: cell];
            }
    return neighbors;
}


// Recursive subroutine used by getGroup:.
- (void) x_addToGroup: (NSMutableSet*)group liberties: (NSMutableSet*)liberties owner: (Player*)owner
{
    Bit *bit = self.bit;
    if( bit == nil ) {
        if( [liberties containsObject: self] )
            return; // already traversed
        [liberties addObject: self];
    } else if( bit.owner==owner ) {
        if( [group containsObject: self] )
            return; // already traversed
        [group addObject: self];
        for( GridCell *c in self.neighbors )
            [c x_addToGroup: group liberties: liberties owner: owner];
    }
}


- (NSSet*) getGroup: (int*)outLiberties
{
    NSMutableSet *group=[NSMutableSet set], *liberties=nil;
    if( outLiberties )
        liberties = [NSMutableSet set];
    [self x_addToGroup: group liberties: liberties owner: self.bit.owner];
    if( outLiberties )
        *outLiberties = liberties.count;
    return group;
}


#pragma mark -
#pragma mark DRAG-AND-DROP:


#if ! TARGET_OS_IPHONE

// An image from another app can be dragged onto a Grid to change its background pattern.

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if( CanGetCGImageFromPasteboard([sender draggingPasteboard]) )
        return NSDragOperationCopy;
    else
        return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    CGImageRef image = GetCGImageFromPasteboard([sender draggingPasteboard],sender);
    if( image ) {
        CGColorRef pattern = CreatePatternColor(image);
        _grid.cellColor = pattern;
        CGColorRelease(pattern);
        [_grid setNeedsDisplay];
        return YES;
    } else
        return NO;
}

#endif

@end




#pragma mark -

@implementation RectGrid


- (id) initWithRows: (unsigned)nRows columns: (unsigned)nColumns
            spacing: (CGSize)spacing
           position: (CGPoint)pos
{
    self = [super initWithRows: nRows columns: nColumns spacing: spacing position: pos];
    if( self ) {
        _cellClass = [Square class];
    }
    return self;
}


- (CGColorRef) altCellColor                         {return _altCellColor;}
- (void) setAltCellColor: (CGColorRef)altCellColor  {setcolor(&_altCellColor,altCellColor);}


@end



#pragma mark -

@implementation Square


- (void) drawInParentContext: (CGContextRef)ctx fill: (BOOL)fill
{
    if( fill ) {
        CGColorRef c = ((RectGrid*)_grid).altCellColor;
        if( c ) {
            if( ! ((_row+_column) & 1) )
                c = _grid.cellColor;
            CGContextSetFillColorWithColor(ctx, c);
        }
    }
    [super drawInParentContext: ctx fill: fill];
}


- (void) setHighlighted: (BOOL)highlighted
{
    [super setHighlighted: highlighted];
    self.cornerRadius = self.bounds.size.width/2.0;
    self.borderWidth = (highlighted ?6 :0);
}


- (Square*) nw     {return (Square*)[_grid cellAtRow: _row+1 column: _column-1];}
- (Square*) n      {return (Square*)[_grid cellAtRow: _row+1 column: _column  ];}
- (Square*) ne     {return (Square*)[_grid cellAtRow: _row+1 column: _column+1];}
- (Square*) e      {return (Square*)[_grid cellAtRow: _row   column: _column+1];}
- (Square*) se     {return (Square*)[_grid cellAtRow: _row-1 column: _column+1];}
- (Square*) s      {return (Square*)[_grid cellAtRow: _row-1 column: _column  ];}
- (Square*) sw     {return (Square*)[_grid cellAtRow: _row-1 column: _column-1];}
- (Square*) w      {return (Square*)[_grid cellAtRow: _row   column: _column-1];}

// Directions relative to the current player:
- (Square*) fl     {return self.fwdIsN ?self.nw :self.se;}
- (Square*) f      {return self.fwdIsN ?self.n  :self.s;}
- (Square*) fr     {return self.fwdIsN ?self.ne :self.sw;}
- (Square*) r      {return self.fwdIsN ?self.e  :self.w;}
- (Square*) br     {return self.fwdIsN ?self.se :self.nw;}
- (Square*) b      {return self.fwdIsN ?self.s  :self.n;}
- (Square*) bl     {return self.fwdIsN ?self.sw :self.ne;}
- (Square*) l      {return self.fwdIsN ?self.w  :self.e;}


static int sgn( int n ) {return n<0 ?-1 :(n>0 ?1 :0);}


- (SEL) directionToCell: (GridCell*)dst
{
    static NSString* const kDirections[9] = {@"sw", @"s", @"se",
                                             @"w",  nil,  @"e",
                                             @"nw", @"n", @"ne"};
    if( dst.grid != self.grid )
        return NULL;
    int dy=dst.row-_row, dx=dst.column-_column;
    if( dx && dy )
        if( !( _grid.usesDiagonals && abs(dx)==abs(dy) ) )
            return NULL;
    NSString *dir = kDirections[ 3*(sgn(dy)+1) + (sgn(dx)+1) ];
    return dir ?NSSelectorFromString(dir) :NULL;
}

- (NSArray*) lineToCell: (GridCell*)dst inclusive: (BOOL)inclusive;
{
    SEL dir = [self directionToCell: dst];
    if( ! dir )
        return nil;
    NSMutableArray *line = [NSMutableArray array];
    GridCell *cell;
    for( cell=self; cell; cell = [cell performSelector: dir] ) {
        if( inclusive || (cell!=self && cell!=dst) )
            [line addObject: cell];
        if( cell==dst )
            return line;
    }
    return nil; // should be impossible, but just in case
}
                

#if ! TARGET_OS_IPHONE

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    CGImageRef image = GetCGImageFromPasteboard([sender draggingPasteboard],sender);
    if( image ) {
        CGColorRef color = CreatePatternColor(image);
        RectGrid *rectGrid = (RectGrid*)_grid;
        if( rectGrid.altCellColor && ((_row+_column) & 1) )
            rectGrid.altCellColor = color;
        else
            rectGrid.cellColor = color;
        CGColorRelease(color);
        [rectGrid setNeedsDisplay];
        return YES;
    } else
        return NO;
}

#endif

@end



#pragma mark -

@implementation GoSquare

@synthesize dotted=_dotted;

- (void) drawInParentContext: (CGContextRef)ctx fill: (BOOL)fill
{
    if( fill )
        [super drawInParentContext: ctx fill: fill];
    else {
        CGRect frame = self.frame;
        const CGFloat midx=floor(CGRectGetMidX(frame))+0.5, 
                    midy=floor(CGRectGetMidY(frame))+0.5;
        CGPoint p[4] = {{CGRectGetMinX(frame),midy},
                        {CGRectGetMaxX(frame),midy},
                        {midx,CGRectGetMinY(frame)},
                        {midx,CGRectGetMaxY(frame)}};
        if( ! self.s )  p[2].y = midy;
        if( ! self.n )  p[3].y = midy;
        if( ! self.w )  p[0].x = midx;
        if( ! self.e )  p[1].x = midx;
        CGContextStrokeLineSegments(ctx, p, 4);
        
        if( _dotted ) {
            CGContextSetFillColorWithColor(ctx,_grid.lineColor);
            CGRect dot = CGRectMake(midx-2.5, midy-2.5, 5, 5);
            CGContextFillEllipseInRect(ctx, dot);
        }
    }
}


@end
