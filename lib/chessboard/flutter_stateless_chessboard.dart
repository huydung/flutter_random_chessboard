library flutter_chessboard;

import 'package:flutter/material.dart';
import 'types.dart';
import 'utils.dart';
import 'widgets/chess_square.dart';
import '../chess.dart' as ch;

final zeroToSeven = List.generate(8, (index) => index);

class Chessboard extends StatefulWidget {
  final String fen;
  final double size;
  final String orientation; // 'w' | 'b'
  final bool Function(ShortMove move) onMove;
  final Color lightSquareColor;
  final Color darkSquareColor;

  Chessboard({
    @required this.fen,
    @required this.size,
    this.orientation = 'w',
    this.onMove,
    this.lightSquareColor = const Color.fromRGBO(240, 217, 181, 1),
    this.darkSquareColor = const Color.fromRGBO(181, 136, 99, 1),
  });

  @override
  State<StatefulWidget> createState() {
    return _ChessboardState();
  }
}

class _ChessboardState extends State<Chessboard> {
  HalfMove _clickMove;

  Map<String, Piece> _pieceMap = {};
  var _squares;
  @override
  Widget build(BuildContext context) {
    final squareSize = widget.size / 8;
    _pieceMap.clear();

    _squares = ch.Chess.SQUARES.keys.toList();
    _squares.forEach((square) {
      final piece = ch.Chess.instance.get(square);
      if (piece != null) {
        _pieceMap[square] = Piece(
            piece.type.toString(), piece.color == ch.Color.BLACK ? 'b' : 'w');
      }
    });

    return Container(
      width: widget.size,
      height: widget.size,
      child: Row(
        children: zeroToSeven.map((fileIndex) {
          return Column(
            children: zeroToSeven.map((rankIndex) {
              final square =
                  getSquare(rankIndex, fileIndex, widget.orientation);
              final color = (rankIndex + fileIndex) % 2 == 0
                  ? widget.lightSquareColor
                  : widget.darkSquareColor;
              return ChessSquare(
                name: square,
                color: color,
                size: squareSize,
                highlight: _clickMove != null && _clickMove.square == square,
                piece: _pieceMap[square],
                onDrop: (move) {
                  if (widget.onMove != null) {
                    widget.onMove(move);
                    setClickMove(null);
                  }
                },
                onClick: (halfMove) {
                  if (_clickMove != null) {
                    if (_clickMove.square == halfMove.square) {
                      setClickMove(null);
                      return;
                    }
                    if (_clickMove.piece.color == halfMove.piece?.color) {
                      setClickMove(halfMove);
                      return;
                    }

                    if (widget.onMove(ShortMove(
                      from: _clickMove.square,
                      to: halfMove.square,
                      promotion: 'q',
                    ))) {
                      setClickMove(null);
                    }
                  } else {
                    if (halfMove.piece != null &&
                        halfMove.piece.color ==
                            ch.Chess.instance.playerToMove) {
                      setClickMove(halfMove);
                    }
                  }
                },
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  void setClickMove(HalfMove move) {
    setState(() {
      _clickMove = move;
    });
  }
}
