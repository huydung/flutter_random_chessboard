import '../chess.dart' as ch;
import 'types.dart';

String getSquare(int rankIndex, int fileIndex, String orientation) {
  final rank = orientation == 'b' ? rankIndex + 1 : 8 - rankIndex;
  final file = orientation == 'b' ? 7 - fileIndex : fileIndex;
  return '${String.fromCharCode(file + 97)}$rank';
}
