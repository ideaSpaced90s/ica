// Copyright 1997, 2008, 2021, 2024-2025 by Jon Dart.  All Rights Reserved.

#include "boardio.h"
#include "attacks.h"
#include "bhash.h"

#include <cassert>
#include <sstream>
#include <cctype>

int BoardIO::readFEN(Board &board, const std::string &buf) {
    bool is_c960 = board.isChess960();
    board.reset();
    board.setChess960(is_c960);
    for (int i = 0; i < 64; i++) {
        board.contents[i] = EmptyPiece;
    }

    char c;
    std::string::const_iterator bp = buf.begin();
    size_t first = buf.find_first_not_of(" \t");
    if (first != std::string::npos) {
        bp += first;
    }
    for (int line = 0; line < 8; line++) {
        int sqval = 56 - line * 8;
        while ((c = *bp) != ' ' && c != '/') {
            Piece piece;
            if (isdigit(c)) {
                sqval += (*bp - '0');
                bp++;
            } else if (isalnum(c)) {
                if (!OnBoard(sqval)) {
                    return 0;
                }
                switch (c) {
                case 'p':
                    piece = BlackPawn;
                    break;
                case 'n':
                    piece = BlackKnight;
                    break;
                case 'b':
                    piece = BlackBishop;
                    break;
                case 'r':
                    piece = BlackRook;
                    break;
                case 'q':
                    piece = BlackQueen;
                    break;
                case 'k':
                    piece = BlackKing;
                    break;
                case 'P':
                    piece = WhitePawn;
                    break;
                case 'N':
                    piece = WhiteKnight;
                    break;
                case 'B':
                    piece = WhiteBishop;
                    break;
                case 'R':
                    piece = WhiteRook;
                    break;
                case 'Q':
                    piece = WhiteQueen;
                    break;
                case 'K':
                    piece = WhiteKing;
                    break;
                default:
                    return 0;
                }
                board.contents[sqval] = piece;
                sqval++;
                bp++;
            } else // not a letter or a digit
            {
                return 0;
            }
        }
        if (c == '/')
            ++bp; // skip delimiter
    }
    while (bp != buf.end() && isspace(*bp))
        bp++;
    if (bp == buf.end())
        return 0;
    if (toupper(*bp) == 'W')
        board.side = White;
    else if (toupper(*bp) == 'B')
        board.side = Black;
    else {
        return 0;
    }
    bp++;

    // Scan back ranks for King and Rook starting positions (needed for Chess960)
    Square w_king_sq = InvalidSquare;
    Square b_king_sq = InvalidSquare;
    for (int file = 0; file < 8; ++file) {
        if (board.contents[file] == WhiteKing) {
            w_king_sq = file;
        }
        if (board.contents[56 + file] == BlackKing) {
            b_king_sq = 56 + file;
        }
    }
    // Fallbacks to standard squares if not found
    if (w_king_sq == InvalidSquare) w_king_sq = chess::E1;
    if (b_king_sq == InvalidSquare) b_king_sq = chess::E8;

    board.kingStartSq[White] = w_king_sq;
    board.kingStartSq[Black] = b_king_sq;

    // Initialize rooks to invalid
    board.rookStartSq[White][Queenside] = board.rookStartSq[White][Kingside] = InvalidSquare;
    board.rookStartSq[Black][Queenside] = board.rookStartSq[Black][Kingside] = InvalidSquare;

    if (!board.isChess960()) {
        board.kingStartSq[White] = chess::E1;
        board.kingStartSq[Black] = chess::E8;
        board.rookStartSq[White][Queenside] = chess::A1;
        board.rookStartSq[White][Kingside] = chess::H1;
        board.rookStartSq[Black][Queenside] = chess::A8;
        board.rookStartSq[Black][Kingside] = chess::H8;
    }

    while (bp != buf.end() && isspace(*bp))
        bp++;
    if (bp == buf.end())
        return 0;
    c = *bp;
    if (c == '-') {
        board.state.castleStatus[White] = board.state.castleStatus[Black] = CantCastleEitherSide;
        bp++;
    } else {
        bool w_k = false, w_q = false, b_k = false, b_q = false;
        for (; bp != buf.end() && !isspace(*bp); bp++) {
            char ch = *bp;
            if (ch == 'K') {
                w_k = true;
                // Scan to the right of the White King for a rook
                Square rsq = InvalidSquare;
                for (int f = (w_king_sq % 8) + 1; f < 8; ++f) {
                    if (board.contents[f] == WhiteRook) { rsq = f; break; }
                }
                if (rsq != InvalidSquare) board.rookStartSq[White][Kingside] = rsq;
            }
            else if (ch == 'Q') {
                w_q = true;
                // Scan to the left of the White King for a rook
                Square rsq = InvalidSquare;
                for (int f = (w_king_sq % 8) - 1; f >= 0; --f) {
                    if (board.contents[f] == WhiteRook) { rsq = f; break; }
                }
                if (rsq != InvalidSquare) board.rookStartSq[White][Queenside] = rsq;
            }
            else if (ch == 'k') {
                b_k = true;
                // Scan to the right of the Black King for a rook
                Square rsq = InvalidSquare;
                for (int f = (b_king_sq % 8) + 1; f < 8; ++f) {
                    if (board.contents[56 + f] == BlackRook) { rsq = 56 + f; break; }
                }
                if (rsq != InvalidSquare) board.rookStartSq[Black][Kingside] = rsq;
            }
            else if (ch == 'q') {
                b_q = true;
                // Scan to the left of the Black King for a rook
                Square rsq = InvalidSquare;
                for (int f = (b_king_sq % 8) - 1; f >= 0; --f) {
                    if (board.contents[56 + f] == BlackRook) { rsq = 56 + f; break; }
                }
                if (rsq != InvalidSquare) board.rookStartSq[Black][Queenside] = rsq;
            }
            else if (ch >= 'A' && ch <= 'H') {
                int f = ch - 'A';
                if (f > (w_king_sq % 8)) {
                    w_k = true;
                    board.rookStartSq[White][Kingside] = f;
                } else {
                    w_q = true;
                    board.rookStartSq[White][Queenside] = f;
                }
            }
            else if (ch >= 'a' && ch <= 'h') {
                int f = ch - 'a';
                if (f > (b_king_sq % 8)) {
                    b_k = true;
                    board.rookStartSq[Black][Kingside] = 56 + f;
                } else {
                    b_q = true;
                    board.rookStartSq[Black][Queenside] = 56 + f;
                }
            }
            else {
                return 0; // Invalid character
            }
        }
        
        // If we found castling rights but the rook squares were not set,
        // use default standard squares or fallback to backrank rook positions.
        if (w_k && board.rookStartSq[White][Kingside] == InvalidSquare) {
            for (int f = (w_king_sq % 8) + 1; f < 8; ++f) {
                if (board.contents[f] == WhiteRook) { board.rookStartSq[White][Kingside] = f; break; }
            }
            if (board.rookStartSq[White][Kingside] == InvalidSquare) board.rookStartSq[White][Kingside] = chess::H1;
        }
        if (w_q && board.rookStartSq[White][Queenside] == InvalidSquare) {
            for (int f = (w_king_sq % 8) - 1; f >= 0; --f) {
                if (board.contents[f] == WhiteRook) { board.rookStartSq[White][Queenside] = f; break; }
            }
            if (board.rookStartSq[White][Queenside] == InvalidSquare) board.rookStartSq[White][Queenside] = chess::A1;
        }
        if (b_k && board.rookStartSq[Black][Kingside] == InvalidSquare) {
            for (int f = (b_king_sq % 8) + 1; f < 8; ++f) {
                if (board.contents[56 + f] == BlackRook) { board.rookStartSq[Black][Kingside] = 56 + f; break; }
            }
            if (board.rookStartSq[Black][Kingside] == InvalidSquare) board.rookStartSq[Black][Kingside] = chess::H8;
        }
        if (b_q && board.rookStartSq[Black][Queenside] == InvalidSquare) {
            for (int f = (b_king_sq % 8) - 1; f >= 0; --f) {
                if (board.contents[56 + f] == BlackRook) { board.rookStartSq[Black][Queenside] = 56 + f; break; }
            }
            if (board.rookStartSq[Black][Queenside] == InvalidSquare) board.rookStartSq[Black][Queenside] = chess::A8;
        }

        // Set castleStatus using CastleType values
        if (w_k && w_q) board.state.castleStatus[White] = CanCastleEitherSide;
        else if (w_k) board.state.castleStatus[White] = CanCastleKSide;
        else if (w_q) board.state.castleStatus[White] = CanCastleQSide;
        else board.state.castleStatus[White] = CantCastleEitherSide;

        if (b_k && b_q) board.state.castleStatus[Black] = CanCastleEitherSide;
        else if (b_k) board.state.castleStatus[Black] = CanCastleKSide;
        else if (b_q) board.state.castleStatus[Black] = CanCastleQSide;
        else board.state.castleStatus[Black] = CantCastleEitherSide;
    }
    board.setSecondaryVars();
    while (bp != buf.end() && isspace(*bp))
        bp++;
    if (bp == buf.end())
        return 0;
    c = *bp;
    if (c == '-') {
        board.state.enPassantSq = InvalidSquare;
    } else if (isalpha(c)) {
        char sqbuf[2];
        sqbuf[0] = *bp++;
        if (bp == buf.end())
            return 0;
        sqbuf[1] = *bp++;
        Square epsq = SquareValue(sqbuf);
        if (epsq == InvalidSquare) {
            return 0;
        }
        board.state.enPassantSq = InvalidSquare;
        Square ep_candidate = SquareValue(sqbuf) - (8 * Direction[board.sideToMove()]);
        // only actually set the e.p. square on the board if an en-passant capture
        // is truly possible:
        if (Attacks::ep_mask[File(ep_candidate) - 1][(int)board.oppositeSide()] &
            board.pawn_bits[board.sideToMove()]) {
            board.state.enPassantSq = ep_candidate;
            // re-calc hash code since ep has changed
            board.state.hashCode = BoardHash::hashCode(board);
        }
    } else {
        return 0;
    }
    assert(board.state.moveCount + 1 < Board::RepListSize);
    board.repList[board.state.moveCount++] = board.hashCode();
    if (board.kingPos[White] == InvalidSquare || board.kingPos[Black] == InvalidSquare) {
        return 0;
    }

    return 1;
}

void BoardIO::writeFEN(const Board &board, std::ostream &o, bool addMoveInfo) {
    // write out the board in Forsythe-Edwards (FEN) notation.
    for (int i = 1; i <= 8; i++) {
        int j = 1;
        while (j <= 8) {
            int n = 0;
            Square sq;
            Piece p;
            do {
                sq = MakeSquare(j, i, Black);
                p = board.contents[sq];
                if (p != EmptyPiece)
                    break;
                ++j;
                ++n;
            } while (j <= 8);
            if (n)
                o << (char)(n + '0');
            if (p != EmptyPiece) {
                char img = PieceImage(TypeOfPiece(p));
                if (PieceColor(p) == Black)
                    img = tolower(img);
                o << img;
                j++;
            }
        }
        if (i != 8)
            o << '/';
    }
    if (board.sideToMove() == White)
        o << " w";
    else
        o << " b";

    // used in I/O of castling data:
    constexpr bool kcastle[4] = {true, true, false, false};
    constexpr bool qcastle[4] = {true, false, true, false};

    int wcs = static_cast<int>(board.castleStatus(White));
    int bcs = static_cast<int>(board.castleStatus(Black));
    o << ' ';
    assert(wcs >= 0 && wcs <= 3 && bcs >=0 && wcs <=3);
    if (wcs == 3 && bcs == 3) {
        o << '-';
    } else {
        if (board.isChess960()) {
            if (kcastle[wcs]) {
                Square rsq = board.rookStartSq[White][1];
                if (rsq == chess::H1) o << 'K';
                else o << (char)std::toupper(FileImage(rsq));
            }
            if (qcastle[wcs]) {
                Square rsq = board.rookStartSq[White][0];
                if (rsq == chess::A1) o << 'Q';
                else o << (char)std::toupper(FileImage(rsq));
            }
            if (kcastle[bcs]) {
                Square rsq = board.rookStartSq[Black][1];
                if (rsq == chess::H8) o << 'k';
                else o << FileImage(rsq);
            }
            if (qcastle[bcs]) {
                Square rsq = board.rookStartSq[Black][0];
                if (rsq == chess::A8) o << 'q';
                else o << FileImage(rsq);
            }
        } else {
            if (kcastle[wcs])
                o << 'K';
            if (qcastle[wcs])
                o << 'Q';
            if (kcastle[bcs])
                o << 'k';
            if (qcastle[bcs])
                o << 'q';
        }
    }
    o << ' ';
    Square epsq = board.enPassantSq();
    if (epsq == InvalidSquare) {
        o << '-';
    } else {
        // FEN stores the destination square for an en passant capture;
        // we store the location of the capturable pawn.
        Square target = (board.sideToMove() == White) ? epsq + 8 : epsq - 8;
        o << FileImage(target) << RankImage(target);
    }
    if (addMoveInfo) {
        // FEN is supposed to include the halfmove and fullmove numbers,
        // but these are attributes of the game - they are not stored in
        // the board.
        o << " 0 1";
    }
}

void BoardIO::writeFEN(const Board &board, std::string &o, bool addMoveInfo) {
    std::stringstream s;
    writeFEN(board, s, addMoveInfo);
    o = s.str();
}
