import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:randomchesshdi/utils/platfom_info.dart';
import 'package:randomchesshdi/views/blinking_dot.dart';
import 'package:randomchesshdi/chess.dart' as ch;
import 'package:randomchesshdi/chessboard/chessboard.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:universal_platform/universal_platform.dart';
import 'utils/helpers.dart';
import 'consts.dart';
import 'dart:math' as math;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/foundation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.supportAds) {
    MobileAds.instance.initialize();
  }

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

  AdSize _adSize;
  bool _isBannerAdLoaded = false;
  bool _isFSAdsLoaded = false;
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
    if (AppConfig.supportIAP) {
      initRevenueCatState();
    }
  }

  @override
  Widget build(BuildContext context) {
    AppConfig.update(MediaQuery.of(context));
    _boardWidth = AppConfig.boardWidth;
    _adSize = AppConfig.isBigAds ? AdSize.leaderboard : AdSize.largeBanner;

    Widget bodyWidget;

    bodyWidget =
        AppConfig.isLandscape ? _buildLandscapeView() : _buildPortraitView();

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
        child: bodyWidget,
      ),
    );
  }

/* RevenueCat integration */

  PurchaserInfo _purchaserInfo;
  Offerings _offerings;
  Package _iapPackage;

  Future<void> initRevenueCatState() async {
    if (!AppConfig.supportIAP) return;

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
    if (!AppConfig.supportIAP) return;

    print('Load available offerings');
    Offerings offerings;
    try {
      offerings = await Purchases.getOfferings();
    } on PlatformException catch (e) {
      print(e);
      _showStatus(e.message);
      return;
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
            return;
          }
        }
      }
    });

    _showStatus("Fail to get offering from revenuecat.");
  }

  void _showStatus(text) {
    final snackBar = SnackBar(content: Text(text));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    //Get.snackbar(text, '');
  }

  void _restorePurchase() async {
    if (!AppConfig.supportIAP) return;

    _showStatus('Restoring your purchases, if any...');
    setState(() {
      _isProcessingPurchase = true;
    });
    try {
      PurchaserInfo restoredInfo = await Purchases.restoreTransactions();
      _setUserAsPro(restoredInfo);
      setState(() {
        _isProcessingPurchase = false;
      });
    } catch (e) {
      print('Error restore purchase');
      _showStatus(
          'Can not restore purchases. Please check your account details, internet connections, and payment history, or try again later.');
    }
  }

  void _setUserAsPro(PurchaserInfo purchaserInfo) {
    if (!AppConfig.supportIAP) return;

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
      // Get.defaultDialog(
      //   title: "Thank you",
      //   content:
      //       Text("Your support is much appreciated. All Ads are removed now."),
      // );
    }
  }

  void _purchaseRemoveAds() async {
    if (!AppConfig.supportIAP) return;

    if (_isProcessingPurchase) {
      print(
          '_purchaseRemoveAds() already trying to purchase, click too fast? ');
      return;
    }
    _showStatus('Preparing your purchase');
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
      _showStatus(
          'There was an error processing your purchase. Please wait a few minutes and try again.');
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
        _playingStarted = true;
      } else {
        setRandomMode(_config.lastSelectedMode);
      }
    });
  }

  void loadFullScreenAd() {
    if (!AppConfig.supportAds) return;

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
    if (!AppConfig.supportAds) return;

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
    super.dispose();
  }

  Widget _buildBannerAds() {
    if (!AppConfig.supportAds) return Container();

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
                androidAppId: 'com.thinkinhd.randomchess');
          },
          child: Image(
            image: AssetImage(AppConfig.isBigAds
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

  Widget _buildPaymentWidget() {
    if (!AppConfig.supportIAP) return Container();

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

    if (_iapPackageAvailableForPurchase && !_isProcessingPurchase) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          OutlinedButton.icon(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.resolveWith<Color>(
                  (states) => Colors.brown[100]),
              overlayColor: MaterialStateProperty.resolveWith<Color>(
                  (states) => Colors.brown[500]),
            ),
            label: Text('Remove Ads'),
            icon: Icon(
              Icons.favorite_border_outlined,
              color: Colors.red[700],
            ),
            onPressed: _purchaseRemoveAds,
          ),
          restoreButton,
        ],
      );
    }
    if (_isPro && _proStatusValidated) {
      if (AppConfig.isBigAds) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            heartIcon,
            Text(
              ' Thank you for the support! If you still see ads, please try',
              style: TextStyle(color: Colors.grey[600]),
            ),
            restoreButton
          ],
        );
      } else {
        return FittedBox(
          fit: BoxFit.none,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    heartIcon,
                    Text(
                      ' Thank you for the support!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 5.0,
                    ),
                    Text(
                      'If you still see ads, please',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    restoreButton,
                  ],
                )
              ],
            ),
          ),
        );
      }
    }
    return Container();
  }

  Widget _buildTurnIndicator(ch.Color forSide) {
    bool explicitName = false;
    bool rotateBlack = true;
    if (!AppConfig.optimizeTwoPlayersUX) {
      explicitName = true;
      rotateBlack = false;
    }

    double rotationAngle =
        rotateBlack ? (forSide == ch.Color.BLACK ? math.pi : 0) : 0;
    String name =
        explicitName ? (forSide == ch.Color.BLACK ? 'BLACK' : 'WHITE') : 'YOU';
    String nameAdj = explicitName
        ? (forSide == ch.Color.BLACK ? 'BLACK\'S' : 'WHITE\'S')
        : 'YOUR';
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
              "$name LOSE!",
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
              "$name WON!",
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
              "$nameAdj TURN",
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
        width: double.infinity,
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

  Widget _buildPortraitView() {
    print('Build Portrait View');
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
            _buildPaymentWidget(),
          ],
        ),
      ],
    );
  }

  Widget _buildLandscapeView() {
    print('Build Landscape View');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRandomizerUI(vertical: true),
        SizedBox(
          width: 20.0,
        ),
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
              ],
            ),
          ],
        ),
      ],
    );
  }
}
