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
#import "CheckersGame.h"
#import "Grid.h"
#import "Piece.h"
#import "QuartzUtils.h"
#import "GGBUtils.h"


@implementation CheckersGame


- (id) init
{
    self = [super init];
    if (self != nil) {
        _cells = [[NSMutableArray alloc] init];
        [self setNumberOfPlayers: 2];
        
        PreloadSound(@"Tink");
        PreloadSound(@"Funk");
        PreloadSound(@"Blow");
        PreloadSound(@"Pop");
    }
    return self;
}

- (CGImageRef) iconForPlayer: (int)playerNum
{
    return GetCGImageNamed( playerNum==0 ?@"Green.png" :@"Red.png" );
}

- (Piece*) pieceForPlayer: (int)playerNum
{
    Piece *p = [[Piece alloc] initWithImageNamed: (playerNum==0 ?@"Green.png" :@"Red.png") 
                                           scale: floor(_grid.spacing.width * 1.0)];
    p.owner = [self.players objectAtIndex: playerNum];
    p.name = playerNum ?@"2" :@"1";
    return [p autorelease];
}

- (void) makeKing: (Piece*)piece
{
    piece.scale = 1.4;
    [piece setValue: @"King" forKey: @"King"];
    piece.name = piece.owner.index ?@"4" :@"3";
}

- (void) setUpBoard
{
    RectGrid *grid = [[[RectGrid alloc] initWithRows: 8 columns: 8 frame: _board.bounds] autorelease];
    _grid = grid;
    [_board addSublayer: _grid];
    CGPoint pos = _grid.position;
    pos.x = floor((_board.bounds.size.width-grid.frame.size.width)/2);
    grid.position = pos;
    grid.allowsMoves = YES;
    grid.allowsCaptures = NO;
    grid.cellColor = CreateGray(0.0, 0.25);
    grid.altCellColor = CreateGray(1.0, 0.25);
    grid.lineColor = nil;

    [grid addAllCells];
    [_cells removeAllObjects];
    for( int i=0; i<32; i++ ) {
        int row = i/4;
        [_cells addObject: [_grid cellAtRow: row column: 2*(i%4) + (row&1)]];
    }
}

- (void) dealloc
{
    [_cells release];
    [_grid release];
    [super dealloc];
}


- (NSString*) initialStateString
{
    return @"111111111111--------222222222222";
}

- (NSString*) stateString
{
    unichar state[_cells.count];
    int i = 0;
    for( GridCell *cell in _cells ) {
        NSString *ident = cell.bit.name;
        if( ident )
            state[i++] = [ident characterAtIndex: 0];
        else
            state[i++] = '-';
    }
    return [NSString stringWithCharacters: state length: i];
}

- (void) setStateString: (NSString*)state
{
    _numPieces[0] = _numPieces[1] = 0;
    int i = 0;
    for( GridCell *cell in _cells ) {
        Piece *piece;
        int which = [state characterAtIndex: i++] - '1';
        if( which >=0 && which < 4 ) {
            int player = (which & 1);
            piece = [self pieceForPlayer: player];
            _numPieces[player]++;
            if( which & 2 ) 
                [self makeKing: piece];
        } else
            piece = nil;
        cell.bit = piece;
    }    
}


- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)srcHolder to: (id<BitHolder>)dstHolder
{
    Square *src=(Square*)srcHolder, *dst=(Square*)dstHolder;
    if( [bit valueForKey: @"King"] )
        if( dst==src.bl || dst==src.br || dst==src.l || dst==src.r
           || (src.bl.bit.unfriendly && dst==src.bl.bl) || (src.br.bit.unfriendly && dst==src.br.br) )
            return YES;    
    return dst==src.fl || dst==src.fr
        || (src.fl.bit.unfriendly && dst==src.fl.fl) || (src.fr.bit.unfriendly && dst==src.fr.fr);
}

- (void) bit: (Bit*)bit movedFrom: (id<BitHolder>)srcHolder to: (id<BitHolder>)dstHolder
{
    Square *src=(Square*)srcHolder, *dst=(Square*)dstHolder;
    int playerIndex = self.currentPlayer.index;
    
    Turn *turn = self.currentTurn;
    if( turn.move.length==0 )
        [turn addToMove: src.name];
    [turn addToMove: @"-"];
    [turn addToMove: dst.name];
    
    BOOL isKing = ([bit valueForKey: @"King"] != nil);
    PlaySound(isKing ?@"Funk" :@"Tink");

    // "King" a piece that made it to the last row:
    if( dst.row == (playerIndex ?0 :7) )
        if( ! isKing ) {
            PlaySound(@"Blow");
            [self makeKing: (Piece*)bit];
            [turn addToMove: @"*"];
            // don't set isKing flag - piece can't jump again after being kinged.
        }

    // Check for a capture:
    Square *capture = nil;
    if(dst==src.fl.fl)
        capture = src.fl;
    else if(dst==src.fr.fr)
        capture = src.fr;
    else if(dst==src.bl.bl)
        capture = src.bl;
    else if(dst==src.br.br)
        capture = src.br;
    
    if( capture ) {
        PlaySound(@"Pop");
        _numPieces[capture.bit.owner.index]--;
        [capture destroyBit];
        [turn addToMove: @"!"];
        
        // Now check if another capture is possible. If so, don't end the turn:
        if( (dst.fl.bit.unfriendly && dst.fl.fl.empty) || (dst.fr.bit.unfriendly && dst.fr.fr.empty) )
            return;
        if( isKing )
            if( (dst.bl.bit.unfriendly && dst.bl.bl.empty) || (dst.br.bit.unfriendly && dst.br.br.empty) )
                return;
    }
    
    [self endTurn];
}

- (Player*) checkForWinner
{
    // Whoever runs out of pieces loses:
    if( _numPieces[0]==0 )
        return [self.players objectAtIndex: 1];
    else if( _numPieces[1]==0 )
        return [self.players objectAtIndex: 0];
    else
        return nil;
}


- (BOOL) applyMoveString: (NSString*)move
{
    GridCell *src = nil;
    for( NSString *ident in [move componentsSeparatedByString: @"-"] ) {
        while( [ident hasSuffix: @"!"] || [ident hasSuffix: @"*"] )
            ident = [ident substringToIndex: ident.length-1];
        GridCell *dst = [_grid cellWithName: ident];
        if( dst == nil )
            return NO;
        if( src && ! [self animateMoveFrom: src to: dst] )
            return NO;
        src = dst;
    }
    return YES;
}


@end
