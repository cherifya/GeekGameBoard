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
#import "GoGame.h"
#import "Grid.h"
#import "Piece.h"
#import "Dispenser.h"
#import "Stack.h"
#import "QuartzUtils.h"
#import "GGBUtils.h"


@implementation GoGame


+ (int) dimensions {return 19;}

+ (const GridCoord*) spotCoords
{
    static GridCoord const sSpots[10]={ { 3,3}, { 3,9}, { 3,15},
                                        { 9,3}, { 9,9}, { 9,15},
                                        {15,3}, {15,9}, {15,15}, 
                                        {(unsigned)NSNotFound,(unsigned)NSNotFound} };
    return sSpots;
}

- (id) init
{
    self = [super init];
    if (self != nil) {
        [self setNumberOfPlayers: 2];
        [(Player*)[_players objectAtIndex: 0] setName: @"Black"];
        [(Player*)[_players objectAtIndex: 1] setName: @"White"];
    }
    return self;
}
        
- (void) setUpBoard
{
    int dimensions = [[self class] dimensions];
    CGRect tableBounds = _table.bounds;
    CGSize size = tableBounds.size;
    CGFloat boardSide = MIN(size.width* dimensions/(CGFloat)(dimensions+2),size.height);
    RectGrid *board = [[RectGrid alloc] initWithRows: dimensions columns: dimensions 
                                              frame: CGRectMake(floor((size.width-boardSide)/2),
                                                                floor((size.height-boardSide)/2),
                                                                boardSide,boardSide)];
    _board = board;
    /*
    grid.backgroundColor = GetCGPatternNamed(@"Wood.jpg");
    grid.borderColor = kTranslucentLightGrayColor;
    grid.borderWidth = 2;
    */
    board.lineColor = kTranslucentGrayColor;
    board.cellClass = [GoSquare class];
    board.usesDiagonals = board.allowsMoves = board.allowsCaptures = NO;
    [board addAllCells];
    const GridCoord *spots = [[self class] spotCoords];
    for( int i=0; spots[i].row!=(unsigned)NSNotFound; i++ )
        ((GoSquare*)[board cellAtRow: spots[i].row column: spots[i].col]).dotted = YES;
    [_table addSublayer: board];
    [board release];
    
    CGRect gridFrame = board.frame;
    CGFloat pieceSize = (int)board.spacing.width & ~1;  // make sure it's even
    CGFloat captureMinY = CGRectGetMinY(tableBounds) + pieceSize/2,
            captureHeight = size.height - pieceSize;
    _captured[0] = [[Stack alloc] initWithStartPos: CGPointMake(pieceSize/2,0)
                                           spacing: CGSizeMake(0,pieceSize)
                                      wrapInterval: floor(captureHeight/pieceSize)
                                       wrapSpacing: CGSizeMake(pieceSize,0)];
    _captured[0].frame = CGRectMake(CGRectGetMinX(tableBounds), 
                                    captureMinY,
                                    CGRectGetMinX(gridFrame)-CGRectGetMinX(tableBounds),
                                    captureHeight);
    _captured[0].zPosition = kPieceZ+1;
    [_table addSublayer: _captured[0]];
    [_captured[0] release];
    
    _captured[1] = [[Stack alloc] initWithStartPos: CGPointMake(pieceSize/2,captureHeight)
                                           spacing: CGSizeMake(0,-pieceSize)
                                      wrapInterval: floor(captureHeight/pieceSize)
                                       wrapSpacing: CGSizeMake(-pieceSize,0)];
    _captured[1].frame = CGRectMake(CGRectGetMaxX(gridFrame), 
                                    captureMinY,
                                    CGRectGetMaxX(tableBounds)-CGRectGetMaxX(gridFrame),
                                    captureHeight);
    _captured[1].startPos = CGPointMake(CGRectGetMaxX(_captured[1].bounds)-pieceSize/2, captureHeight);
    _captured[1].zPosition = kPieceZ+1;
    [_table addSublayer: _captured[1]];
    [_captured[1] release];

    PreloadSound(@"Pop");
}

- (CGImageRef) iconForPlayer: (int)playerNum
{
    return GetCGImageNamed( playerNum ?@"ball-white.png" :@"ball-black.png" );
}

- (Piece*) pieceForPlayer: (int)index
{
    NSString *imageName = index ?@"ball-white.png" :@"ball-black.png";
    CGFloat pieceSize = (int)(_board.spacing.width * 1.0) & ~1;  // make sure it's even
    Piece *stone = [[Piece alloc] initWithImageNamed: imageName scale: pieceSize];
    stone.owner = [self.players objectAtIndex: index];
    return [stone autorelease];
}

- (Bit*) bitToPlaceInHolder: (id<BitHolder>)holder
{
    if( holder.bit != nil || ! [holder isKindOfClass: [GoSquare class]] )
        return nil;
    else
        return [self pieceForPlayer: self.currentPlayer.index];
}


- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)srcHolder
{
    return (srcHolder==nil);
}


- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)srcHolder to: (id<BitHolder>)dstHolder
{
    if( srcHolder!=nil || ! [dstHolder isKindOfClass: [Square class]] )
        return NO;
    Square *dst=(Square*)dstHolder;
    
    // There should be a check here for a "ko" (repeated position) ... exercise for the reader!
    
    // Check for suicidal move. First an easy check for an empty adjacent space:
    NSArray *neighbors = dst.neighbors;
    for( GridCell *c in neighbors )
        if( c.empty )
            return YES;                     // there's an empty space
    // If the piece is surrounded, check the neighboring groups' liberties:
    for( GridCell *c in neighbors ) {
        int nLiberties;
        [c getGroup: &nLiberties];
        if( c.bit.unfriendly ) {
            if( nLiberties <= 1 )
                return YES;             // the move captures, so it's not suicidal
        } else {
            if( nLiberties > 1 )
                return YES;             // the stone joins a group with other liberties
        }
    }
    return NO;
}


- (void) bit: (Bit*)bit movedFrom: (id<BitHolder>)srcHolder to: (id<BitHolder>)dstHolder
{
    Square *dst=(Square*)dstHolder;
    int curIndex = self.currentPlayer.index;
    // Check for captured enemy groups:
    BOOL captured = NO;
    for( GridCell *c in dst.neighbors )
        if( c.bit.unfriendly ) {
            int nLiberties;
            NSSet *group = [c getGroup: &nLiberties];
            if( nLiberties == 0 ) {
                captured = YES;
                for( GridCell *capture in group )
                    [_captured[curIndex] addBit: capture.bit];  // Moves piece to POW camp!
            }
        }
    if( captured )
        PlaySound(@"Pop");
    
    [self.currentTurn addToMove: dst.name];
    [self endTurn];
}


// This sample code makes no attempt to detect the end of the game, or count score,
// both of which are rather complex to decide in Go.


#pragma mark -
#pragma mark STATE:


- (NSString*) stateString
{
    int n = _board.rows;
    unichar state[n*n];
    for( int y=0; y<n; y++ )
        for( int x=0; x<n; x++ ) {
            Bit *bit = [_board cellAtRow: y column: x].bit;
            unichar ch;
            if( bit==nil )
                ch = '-';
            else
                ch = '1' + bit.owner.index;
            state[y*n+x] = ch;
        }
    NSMutableString *stateString = [NSMutableString stringWithCharacters: state length: n*n];
    
    NSUInteger cap0=_captured[0].numberOfBits, cap1=_captured[1].numberOfBits;
    if( cap0 || cap1 )
        [stateString appendFormat: @",%i,%i", cap0,cap1];
    return stateString;
}

- (void) setStateString: (NSString*)state
{
    //NSLog(@"Go: setStateString: '%@'",state);
    NSArray *components = [state componentsSeparatedByString: @","];
    state = [components objectAtIndex: 0];
    int n = _board.rows;
    for( int y=0; y<n; y++ )
        for( int x=0; x<n; x++ ) {
            int i = y*n+x;
            Piece *piece = nil;
            if( i < state.length ) {
                int index = [state characterAtIndex: i] - '1';
                if( index==0 || index==1 )
                    piece = [self pieceForPlayer: index];
            }
            [_board cellAtRow: y column: x].bit = piece;
        }
    
    if( components.count < 3 )
        components = nil;
    for( int player=0; player<=1; player++ ) {
        NSUInteger nCaptured = [[components objectAtIndex: 1+player] intValue];
        NSUInteger curNCaptured = _captured[player].numberOfBits;
        if( nCaptured < curNCaptured )
           _captured[player].numberOfBits = nCaptured;
        else
            for( int i=curNCaptured; i<nCaptured; i++ )
                [_captured[player] addBit: [self pieceForPlayer: 1-player]];
    }
}


- (BOOL) applyMoveString: (NSString*)move
{
    //NSLog(@"Go: applyMoveString: '%@'",move);
    return [self animatePlacementIn: [_board cellWithName: move]];
}


@end


@implementation Go9Game
+ (NSString*) displayName   {return @"Go (9x9)";}
+ (int) dimensions          {return 9;}
+ (const GridCoord*) spotCoords
{
    static GridCoord const sSpots[6]= { {2,2}, {2,6}, {4,4}, {6,2}, {6,6}, 
                                        {(unsigned)NSNotFound,(unsigned)NSNotFound} };
    return sSpots;
}
@end


@implementation Go13Game
+ (NSString*) displayName   {return @"Go (13x13)";}
+ (int) dimensions          {return 13;}
+ (const GridCoord*) spotCoords
{
    static GridCoord const sSpots[6] = { { 2,2}, { 2,10}, {6,6},
                                         {10,2}, {10,10},
                                         {(unsigned)NSNotFound,(unsigned)NSNotFound} };
    return sSpots;
}
@end
