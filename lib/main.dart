import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:randomchesshdi/chess.dart' as ch;
import 'helpers.dart';
import 'flutter_stateless_chessboard/flutter_stateless_chessboard.dart';
import 'consts.dart';
import 'dart:math' as math;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Chess Generator /by HDI',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Random Chess Generator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String fen = ChessHelper.STANDARD_STARTING_POSITION;
  //https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation

  BannerAd _ad;
  bool _isAdLoaded = false;
  double _screenWidth = 320;
  double _boardWidth = 320;
  RandomizeMode selectedRandomMode = RandomizeMode.FULL_RANDOM;
  double centerUIpadding = 0;
  var _selectedMode = [false, false, true];

  void loadSavedFen() async {
    final savedFen = await DataHelper.getLastFEN();
    ch.Chess.instance.setFEN(savedFen);
    setState(() {
      fen = savedFen;
    });
  }

  @override
  void initState() {
    super.initState();
    ch.Chess.instance.setFEN(ChessHelper.STANDARD_STARTING_POSITION);
    loadSavedFen();

    Future.delayed(Duration(seconds: 3), () {
      _ad = BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        size: AdSize.largeBanner,
        request: AdRequest(),
        listener: AdListener(
          onAdLoaded: (_) {
            setState(() {
              _isAdLoaded = true;
            });
          },
          onAdFailedToLoad: (_, error) {
            print(
                'Ad load failed (code=${error.code} message=${error.message})');
          },
        ),
      );

      _ad.load();
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  Widget _buildBannerAds() {
    Widget widgetAdLoading = GestureDetector(
      onTap: () {
        LinkHelper.launchURL(K_DEFAULT_AD_LINK);
      },
      child: Image(
        image: AssetImage('assets/img/default_banner.png'),
      ),
    );
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
        width: AdSize.largeBanner.width.toDouble(),
        alignment: Alignment.center,
      );
    }
  }

  void _purchaseRemoveAds() {}

  Widget _buildChessboard(width) {
    return Chessboard(
        fen: fen,
        size: width,
        darkSquareColor: K_HDI_DARK_RED,
        lightSquareColor: K_HDI_LIGHT_GREY,
        orientation: 'w',
        onMove: (move) {
          bool moveMade = ch.Chess.instance
              .move({'from': move.from, 'to': move.to, 'promotion': 'q'});
          print(
              "Tried to move from ${move.from} to ${move.to}. Success: $moveMade");
          if (moveMade) {
            setState(() {
              fen = ch.Chess.instance.fen;
              DataHelper.saveFEN(fen);
            });
          }
        });
  }

  Widget _buildRandomizerUI() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ToggleButtons(
          direction: Axis.horizontal,
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Random Board'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Chess960'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text('Standard'),
            ),
          ],
          isSelected: _selectedMode,
          onPressed: (int index) {
            var _newMode = [false, false, false];
            _newMode[index] = true;
            setState(() {
              _selectedMode = _newMode;
              if (index == 0)
                fen = ChessHelper.generateRandomPosition(
                    RandomizeMode.FULL_RANDOM);
              else if (index == 1)
                fen = ChessHelper.generateRandomPosition(RandomizeMode.FISCHER);
              else
                fen = ChessHelper.STANDARD_STARTING_POSITION;
              ch.Chess.instance.setFEN(fen);
              DataHelper.saveFEN(fen);
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width.toDouble();
    if (_screenWidth > K_PHONE_WIDTH_PX) {
      centerUIpadding = (_screenWidth - K_PHONE_WIDTH_PX) * 0.5;
    }
    _boardWidth = _screenWidth > 560 ? 560 : _screenWidth;
    //print('Queried Size: ${size.width}, centerUIpadding: $centerUIpadding');

    return Scaffold(
      appBar: AppBar(
        title: Text("Random Chess Generator"),
        actions: [
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _screenWidth,
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Transform.rotate(
                angle: math.pi,
                child: Text(
                  (ch.Chess.instance.playerToMove == 'b'
                      ? 'YOUR TURN'
                      : '-- WAIT --'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24.0,
                    backgroundColor: (ch.Chess.instance.playerToMove == 'b'
                        ? Colors.green[800]
                        : null),
                  ),
                ),
              ),
            ),
            Container(
              width: _boardWidth,
              height: _boardWidth,
              child: _buildChessboard(_boardWidth),
            ),
            Container(
              width: _screenWidth,
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                (ch.Chess.instance.playerToMove == 'w'
                    ? 'YOUR TURN'
                    : '-- WAIT --'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.0,
                  backgroundColor: (ch.Chess.instance.playerToMove == 'w'
                      ? Colors.green[800]
                      : null),
                ),
              ),
            ),
            Divider(
              height: 20.0,
            ),
            _buildRandomizerUI(),
            Divider(
              height: 20.0,
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
