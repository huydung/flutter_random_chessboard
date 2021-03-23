import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:randomchesshdi/blinking_dot.dart';
import 'package:randomchesshdi/chess.dart' as ch;
import 'package:randomchesshdi/chessboard/chessboard.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:store_redirect/store_redirect.dart';
import 'helpers.dart';
import 'consts.dart';
import 'dart:math' as math;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
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
      debugShowCheckedModeBanner: false,
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
  InterstitialAd _fsAd;

  bool _isTablet = false;
  AdSize _adSize;
  bool _isBannerAdLoaded = false;
  bool _isFSAdsLoaded = false;
  double _screenWidth = 320;
  double _boardWidth = 320;

  bool _playingStarted = false;
  var _selectedMode = [false, false, false];

  ConfigStruct _config;

  bool _isPro = false;
  bool _proStatusValidated = false;
  bool _iapPackageAvailableForPurchase = false;
  bool _isProcessingPurchase = false;

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
      _isTablet = true;
      _boardWidth = (_screenWidth - K_TABLET_PADDING).toDouble();
      _adSize = AdSize.leaderboard;
    } else {
      _isTablet = false;
      _boardWidth = _screenWidth;
      _adSize = AdSize.fullBanner;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Random Chess Generator"),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.help),
        //     onPressed: () {},
        //   )
        // ],
      ),
      body: SingleChildScrollView(
          child: _screenWidth > K_TWO_COLUMN_THRESHOLD
              ? _buildTabletView()
              : _buildPhoneView()),
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
          _proStatusValidated = true;
        } else {
          _isPro = false;
          _proStatusValidated = true;
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
        if (_offerings.current != null && _offerings.current.lifetime != null) {
          _iapPackage = _offerings.current.lifetime;
          if (_iapPackage != null) {
            print('Offering available, show it now!');
            _iapPackageAvailableForPurchase = true;
          }
        }
      }
    });
  }

  void _restorePurchase() async {
    try {
      PurchaserInfo restoredInfo = await Purchases.restoreTransactions();
      _setUserAsPro(restoredInfo);
    } catch (e) {
      print('Error restore purchase');
    }
  }

  void _setUserAsPro(PurchaserInfo purchaserInfo) {
    if (purchaserInfo.entitlements.all[K_ENTITLEMENT_KEY] != null) {
      setState(() {
        _isPro = purchaserInfo.entitlements.all[K_ENTITLEMENT_KEY].isActive;
        _proStatusValidated = true;
        _iapPackageAvailableForPurchase = false;
        _isProcessingPurchase = false;
      });
      print('Set user as Pro user');
    }
    if (_isPro) {
      Alert(
              context: context,
              title: "Thank you",
              type: AlertType.success,
              style: AlertStyle(
                  backgroundColor: Colors.white, isButtonVisible: false),
              desc:
                  "Your support is much appreciated. All Ads are removed now.")
          .show();
    }
  }

  void _purchaseRemoveAds() async {
    if (_isProcessingPurchase) {
      print(
          '_purchaseRemoveAds() already trying to purchase, click too fast? ');
      return;
    }
    setState(() {
      _isProcessingPurchase = true;
    });

    try {
      PurchaserInfo purchaserInfo =
          await Purchases.purchasePackage(_iapPackage);
      _setUserAsPro(purchaserInfo);
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
      setState(() {
        _isProcessingPurchase = false;
      });
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

  void loadFullScreenAd() {
    print('loadFullScreenAd is called');
    if (_fsAd == null) {
      print('Start actually loading full screen ad');
      _fsAd = InterstitialAd(
        adUnitId: AdHelper.fullScreenAdUnitId,
        request: AdRequest(),
        listener: AdListener(
          onAdLoaded: (Ad ad) {
            print('Full Screen loaded.');
            _isFSAdsLoaded = true;
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('Ad failed to load: $error');
          },
          // Called when an ad opens an overlay that covers the screen.
          onAdOpened: (Ad ad) => print('Ad opened.'),
          // Called when an ad removes an overlay that covers the screen.
          onAdClosed: (Ad ad) => print('Ad closed.'),
          // Called when an ad is in the process of leaving the application.
          onApplicationExit: (Ad ad) => print('Left application.'),
        ),
      );
      _fsAd.load();
    }
  }

  void loadBannerAd() {
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
              _isBannerAdLoaded = true;
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
    _fsAd?.dispose();
    //_subscription?.cancel();
    super.dispose();
  }

  Widget _buildBannerAds() {
    if (_proStatusValidated && !_isPro) {
      print('_buildBannerAds() should actually start loading Ads now');

      Widget placeholderAds = Container(
        width: _adSize.width.toDouble(),
        //height: _adSize.height.toDouble(),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {
            //LinkHelper.launchURL(K_DEFAULT_AD_LINK);
            StoreRedirect.redirect(
                iOSAppId: '1558633367',
                androidAppId: 'com.huydung.randomchess');
          },
          child: Image(
            image: AssetImage(_isTablet
                ? 'assets/img/AdSizeLeaderboard.png'
                : 'assets/img/AdSizeLargeBanner.png'),
          ),
        ),
      );

      //Show placeholder banner for few seonds during debug, to check the flow and positioning

      Future.delayed(Duration(seconds: kReleaseMode ? 0 : 15)).then((value) {
        loadBannerAd();
        loadFullScreenAd();
      });

      if (_isBannerAdLoaded) {
        return Container(
          child: AdWidget(ad: _ad),
          width: _ad.size.width.toDouble(),
          height: _ad.size.height.toDouble(),
          alignment: Alignment.center,
        );
      } else {
        return placeholderAds;
      }
    }
    return Container();
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
    if (_iapPackageAvailableForPurchase && !_isProcessingPurchase) {
      return OutlinedButton.icon(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith<Color>(
              (states) => Colors.brown[100]),
          overlayColor: MaterialStateProperty.resolveWith<Color>(
              (states) => Colors.brown[500]),
        ),
        label: Text('Support Us & Remove Ads'),
        icon: Icon(
          Icons.local_cafe,
          color: Colors.brown[200],
        ),
        onPressed: _purchaseRemoveAds,
      );
    }
    if (_isPro && _proStatusValidated) {
      Widget restoreButton = TextButton(
        onPressed: _restorePurchase,
        child: Text(
          'Restore Purchase.',
          style: TextStyle(
              color: Colors.grey[500], decoration: TextDecoration.underline),
        ),
      );

      Widget heartIcon = Icon(
        Icons.favorite_sharp,
        color: Colors.red[700],
      );
      if (_isTablet) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            heartIcon,
            Text(
              ' Thank you for the support! If ads are still showing, please try',
              style: TextStyle(color: Colors.grey[600]),
            ),
            restoreButton
          ],
        );
      } else {
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heartIcon,
                Text(
                  ' Thank you for the support!\n If ads are still showing, please try',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            restoreButton,
          ],
        );
      }
    }
    return Container();
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
        if (_config.boardGenerated % K_FULLSCREEN_ADS_THRESHOLD == 0) {
          if (_isFSAdsLoaded && !_isPro) {
            _fsAd.show();
          }
        }
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

  Widget _buildPhoneView() {
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
            _buildPaymentButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletView() {
    return Column(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: _boardWidth,
                  child: Column(
                    children: [
                      _buildTurnIndicator(ch.Color.BLACK),
                      _buildChessboard(_boardWidth),
                      _buildTurnIndicator(ch.Color.WHITE),
                    ],
                  ),
                ),
                _buildRandomizerUI(vertical: true),
              ],
            ),
            Divider(
              height: 20.0,
            ),
            (_proStatusValidated && !_isPro) ? _buildBannerAds() : Container(),
            _buildPaymentButton(),
          ],
        ),
      ],
    );
  }
}
