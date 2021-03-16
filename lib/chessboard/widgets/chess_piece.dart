import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';
import 'package:randomchesshdi/chess.dart' as ch;
import '../types.dart';
import 'square.dart';
import 'dart:math' as math;

class ChessPiece extends StatefulWidget {
  final String squareName;
  final Color squareColor;
  final Piece piece;
  final double size;
  final bool setToMove;

  ChessPiece(
      {@required this.squareName,
      @required this.squareColor,
      @required this.piece,
      @required this.size,
      this.setToMove = false});

  @override
  _ChessPieceState createState() => _ChessPieceState();
}

class _ChessPieceState extends State<ChessPiece> with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;
  Tween<double> _tween = Tween(begin: 0.9, end: 1.1);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _controller.repeat(reverse: true);
    _animation = _tween
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    final pieceWidget = _buildPiece();

    return Draggable<HalfMove>(
      data: HalfMove(widget.squareName, widget.piece),
      child: Container(
        width: widget.size,
        height: widget.size,
        child: pieceWidget,
      ),
      feedback: pieceWidget,
      childWhenDragging: Square(
        color: widget.squareColor,
        size: widget.size,
      ),
    );
  }

  Widget _buildPiece() {
    //print(piece.toString());
    //huydung_mod: Added Transform.rotate to rotate the pieces

    var pieceWidget;
    switch (widget.piece.toString()) {
      case 'wr':
        pieceWidget = WhiteRook(size: widget.size);
        break;
      case 'wn':
        pieceWidget = WhiteKnight(size: widget.size);
        break;
      case 'wb':
        pieceWidget = WhiteBishop(size: widget.size);
        break;
      case 'wk':
        pieceWidget = WhiteKing(size: widget.size);
        break;
      case 'wq':
        pieceWidget = WhiteQueen(size: widget.size);
        break;
      case 'wp':
        pieceWidget = WhitePawn(size: widget.size);
        break;
      case 'br':
        pieceWidget = BlackRook(size: widget.size);
        break;
      case 'bn':
        pieceWidget = BlackKnight(size: widget.size);
        break;
      case 'bb':
        pieceWidget = BlackBishop(size: widget.size);
        break;
      case 'bk':
        pieceWidget = BlackKing(size: widget.size);
        break;
      case 'bq':
        pieceWidget = BlackQueen(size: widget.size);
        break;
      case 'bp':
        pieceWidget = BlackPawn(size: widget.size);
        break;
      default:
        return null;
    }
    if (widget.piece.color == 'b') {
      pieceWidget = Transform.rotate(
        angle: math.pi,
        child: pieceWidget,
      );
    }

    if (widget.setToMove) {
      pieceWidget = ScaleTransition(
        scale: _animation,
        alignment: Alignment.center,
        child: pieceWidget,
      );
    }

    return pieceWidget;
  }
}
