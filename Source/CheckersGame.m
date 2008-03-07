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


@implementation CheckersGame


- (void) addPieces: (NSString*)imageName
            toGrid: (Grid*)grid
         forPlayer: (int)playerNum
              rows: (NSRange)rows
       alternating: (BOOL)alternating
{
    Piece *prototype = [[Piece alloc] initWithImageNamed: imageName scale: floor(grid.spacing.width * 0.8)];
    prototype.owner = [self.players objectAtIndex: playerNum];
    unsigned cols=grid.columns;
    for( unsigned row=rows.location; row<NSMaxRange(rows); row++ )
        for( unsigned col=0; col<cols; col++ ) {
            if( !alternating || ((row+col) & 1) == 0 ) {
                GridCell *cell = [grid cellAtRow: row column: col];
                if( cell ) {
                    Piece *piece = [prototype copy];
                    cell.bit = piece;
                    [piece release];
                    //cell.bit.rotation = random() % 360; // keeps pieces from looking too samey
                    _numPieces[playerNum]++;
                }
            }
        }
    [prototype release];
}


- (Grid*) x_makeGrid
{
    RectGrid *grid = [[[RectGrid alloc] initWithRows: 8 columns: 8 frame: _board.bounds] autorelease];
    CGPoint pos = grid.position;
    pos.x = floor((_board.bounds.size.width-grid.frame.size.width)/2);
    [grid addAllCells];
    grid.position = pos;
    grid.allowsMoves = YES;
    grid.allowsCaptures = NO;
    grid.cellColor = CGColorCreateGenericGray(0.0, 0.25);
    grid.altCellColor = CGColorCreateGenericGray(1.0, 0.25);
    grid.lineColor = nil;
    [self addPieces: @"Green Ball.png" toGrid: grid forPlayer: 0 rows: NSMakeRange(0,3) alternating: YES];
    [self addPieces: @"Red Ball.png"   toGrid: grid forPlayer: 1 rows: NSMakeRange(5,3) alternating: YES];
    return grid;
}


- (id) initWithBoard: (CALayer*)board
{
    self = [super initWithBoard: board];
    if (self != nil) {
        [self setNumberOfPlayers: 2];
        [board addSublayer: [self x_makeGrid]];
        [self nextPlayer];
    }
    return self;
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
    BOOL isKing = ([bit valueForKey: @"King"] != nil);
    
    [[NSSound soundNamed: (isKing ?@"Funk" :@"Tink")] play];

    // "King" a piece that made it to the last row:
    if( dst.row == (playerIndex ?0 :7) )
        if( ! isKing ) {
            [[NSSound soundNamed: @"Blow"] play];
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
        [[NSSound soundNamed: @"Pop"] play];
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


@end
