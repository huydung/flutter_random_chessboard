import 'package:flutter/material.dart';

import 'package:randomchesshdi/consts.dart';
import 'package:universal_platform/universal_platform.dart';

class AppConfig {
  static bool get supportIAP {
    return (UniversalPlatform.isIOS || UniversalPlatform.isAndroid);
  }

  static bool get supportAds {
    return (UniversalPlatform.isIOS || UniversalPlatform.isAndroid);
  }

  static double _boardWidth = 320;
  static double get boardWidth => _boardWidth;

  static bool _isLandscape = false;
  static bool get isLandscape => _isLandscape;

  static bool _isBigAds = false;
  static bool get isBigAds => _isBigAds;

  static bool get optimizeTwoPlayersUX =>
      (UniversalPlatform.isIOS || UniversalPlatform.isAndroid);

  static void update(MediaQueryData query) {
    double width = query.size.width;
    double height = query.size.height;
    print('AppConfig being updated for width = $width and height = $height');

    _isLandscape = width > height;

    _isBigAds = width >= K_NEEDS_BIG_ADS;

    //determine the correct size for the Chessboard
    double verticalPadding = 56 +
        (28 *
            2.0); //the height of the two turn indicators plus the AppBar plus the randomizer
    double horizontalPadding =
        100; //the width of the randomizer in vertical, to be confirm later.

    if (supportIAP && !_isLandscape) {
      verticalPadding +=
          40; // the height of a normal text widget - to be confirm later
    }
    if (supportAds && !_isLandscape) {
      verticalPadding +=
          _isBigAds ? 90 : 100; //Leaderboard Ads vs Large Banner Ads
    }
    if (!_isLandscape) {
      verticalPadding += 120; //the Randomizer height
    }

    if (_isLandscape) {
      double tmpWidth = width - horizontalPadding;
      double tmpHeight = height - verticalPadding;
      if (tmpWidth > tmpHeight) {
        _boardWidth = tmpHeight;
      } else {
        _boardWidth = tmpWidth;
      }
    } else {
      double tmpWidth = height - verticalPadding;
      if (tmpWidth > width) {
        _boardWidth = width;
      } else {
        _boardWidth = tmpWidth;
      }
    }

    //set a minBoardWidth
    if (_boardWidth < 340) {
      _boardWidth = 340;
    }
    print('Set ChessboardWidth to $_boardWidth');
  }
}
