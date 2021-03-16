import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:randomchesshdi/blinking_dot.dart';
import 'package:randomchesshdi/chess.dart' as ch;
import 'package:randomchesshdi/chessboard/chessboard.dart';
import 'helpers.dart';
import 'consts.dart';
import 'dart:math' as math;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  InAppPurchaseConnection.enablePendingPurchases();
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
  String fen;
  //https://en.wikipedia.org/wiki/Forsyth%E2%80%93Edwards_Notation
  /* Handling In App Purchase */
  final InAppPurchaseConnection _connection = InAppPurchaseConnection.instance;
  StreamSubscription<List<PurchaseDetails>> _subscription;
  List<String> _notFoundIds = [];
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isStoreAvailable = false;
  bool _purchasePending = false;
  bool _isStoreloading = true;
  final String _kUpgradeId = 'com.huydung.randomchess.removeads'; //SKU
  List<String> _kProductIds = <String>['com.huydung.randomchess.removeads'];
  String _queryProductError;
  /* In App Purchase */

  BannerAd _ad;
  bool _storeAvailable = false;
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

    Stream<List<PurchaseDetails>> purchaseUpdated =
        InAppPurchaseConnection.instance.purchaseUpdatedStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // handle error here.
    });
    initStoreInfo();
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _connection.isAvailable();
    if (!isAvailable) {
      print('Store COnnection is not available');
      setState(() {
        _isStoreAvailable = isAvailable;
        _products = [];
        _purchases = [];
        _purchasePending = false;
        _isStoreloading = false;
      });
      return;
    }

    print('Store COnnection is available, trying to get the products');
    ProductDetailsResponse productDetailResponse =
        await _connection.queryProductDetails(_kProductIds.toSet());
    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error.message;
        _isStoreAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = [];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _purchasePending = false;
        _isStoreloading = false;
      });
      print('queryProductDetailError: $_queryProductError');
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        _isStoreAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = [];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _purchasePending = false;
        _isStoreloading = false;
      });
      print('queryProductDetailError: Empty');
      return;
    }

    final QueryPurchaseDetailsResponse purchaseResponse =
        await _connection.queryPastPurchases();
    if (purchaseResponse.error != null) {
      // handle query past purchase error..
    }
    final List<PurchaseDetails> verifiedPurchases = [];
    for (PurchaseDetails purchase in purchaseResponse.pastPurchases) {
      if (await _verifyPurchase(purchase)) {
        verifiedPurchases.add(purchase);
      }
    }

    setState(() {
      _isStoreAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _purchases = verifiedPurchases;
      _notFoundIds = productDetailResponse.notFoundIDs;
      _purchasePending = false;
      _isStoreloading = false;
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    print('_verifyPurchase');
    // IMPORTANT!! Always verify a purchase before delivering the product.
    // For the purpose of an example, we directly return true.
    return Future<bool>.value(true);
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    // handle invalid purchase here if  _verifyPurchase` failed.
    print('_handleInvalidPurchase');
  }

  void deliverProduct(PurchaseDetails purchaseDetails) async {
    // IMPORTANT!! Always verify purchase details before delivering the product.
    // if (purchaseDetails.productID == _kConsumableId) {
    //   await ConsumableStore.save(purchaseDetails.purchaseID!);
    //   List<String> consumables = await ConsumableStore.load();
    //   setState(() {
    //     _purchasePending = false;
    //     _consumables = consumables;
    //   });
    // } else {
    setState(() {
      _purchases.add(purchaseDetails);
      _purchasePending = false;
    });
    //}
  }

  void showPendingUI() {
    setState(() {
      _purchasePending = true;
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          handleError(purchaseDetails.error);
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            deliverProduct(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
            return;
          }
        }
        // if (Platform.isAndroid) {
        //   if (!_kAutoConsume && purchaseDetails.productID == _kConsumableId) {
        //     await InAppPurchaseConnection.instance
        //         .consumePurchase(purchaseDetails);
        //   }
        // }
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchaseConnection.instance
              .completePurchase(purchaseDetails);
        }
      }
    });
  }

  void handleError(IAPError error) {
    setState(() {
      print('IAP Error: ${error.message}');
      _purchasePending = false;
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    _subscription?.cancel();
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
      onPressed: () {
        ch.Move lastMove = ch.Chess.instance.undo_move();
        if (lastMove != null) {
          setState(() {
            fen = ch.Chess.instance.fen;
          });
        }
      },
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

  Widget _buildRandomizerUI() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ToggleButtons(
          borderColor: Colors.white54,
          fillColor: Colors.white70,
          textStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          selectedColor: Colors.black,
          direction: Axis.horizontal,
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
