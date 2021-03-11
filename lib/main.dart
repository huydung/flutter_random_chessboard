import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';
import 'flutter_stateless_chessboard/flutter_stateless_chessboard.dart';
import 'consts.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Chess',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Random Chess'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  Future<InitializationStatus> _initGoogleMobileAds() {
    return MobileAds.instance.initialize();
  }

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  //https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation

  BannerAd _ad;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: AdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (_, error) {
          print('Ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    );

    _ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  RandomizeMode selectedRandomMode = RandomizeMode.FULL_RANDOM;
  double centerUIpadding = 0;

  Widget _buildBannerAds() {
    Widget widgetAdLoading = Text('Loading Ads');

    if (_isAdLoaded) {
      return Container(
        child: AdWidget(ad: _ad),
        width: _ad.size.width.toDouble(),
        height: _ad.size.height.toDouble(),
        alignment: Alignment.center,
      );
    } else {
      return Container(
        color: Colors.grey[800],
        child: widgetAdLoading,
        height: AdSize.banner.height.toDouble(),
        alignment: Alignment.center,
      );
    }
  }

  void _generateRandomPosition() {
    if (selectedRandomMode == RandomizeMode.FISCHER) {
      var rng = new Random();
      var index = rng.nextInt(960);
      setState(() {
        fen = K_FEN960_LIST[index];
      });
    } else if (selectedRandomMode == RandomizeMode.FULL_RANDOM) {
      setState(() {
        fen = _randomizePieces('rnbqkbnrpppppppp') +
            '/8/8/8/8/' +
            _randomizePieces('PPPPPPPPRNBQKBNR', reversed: true) +
            ' w KQkq - 0 1';
      });
    }
  }

  String _randomizePieces(String piecesList, {bool reversed = false}) {
    List<String> pieces = piecesList.split('');
    pieces.shuffle();

    int attemps = 0;
    while (!isValidStartingPos(pieces)) {
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

  bool isValidStartingPos(List<String> pieces) {
    //Check for specific rules:

    bool isValideStartingPos = true;
    List<String> lowerCasePieces = pieces.map((e) => e.toLowerCase()).toList();

    // - The king should not be exposed on the frontline
    int indexOfKing = lowerCasePieces.indexOf('k');
    //print('indexOfKing = $indexOfKing');

    if (indexOfKing > 7) {
      isValideStartingPos = false;
      print('King Exposed!');
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
        print('Bishops on same color!');
      }
    } else {
      //When two bishop are in different row, they will be on same color if their index summed into an odd number
      if ((firstBishop + lastBishop).isOdd) {
        isValideStartingPos = false;
        print('Bishops on same color!');
      }
    }
    return isValideStartingPos;
  }

  void _purchaseRemoveAds() {}

  Widget _buildChessboard(width) {
    return Chessboard(
      fen: fen,
      size: width,
      orientation: 'w',
      onMove: (move) {
        print("move from ${move.from} to ${move.to}");
      },
    );
  }

  Widget _buildRandomizerUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RadioListTile<RandomizeMode>(
          title: const Text('Fully Randomized'),
          value: RandomizeMode.FULL_RANDOM,
          groupValue: selectedRandomMode,
          onChanged: (RandomizeMode value) {
            setState(() {
              selectedRandomMode = value;
            });
          },
          secondary: IconButton(
            icon: Icon(Icons.info_outline_rounded),
            onPressed: () {},
          ),
        ),
        RadioListTile<RandomizeMode>(
          title: const Text('Chess690 - Fischer'),
          value: RandomizeMode.FISCHER,
          groupValue: selectedRandomMode,
          onChanged: (RandomizeMode value) {
            setState(() {
              selectedRandomMode = value;
            });
          },
          secondary: IconButton(
            icon: Icon(Icons.info_outline_rounded),
            onPressed: () {},
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: ElevatedButton.icon(
            icon: Icon(Icons.cached),
            label: Text('GENERATE'),
            onPressed: _generateRandomPosition,
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (size.width > K_PHONE_WIDTH_PX) {
      centerUIpadding = (size.width - K_PHONE_WIDTH_PX) * 0.5;
    }
    //print('Queried Size: ${size.width}, centerUIpadding: $centerUIpadding');

    return Scaffold(
      appBar: AppBar(
        title: Text("Random Chess"),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size.width,
              height: size.width,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    child: _buildChessboard(size.width),
                  ),
                  Container(
                    width: size.width,
                    height: size.width / 2,
                    color: Colors.black.withAlpha(96),
                    padding: EdgeInsets.symmetric(
                      horizontal: centerUIpadding,
                    ),
                    child: _buildRandomizerUI(),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 15.0,
            ),
            _buildBannerAds(),
            Container(
              child: OutlinedButton.icon(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) => Colors.green[500]),
                  overlayColor: MaterialStateProperty.resolveWith<Color>(
                      (states) => Colors.green[800]),
                ),
                label: Text('Remove Ads'),
                icon: Icon(Icons.sentiment_very_satisfied),
                onPressed: _purchaseRemoveAds,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
