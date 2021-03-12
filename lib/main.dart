import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'helpers.dart';
import 'flutter_stateless_chessboard/flutter_stateless_chessboard.dart';
import 'consts.dart';
import 'dart:math';

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
  RandomizeMode selectedRandomMode = RandomizeMode.FULL_RANDOM;
  double centerUIpadding = 0;

  void loadSavedFen() async {
    final savedFen = await DataHelper.getLastFEN();
    setState(() {
      fen = savedFen;
    });
  }

  @override
  void initState() {
    super.initState();
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
        width: _screenWidth,
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
          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.cached),
                  label: Text('GENERATE'),
                  onPressed: () {
                    setState(() {
                      fen = ChessHelper.generateRandomPosition(
                          selectedRandomMode);
                      DataHelper.saveFEN(fen);
                    });
                  },
                ),
              ),
              SizedBox(
                width: 30,
              ),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.play_circle_fill_outlined),
                  label: Text('PLAY!'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) => Colors.green[800]),
                  ),
                  onPressed: () {
                    setState(() {
                      fen = ChessHelper.generateRandomPosition(
                          selectedRandomMode);
                    });
                  },
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width.toDouble();
    if (_screenWidth > K_PHONE_WIDTH_PX) {
      centerUIpadding = (_screenWidth - K_PHONE_WIDTH_PX) * 0.5;
    }
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
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _screenWidth,
              height: _screenWidth,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    child: _buildChessboard(_screenWidth),
                  ),
                  Container(
                    width: _screenWidth,
                    height: _screenWidth / 2,
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
