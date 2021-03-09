import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';
import '../types.dart';
import 'square.dart';
import 'dart:math' as math;

class ChessPiece extends StatelessWidget {
  final String squareName;
  final Color squareColor;
  final Piece piece;
  final double size;

  ChessPiece({
    @required this.squareName,
    @required this.squareColor,
    @required this.piece,
    @required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final pieceWidget = _buildPiece();

    return Draggable<HalfMove>(
      data: HalfMove(squareName, piece),
      child: pieceWidget,
      feedback: pieceWidget,
      childWhenDragging: Square(
        color: squareColor,
        size: size,
      ),
    );
  }

  Widget _buildPiece() {
    //print(piece.toString());
    //huydung_mod: Added Transform.rotate to rotate the pieces
    switch (piece.toString()) {
      case 'wr':
        return WhiteRook(size: size);
      case 'wn':
        return WhiteKnight(size: size);
      case 'wb':
        return WhiteBishop(size: size);
      case 'wk':
        return WhiteKing(size: size);
      case 'wq':
        return WhiteQueen(size: size);
      case 'wp':
        return WhitePawn(size: size);
      case 'br':
        return Transform.rotate(angle: math.pi, child: BlackRook(size: size));
      case 'bn':
        return Transform.rotate(angle: math.pi, child: BlackKnight(size: size));
      case 'bb':
        return Transform.rotate(angle: math.pi, child: BlackBishop(size: size));
      case 'bk':
        return Transform.rotate(angle: math.pi, child: BlackKing(size: size));
      case 'bq':
        return Transform.rotate(angle: math.pi, child: BlackQueen(size: size));
      case 'bp':
        return Transform.rotate(angle: math.pi, child: BlackPawn(size: size));
      default:
        return null;
    }
  }
}
