import 'package:attendance_calendar/ads/ad_manager.dart';
import 'package:firebase_admob/firebase_admob.dart';

class ShowAds {
  BannerAd _bannerAd;

  void _loadBannerAd() {
    _bannerAd
      ..load()
      ..show(anchorType: AnchorType.bottom);
  }

  void showBannerAd() {
    this.disposeAds();

    _bannerAd = BannerAd(
      adUnitId: AdManager.bannerAdUnitId,
      size: AdSize.banner,
    );

    _bannerAd?.dispose();

    _loadBannerAd();
  }

  void disposeAds() {
    try {
      _bannerAd?.dispose();
      _bannerAd = null;
    } catch (ex) {
      print("banner dispose error $ex");
    }
  }
}
