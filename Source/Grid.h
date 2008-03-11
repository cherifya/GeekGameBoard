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
#import "BitHolder.h"
@class GridCell;


/** Abstract superclass of regular geometric grids of GridCells that Bits can be placed on. */
@interface Grid : GGBLayer
{
    unsigned _nRows, _nColumns;                         
    CGSize _spacing;                                    
    Class _cellClass;                                   
    CGColorRef _cellColor, _lineColor;                  
    BOOL _usesDiagonals, _allowsMoves, _allowsCaptures;
    NSMutableArray *_cells;                             // Really a 2D array, in row-major order.
}

/** Initializes a new Grid with the given dimensions and cell size, and position in superview.
    Note that a new Grid has no cells! Either call -addAllCells, or -addCellAtRow:column:. */
- (id) initWithRows: (unsigned)nRows columns: (unsigned)nColumns
            spacing: (CGSize)spacing
           position: (CGPoint)pos;

/** Initializes a new Grid with the given dimensions and frame in superview.
    The cell size will be computed by dividing frame size by dimensions.
    Note that a new Grid has no cells! Either call -addAllCells, or -addCellAtRow:column:. */
- (id) initWithRows: (unsigned)nRows columns: (unsigned)nColumns
              frame: (CGRect)frame;

@property Class cellClass;                      // What kind of GridCells to create
@property (readonly) unsigned rows, columns;    // Dimensions of the grid
@property (readonly) CGSize spacing;            // x,y spacing of GridCells
@property CGColorRef cellColor, lineColor;      // Cell background color, line color (or nil)
@property BOOL usesDiagonals;                   // Affects GridCell.neighbors, for rect grids
@property BOOL allowsMoves, allowsCaptures;     // Can pieces be moved, and can they land on others?

/** Returns the GridCell at the given coordinates, or nil if there is no cell there.
    It's OK to call this with off-the-board coordinates; it will just return nil.*/
- (GridCell*) cellAtRow: (unsigned)row column: (unsigned)col;

/** Adds cells at all coordinates, creating a complete grid. */
- (void) addAllCells;

/** Adds a GridCell at the given coordinates. */
- (GridCell*) addCellAtRow: (unsigned)row column: (unsigned)col;

/** Removes a particular cell, leaving a blank space. */
- (void) removeCellAtRow: (unsigned)row column: (unsigned)col;


// protected:
- (GridCell*) createCellAtRow: (unsigned)row column: (unsigned)col 
               suggestedFrame: (CGRect)frame;

@end


/** Abstract superclass of a single cell in a grid. */
@interface GridCell : BitHolder
{
    Grid *_grid;
    unsigned _row, _column;
}

- (id) initWithGrid: (Grid*)grid 
                row: (unsigned)row column: (unsigned)col
              frame: (CGRect)frame;

@property (readonly) Grid* grid;
@property (readonly) unsigned row, column;
@property (readonly) NSArray* neighbors;        // Dependent on grid.usesDiagonals

/** Returns YES if 'forward' is north (increasing row#) for the current player */
@property (readonly) BOOL fwdIsN;

/* Go-style group detection. Returns the set of contiguous GridCells that have pieces of the same
   owner as this one, and optionally a count of the number of "liberties", or adjacent empty cells. */
- (NSSet*) getGroup: (int*)outLiberties;

// protected:
- (void) drawInParentContext: (CGContextRef)ctx fill: (BOOL)fill;
@end



/** A rectangular grid of squares. */
@interface RectGrid : Grid
{
    CGColorRef _altCellColor;
}

/** If non-nil, alternate cells will be drawn with this background color, in a checkerboard pattern.
    The precise rule is that cells whose row+column is odd use the altCellColor.*/
@property CGColorRef altCellColor;

@end



/* A square in a RectGrid */
@interface Square : GridCell

@property (readonly) Square *nw, *n, *ne, *e, *se, *s, *sw, *w;    // Absolute directions (n = increasing row#)
@property (readonly) Square *fl, *f, *fr, *r, *br, *b, *bl, *l;    // Relative to player (upside-down for player 2)

@end


/* Substitute this for Square in a RectGrid's cellClass to draw the lines through the centers
   of the squares, so the pieces sit on the intersections, as in a Go board. */
@interface GoSquare : Square
{
    BOOL _dotted;
}

/** Set to YES to put a dot at the intersection, as in the handicap points of a Go board. */
@property BOOL dotted;

@end
