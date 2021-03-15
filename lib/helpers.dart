import 'dart:io';
import 'dart:math';
import 'package:randomchesshdi/consts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LinkHelper {
  static void launchURL(String url) async {
    //const url = 'https://flutter.dev';
    if (await canLaunch(url) != null) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class DataHelper {
  static Future<String> getLastFEN() async {
    final prefs = await SharedPreferences.getInstance();
    String fen =
        prefs.getString('fen') ?? ChessHelper.STANDARD_STARTING_POSITION;
    print('Read from disk fen = $fen');
    return fen;
  }

  static void saveFEN(String fen) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('fen', fen);
    print('Saved $fen');
  }
}

class ChessHelper {
  static const String STANDARD_STARTING_POSITION =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  static String generateRandomPosition(randomMode) {
    var fen;
    if (randomMode == RandomizeMode.FISCHER) {
      var rng = new Random();
      var index = rng.nextInt(960);
      fen = K_FEN960_LIST[index];
    } else if (randomMode == RandomizeMode.FULL_RANDOM) {
      fen = _randomizePieces('rnbqkbnrpppppppp') +
          '/8/8/8/8/' +
          _randomizePieces('PPPPPPPPRNBQKBNR', reversed: true) +
          ' w - - 0 1';
    }
    return fen;
  }

  static String _randomizePieces(String piecesList, {bool reversed = false}) {
    List<String> pieces = piecesList.split('');
    pieces.shuffle();

    int attemps = 0;
    while (!_isValidStartingPos(pieces)) {
      pieces.shuffle();
      attemps++;
      print('Invalid Board, Reshuffle!');
    }

    print('TOTAL attempts to reach a valid Board: $attemps');

    String randomizedPieces = reversed ? pieces.reversed.join() : pieces.join();
    randomizedPieces =
        randomizedPieces.substring(0, 8) + '/' + randomizedPieces.substring(8);
    return randomizedPieces;
  }

  static bool _isValidStartingPos(List<String> pieces) {
    //Check for specific rules:

    bool isValideStartingPos = true;
    List<String> lowerCasePieces = pieces.map((e) => e.toLowerCase()).toList();

    // - The king should not be exposed on the frontline
    int indexOfKing = lowerCasePieces.indexOf('k');
    //print('indexOfKing = $indexOfKing');

    if (indexOfKing > 7) {
      isValideStartingPos = false;
      //print('King Exposed!');
    }

    // - The two bishop should be on different color
    int firstBishop = lowerCasePieces.indexOf('b');
    int lastBishop = lowerCasePieces.lastIndexOf('b');
    //print('indexOfBishops = $firstBishop & $lastBishop');
    if ((firstBishop < 8 && lastBishop < 8) ||
        (firstBishop > 7 && lastBishop > 7)) {
      //When two bishop are in the same row, they will be on same color if their index summed into an even number
      if ((firstBishop + lastBishop).isEven) {
        isValideStartingPos = false;
        //print('Bishops on same color!');
      }
    } else {
      //When two bishop are in different row, they will be on same color if their index summed into an odd number
      if ((firstBishop + lastBishop).isOdd) {
        isValideStartingPos = false;
        //print('Bishops on same color!');
      }
    }
    return isValideStartingPos;
  }
}

class AdHelper {
  static String _env = 'test';
  static String _platform = 'apple';

  static Map<String, Map<String, Map<String, String>>> adsIds = {
    'test': {
      'android': {
        'banner': 'ca-app-pub-3940256099942544/6300978111',
        'native': 'ca-app-pub-3940256099942544/2247696110'
      },
      'apple': {
        'banner': 'ca-app-pub-3940256099942544/2934735716',
        'native': 'ca-app-pub-3940256099942544/3986624511'
      },
    },
    'prod': {
      'android': {
        'banner': 'ca-app-pub-4757047581054358/7600361025',
        'native': 'ca-app-pub-4757047581054358/8712463846'
      },
      'apple': {
        'banner': 'ca-app-pub-4757047581054358/2338627183',
        'native': 'ca-app-pub-4757047581054358/1226524369'
      },
    }
  };

  static _detectPlatform() {
    if (Platform.isAndroid) {
      _platform = 'android';
    } else if (Platform.isIOS) {
      _platform = 'apple';
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get bannerAdUnitId {
    _detectPlatform();
    return adsIds[_env][_platform]['banner'];
  }

  static String get nativeAdUnitId {
    _detectPlatform();
    return adsIds[_env][_platform]['native'];
  }
}
