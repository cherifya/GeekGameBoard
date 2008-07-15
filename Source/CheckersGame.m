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


static NSMutableDictionary *kPieceStyle1, *kPieceStyle2;

+ (void) initialize
{
    if( self == [CheckersGame class] ) {
        kPieceStyle1 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                        (id)GetCGImageNamed(@"Green.png"), @"contents",
                        kCAGravityResizeAspect, @"contentsGravity",
                        kCAFilterLinear, @"minificationFilter",
                        nil];
        kPieceStyle2 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                        (id)GetCGImageNamed(@"Red.png"), @"contents",
                        kCAGravityResizeAspect, @"contentsGravity",
                        kCAFilterLinear, @"minificationFilter",
                        nil];
    }
}


- (id) init
{
    self = [super init];
    if (self != nil) {
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
    Piece *p = [[Piece alloc] init];
    p.bounds = CGRectMake(0,0,floor(_board.spacing.width),floor(_board.spacing.height));
    p.style = (playerNum ?kPieceStyle2 :kPieceStyle1);
    p.owner = [self.players objectAtIndex: playerNum];
    p.name = playerNum ?@"2" :@"1";
    return [p autorelease];
}

- (void) makeKing: (Piece*)piece
{
    piece.scale = 1.4;
    piece.tag = YES;        // tag property stores the 'king' flag
    piece.name = piece.owner.index ?@"4" :@"3";
}

- (void) setUpBoard
{
    RectGrid *board = [[RectGrid alloc] initWithRows: 8 columns: 8 frame: _table.bounds];
    _board = board;
    [_table addSublayer: _board];
    CGPoint pos = _board.position;
    pos.x = floor((_table.bounds.size.width-board.frame.size.width)/2);
    board.position = pos;
    board.allowsMoves = YES;
    board.allowsCaptures = NO;
    board.cellColor    = CreateGray(0.0, 0.5);
    board.altCellColor = CreateGray(1.0, 0.25);
    board.lineColor = nil;
    board.reversed = ! [[self.players objectAtIndex: 0] isLocal];

    for( int i=0; i<32; i++ ) {
        int row = i/4;
        [_board addCellAtRow: row column: 2*(i%4) + (row&1)];
    }
    [_board release]; // its superlayer still retains it
}

- (NSString*) initialStateString            {return @"111111111111--------222222222222";}
- (NSString*) stateString                   {return _board.stateString;}
- (void) setStateString: (NSString*)state   {_board.stateString = state;}

- (Piece*) makePieceNamed: (NSString*)name
{
    int which = [name characterAtIndex: 0] - '1';
    if( which >=0 && which < 4 ) {
        Piece *piece = [self pieceForPlayer: (which & 1)];
        if( which & 2 ) 
            [self makeKing: piece];
        return piece;
    } else
        return nil;
}


- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)srcHolder to: (id<BitHolder>)dstHolder
{
    Square *src=(Square*)srcHolder, *dst=(Square*)dstHolder;
    if( bit.tag )
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
    
    BOOL isKing = bit.tag;
    PlaySound(isKing ?@"Funk" :@"Tink");

    // "King" a piece that made it to the last row:
    if( !isKing && (dst.row == (playerIndex ?0 :7)) ) {
        PlaySound(@"Blow");
        [self makeKing: (Piece*)bit];
        [turn addToMove: @"*"];
        // don't set isKing flag - piece can't jump again after being kinged.
    }

    // Check for a capture:
    NSArray *line = [src lineToCell: dst inclusive: NO];
    if( line.count==1 ) {
        Square *capture = [line objectAtIndex: 0];
        [capture destroyBit];
        [turn addToMove: @"!"];
        PlaySound(@"Pop");
        
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
    NSCountedSet *remaining = _board.countPiecesByPlayer;
    if( remaining.count==1 )
        return [remaining anyObject];
    else
        return nil;
}


- (BOOL) applyMoveString: (NSString*)move
{
    GridCell *src = nil;
    for( NSString *ident in [move componentsSeparatedByString: @"-"] ) {
        while( [ident hasSuffix: @"!"] || [ident hasSuffix: @"*"] )
            ident = [ident substringToIndex: ident.length-1];
        GridCell *dst = [_board cellWithName: ident];
        if( dst == nil )
            return NO;
        if( src && ! [self animateMoveFrom: src to: dst] )
            return NO;
        src = dst;
    }
    return YES;
}


@end
