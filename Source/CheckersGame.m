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


- (Piece*) pieceForPlayer: (int)playerNum
{
    Piece *p = [[Piece alloc] initWithImageNamed: (playerNum==0 ?@"Green Ball.png" :@"Red Ball.png") 
                                           scale: floor(_grid.spacing.width * 0.8)];
    p.owner = [self.players objectAtIndex: playerNum];
    p.name = playerNum ?@"2" :@"1";
    return [p autorelease];
}

- (Grid*) x_makeGrid
{
    RectGrid *grid = [[[RectGrid alloc] initWithRows: 8 columns: 8 frame: _board.bounds] autorelease];
    _grid = grid;
    CGPoint pos = _grid.position;
    pos.x = floor((_board.bounds.size.width-grid.frame.size.width)/2);
    grid.position = pos;
    grid.allowsMoves = YES;
    grid.allowsCaptures = NO;
    grid.cellColor = CreateGray(0.0, 0.25);
    grid.altCellColor = CreateGray(1.0, 0.25);
    grid.lineColor = nil;

    [grid addAllCells];
    for( int i=0; i<32; i++ ) {
        int row = i/4;
        [_cells addObject: [_grid cellAtRow: row column: 2*(i%4) + (row&1)]];
    }
    self.stateString = @"111111111111--------222222222222";
    return grid;
}


- (id) initWithBoard: (GGBLayer*)board
{
    self = [super initWithBoard: board];
    if (self != nil) {
        [self setNumberOfPlayers: 2];
        _cells = [[NSMutableArray alloc] init];
        [self x_makeGrid];
        [board addSublayer: _grid];
        [self nextPlayer];
        
        PreloadSound(@"Tink");
        PreloadSound(@"Funk");
        PreloadSound(@"Blow");
        PreloadSound(@"Pop");
    }
    return self;
}

- (void) dealloc
{
    [_cells release];
    [_grid release];
    [super dealloc];
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
        switch( [state characterAtIndex: i++] ) {
            case '1': piece = [self pieceForPlayer: 0]; _numPieces[0]++; break;
            case '2': piece = [self pieceForPlayer: 1]; _numPieces[1]++; break;
            default:  piece = nil; break;
        }
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
    
    if( self.currentMove.length==0 )
        [self.currentMove appendString: src.name];
    [self.currentMove appendString: dst.name];
    
    BOOL isKing = ([bit valueForKey: @"King"] != nil);
    PlaySound(isKing ?@"Funk" :@"Tink");

    // "King" a piece that made it to the last row:
    if( dst.row == (playerIndex ?0 :7) )
        if( ! isKing ) {
            PlaySound(@"Blow");
            bit.scale = 1.4;
            [bit setValue: @"King" forKey: @"King"];
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
        Bit *bit = capture.bit;
        _numPieces[bit.owner.index]--;
        [bit destroy];
        
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
    int length = move.length;
    if( length<4 || (length&1) )
        return NO;
    GridCell *src = nil;
    for( int i=0; i<length; i+=2 ) {
        NSString *ident = [move substringWithRange: NSMakeRange(i,2)];
        GridCell *dst = [_grid cellWithName: ident];
        if( i > 0 )
            if( ! [self animateMoveFrom: src to: dst] )
                return NO;
        src = dst;
    }
    return YES;
}


@end
