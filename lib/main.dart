import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:randomchesshdi/blinking_turn_indicator.dart';
import 'package:randomchesshdi/chess.dart' as ch;
import 'package:randomchesshdi/chessboard/flutter_stateless_chessboard.dart';
import 'helpers.dart';
import 'consts.dart';
import 'dart:math' as math;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(MyApp());
}

class Configs {
  String fen = ChessHelper.STANDARD_STARTING_POSITION;
  int lastSelectedMode = 0;
  bool firstTimeTutorialShown = false;
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
  String fen;
  //https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation

  BannerAd _ad;
  bool _isAdLoaded = false;
  double _screenWidth = 320;
  double _boardWidth = 320;
  RandomizeMode selectedRandomMode = RandomizeMode.FULL_RANDOM;
  bool _isShowingHint;
  bool _playingStarted = false;
  var _selectedMode = [true, false, false];

  void loadSavedFen() async {
    final savedFen = await DataHelper.getLastFEN();
    ch.Chess.instance.setFEN(savedFen);
    setState(() {
      fen = savedFen;
      _selectedMode = [false, false, false];
    });
  }

  @override
  void initState() {
    super.initState();
    fen = ChessHelper.generateRandomPosition(RandomizeMode.FULL_RANDOM);
    ch.Chess.instance.setFEN(fen);
    //loadSavedFen();

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
              _playingStarted = true;
            });
          }
          return moveMade;
        });
  }

  Widget _buildPaymentButton() {
    return Container(
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
    );
  }

  Widget _buildTurnIndicator(ch.Color forSide) {
    double rotationAngle = forSide == ch.Color.BLACK ? math.pi : 0;
    Widget turnIndicator;
    if (forSide == ch.Chess.instance.turn) {
      turnIndicator = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BlinkingDotIndicator(
            color: Colors.green,
            size: 20.0,
          ),
          SizedBox(
            width: 5.0,
          ),
          Text(
            "YOUR TURN",
            style: TextStyle(fontSize: 20.0),
          ),
        ],
      );
    } else {
      turnIndicator = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "-- WAIT --",
            style: TextStyle(fontSize: 20.0, color: Colors.grey[700]),
          ),
        ],
      );
    }

    return Visibility(
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      visible: _playingStarted,
      child: Container(
        width: _screenWidth,
        padding: EdgeInsets.symmetric(vertical: 10.0),
        child: Transform.rotate(
            angle: forSide == ch.Color.BLACK ? math.pi : 0,
            child: turnIndicator),
      ),
    );
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
              _playingStarted = false;
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

  Widget _builPhoneView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTurnIndicator(ch.Color.BLACK),
        Container(
          width: _boardWidth,
          height: _boardWidth,
          child: _buildChessboard(_boardWidth),
        ),
        _buildTurnIndicator(ch.Color.WHITE),
        Divider(
          height: 20.0,
        ),
        _buildRandomizerUI(),
        Divider(
          height: 20.0,
        ),
        _buildBannerAds(),
        _buildPaymentButton(),
      ],
    );
  }

  Widget _buildTabletView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTurnIndicator(ch.Color.BLACK),
                Container(
                  width: _boardWidth,
                  height: _boardWidth,
                  child: _buildChessboard(_boardWidth),
                ),
                _buildTurnIndicator(ch.Color.WHITE),
              ],
            ),
          ],
        ),
        Divider(
          height: 20.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRandomizerUI(),
                SizedBox(height: 10.0),
                _buildPaymentButton(),
              ],
            ),
            SizedBox(width: 10.0),
            _buildBannerAds(),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width.toDouble();
    _boardWidth = _screenWidth > K_TWO_COLUMN_THRESHOLD
        ? K_TWO_COLUMN_THRESHOLD.toDouble()
        : _screenWidth;
    print('Queried Size: _screenWidth');

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
          child: _screenWidth > K_TWO_COLUMN_THRESHOLD
              ? _buildTabletView()
              : _builPhoneView()),
    );
  }
}
