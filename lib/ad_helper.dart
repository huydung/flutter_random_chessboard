import 'dart:io';

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
