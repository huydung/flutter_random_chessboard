import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:randomchesshdi/blinking_dot.dart';
import 'package:randomchesshdi/chess.dart' as ch;
import 'package:randomchesshdi/chessboard/chessboard.dart';
import 'helpers.dart';
import 'consts.dart';
import 'dart:math' as math;
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) => runApp(MyApp()));
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
      home: MyHomePage(title: 'Random Chess - Fun Learning'),
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
  AdSize _adSize;
  bool _isAdLoaded = false;
  double _screenWidth = 320;
  double _boardWidth = 320;

  bool _playingStarted = false;
  var _selectedMode = [false, false, false];

  ConfigStruct _config;

  bool _isPro = false;
  bool _proStatusValidated = false;
  bool _iapPackageAvailableForPurchase = false;

  @override
  void initState() {
    super.initState();
    fen = ChessHelper.generateRandomPosition(RandomizeMode.FULL_RANDOM);
    ch.Chess.instance.setFEN(fen);
    loadConfigs();
    //loadSavedFen();
    initRevenueCatState();
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width.toDouble();
    print("_screenWidth = $_screenWidth");
    if (_screenWidth > K_TWO_COLUMN_THRESHOLD) {
      _boardWidth = (_screenWidth - K_TABLET_PADDING).toDouble();
      _adSize = AdSize.fullBanner;
    } else {
      _boardWidth = _screenWidth;
      _adSize = AdSize.leaderboard;
    }

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
              ? _builPhoneView()
              : _builPhoneView()),
    );
  }

/* RevenueCat integration */

  PurchaserInfo _purchaserInfo;
  Offerings _offerings;
  Package _iapPackage;

  Future<void> initRevenueCatState() async {
    await Purchases.setDebugLogsEnabled(true);
    await Purchases.setup("XrqNInJynDtEdaZCxRDmDJURILfaxmMi");
    PurchaserInfo purchaserInfo = await Purchases.getPurchaserInfo();
    print('initRevenueCatState()');

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _purchaserInfo = purchaserInfo;
      _proStatusValidated = true;
      if (_purchaserInfo != null) {
        if (_purchaserInfo.entitlements.active.containsKey(K_ENTITLEMENT_KEY)) {
          print('User purchased the Pro package!');
          _isPro = true;
        } else {
          _isPro = false;
          print('User did not purchase the Pro package, let try offering it');
          fetchOfferingsData();
        }
      }
    });
  }

  Future<void> fetchOfferingsData() async {
    print('Load available offerings');
    Offerings offerings;
    try {
      offerings = await Purchases.getOfferings();
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return;

    setState(() {
      _offerings = offerings;
      if (offerings != null) {
        if (_offerings.current.lifetime != null) {
          _iapPackage = _offerings.current.lifetime;
          if (_iapPackage != null) {
            print('Offering available, show it now!');
            _iapPackageAvailableForPurchase = true;
          }
        }
      }
    });
  }

  bool _isProcessingPurchase = false;

  void _purchaseRemoveAds() async {
    if (_isProcessingPurchase) {
      print(
          '_purchaseRemoveAds() already trying to purchase, click too fast? ');
      return;
    }
    _isProcessingPurchase = true;

    try {
      PurchaserInfo purchaserInfo =
          await Purchases.purchasePackage(_iapPackage);
      setState(() {
        if (purchaserInfo.entitlements.all[K_ENTITLEMENT_KEY] != null) {
          _isPro = purchaserInfo.entitlements.all[K_ENTITLEMENT_KEY].isActive;
          _proStatusValidated = true;
          _iapPackageAvailableForPurchase = false;
        }
      });
      _isProcessingPurchase = false;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      print(errorCode);
      print('Error during purchase!');
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        print("User cancelled");
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        print("User not allowed to purchase");
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        print("Payment is pending");
      }
      _isProcessingPurchase = false;
    }
  }

  /* end of Revenue Cat integration */

  void loadConfigs() async {
    _config = await DataHelper.getConfigs();
    setState(() {
      if (_config.isPlaying) {
        print('Reload the last saved FEN ${_config.fen}');
        fen = _config.fen;
        ch.Chess.instance.setFEN(fen);
      } else {
        setRandomMode(_config.lastSelectedMode);
      }
    });
  }

  void loadAd() {
    print("_loadAd is called");
    if (_ad == null) {
      print("Start loading Ads");
      _ad = BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        size: _adSize,
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
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    //_subscription?.cancel();
    super.dispose();
  }

  Widget _buildBannerAds() {
    if (_proStatusValidated && !_isPro) {
      print('_buildBannerAds() should actually start loading Ads now');
      // Widget widgetAdLoading = GestureDetector(
      //   onTap: () {
      //     LinkHelper.launchURL(K_DEFAULT_AD_LINK);
      //   },
      //   child: Image(
      //     image: AssetImage('assets/img/default_banner.png'),
      //   ),
      // );
      loadAd();
      if (_isAdLoaded) {
        return Container(
          child: AdWidget(ad: _ad),
          width: _ad.size.width.toDouble(),
          height: _ad.size.height.toDouble(),
          alignment: Alignment.center,
        );
      }
    }
    return Container(
      child: null,
      width: _adSize.width.toDouble(),
      height: _adSize.height.toDouble(),
      alignment: Alignment.center,
    );
  }

  Widget _buildChessboard(width) {
    return Chessboard(
      fen: fen,
      size: width,
      darkSquareColor: K_HDI_DARK_RED,
      lightSquareColor: K_HDI_LIGHT_GREY,
      orientation: 'w',
      onMove: _makeChessMove,
    );
  }

  bool _makeChessMove(move) {
    bool moveMade = ch.Chess.instance
        .move({'from': move.from, 'to': move.to, 'promotion': 'q'});
    print("Tried to move from ${move.from} to ${move.to}. Success: $moveMade");
    if (moveMade) {
      setState(() {
        fen = ch.Chess.instance.fen;

        _playingStarted = true;
        _config.isPlaying = true;
        _config.fen = fen;
        DataHelper.saveConfigs(_config);
      });
    }
    return moveMade;
  }

  Widget _buildPaymentButton() {
    return Visibility(
      visible: _iapPackageAvailableForPurchase,
      maintainSize: true,
      maintainState: true,
      maintainAnimation: true,
      child: OutlinedButton.icon(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith<Color>(
              (states) => Colors.green[200]),
          overlayColor: MaterialStateProperty.resolveWith<Color>(
              (states) => Colors.green[500]),
        ),
        label: Text('Remove Ads'),
        icon: Icon(Icons.sentiment_very_satisfied),
        onPressed: _purchaseRemoveAds,
      ),
    );
  }

  Widget _buildTurnIndicator(ch.Color forSide) {
    double rotationAngle = forSide == ch.Color.BLACK ? math.pi : 0;
    List<Widget> turnIndicators;
    if (ch.Chess.instance.in_checkmate) {
      if (forSide == ch.Chess.instance.turn) {
        turnIndicators = [
          BlinkingDotIndicator(
            color: Colors.red,
            size: 20.0,
          ),
          SizedBox(
            width: 5.0,
          ),
          Expanded(
            child: Text(
              "YOU LOSE!",
              style: TextStyle(fontSize: 18.0),
            ),
          ),
        ];
      } else {
        turnIndicators = [
          BlinkingDotIndicator(
            color: Colors.green,
            size: 20.0,
          ),
          SizedBox(
            width: 5.0,
          ),
          Expanded(
            child: Text(
              "YOU WON!",
              style: TextStyle(fontSize: 18.0),
            ),
          ),
        ];
      }
    } else {
      if (forSide == ch.Chess.instance.turn) {
        turnIndicators = [
          BlinkingDotIndicator(
            color: Colors.white,
            size: 20.0,
          ),
          SizedBox(
            width: 5.0,
          ),
          Expanded(
            child: Text(
              "YOUR TURN",
              style: TextStyle(fontSize: 18.0),
            ),
          ),
        ];
      } else {
        turnIndicators = [
          Expanded(
            child: Text(
              "-- WAIT --",
              style: TextStyle(fontSize: 18.0, color: Colors.grey[700]),
            ),
          ),
        ];
      }
    }

    turnIndicators.add(TextButton.icon(
      icon: Icon(
        Icons.undo,
      ),
      onPressed: _makeChessUndoMove,
      label: Text("UNDO"),
    ));

    return Visibility(
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      visible: _playingStarted,
      child: Container(
        width: _screenWidth,
        padding: EdgeInsets.symmetric(
          vertical: 0.0,
          horizontal: 15.0,
        ),
        child: Transform.rotate(
          angle: rotationAngle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: turnIndicators,
          ),
        ),
      ),
    );
  }

  void _makeChessUndoMove() {
    ch.Move lastMove = ch.Chess.instance.undo_move();
    if (lastMove != null) {
      setState(() {
        fen = ch.Chess.instance.fen;
        _config.fen = fen;
        DataHelper.saveConfigs(_config);
      });
    }
  }

  Widget _buildRandomizerUI({bool vertical = false}) {
    return ToggleButtons(
      //borderColor: Colors.white54,
      fillColor: Colors.white70,
      textStyle: TextStyle(
        color: Colors.black,
        fontSize: 18,
      ),
      selectedColor: Colors.black,
      direction: vertical ? Axis.vertical : Axis.horizontal,
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Text('Random Board'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Text('Chess960'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Text('Standard'),
        ),
      ],
      isSelected: _selectedMode,
      onPressed: (int index) {
        setRandomMode(index);
        //saveData
        _config.lastSelectedMode = index;
        _config.isPlaying = false;
        _config.boardGenerated++;
        DataHelper.saveConfigs(_config);
      },
    );
  }

  void setRandomMode(int modeIndex) {
    setState(() {
      print('setRandomMode $modeIndex');
      var _newMode = [false, false, false];
      _newMode[modeIndex] = true;
      _selectedMode = _newMode;
      _playingStarted = false;
      if (modeIndex == 0)
        fen = ChessHelper.generateRandomPosition(RandomizeMode.FULL_RANDOM);
      else if (modeIndex == 1)
        fen = ChessHelper.generateRandomPosition(RandomizeMode.FISCHER);
      else
        fen = ChessHelper.STANDARD_STARTING_POSITION;
      ch.Chess.instance.setFEN(fen);
      _config.fen = fen;
    });
  }

  Widget _builPhoneView() {
    return Column(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: _boardWidth,
                child: Column(
                  children: [
                    _buildTurnIndicator(ch.Color.BLACK),
                    _buildChessboard(_boardWidth),
                    _buildTurnIndicator(ch.Color.WHITE),
                  ],
                )),
            Divider(
              height: 20.0,
            ),
            _buildRandomizerUI(),
            Divider(
              height: 20.0,
            ),
            (_proStatusValidated && !_isPro) ? _buildBannerAds() : Container(),
            //_buildBannerAds(),
            _buildPaymentButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletView() {
    // return Column(
    //   mainAxisSize: MainAxisSize.min,
    //   children: [
    //     Row(
    //       children: [
    //         Container(
    //           width: _boardWidth,
    //           height: _boardWidth,
    //           child: _buildChessboard(_boardWidth),
    //         ),
    //         Container(
    //           width: K_SECOND_COLIUMN_WIDTH.toDouble(),
    //           height: _boardWidth,
    //           child: Column(
    //             mainAxisAlignment: MainAxisAlignment.spaceAround,
    //             crossAxisAlignment: CrossAxisAlignment.center,
    //             children: [
    //               _buildTurnIndicator(ch.Color.BLACK),
    //               Expanded(
    //                   child: Center(child: _buildRandomizerUI(vertical: true))),
    //               _buildTurnIndicator(ch.Color.WHITE),
    //             ],
    //           ),
    //         )
    //       ],
    //     ),
    //     Divider(height: 20.0),
    //     _buildBannerAds(),
    //     _buildPaymentButton()
    //   ],
    // );
    // return Column(
    //   mainAxisSize: MainAxisSize.min,
    //   children: [
    //     Row(
    //       children: [
    //         Column(
    //           mainAxisSize: MainAxisSize.min,
    //           children: [
    //             _buildTurnIndicator(ch.Color.BLACK),
    //             Container(
    //               width: _boardWidth,
    //               height: _boardWidth,
    //               child: _buildChessboard(_boardWidth),
    //             ),
    //             _buildTurnIndicator(ch.Color.WHITE),
    //           ],
    //         ),
    //       ],
    //     ),
    //     Divider(
    //       height: 20.0,
    //     ),
    //     Row(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Column(
    //           crossAxisAlignment: CrossAxisAlignment.end,
    //           mainAxisAlignment: MainAxisAlignment.spaceAround,
    //           children: [
    //             _buildRandomizerUI(),
    //             SizedBox(height: 10.0),
    //             _buildPaymentButton(),
    //           ],
    //         ),
    //         SizedBox(width: 10.0),
    //         _buildBannerAds(),
    //       ],
    //     ),
    //   ],
    // );
  }
}
