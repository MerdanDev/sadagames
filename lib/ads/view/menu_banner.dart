import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sadagames/ads/ads.dart';

/// The anchored banner under the game list.
///
/// It is on the menu and nowhere else. Game canvases run edge to edge, and a
/// banner next to a tap target invites the mis-taps that AdMob counts as
/// invalid traffic — the menu is the one screen with nothing to fat-finger.
///
/// Occupies no space until an ad has loaded, so the list never reflows under a
/// player who is mid-scroll.
class MenuBanner extends StatefulWidget {
  const MenuBanner({super.key});

  @override
  State<MenuBanner> createState() => _MenuBannerState();
}

class _MenuBannerState extends State<MenuBanner> {
  /// Held rather than read in dispose, where context is gone.
  late final GameAds _ads;

  BannerAd? _ad;
  bool _isLoaded = false;

  /// The width the current ad was sized for. Reloading on every pixel of a
  /// resize would churn impressions, so only a real change — a rotation —
  /// earns a new ad.
  double? _loadedForWidth;

  @override
  void initState() {
    super.initState();
    _ads = context.read<GameAds>();
    // Consent usually lands after the menu is already on screen, so the first
    // load is normally this listener firing rather than the build below.
    _ads.isReady.addListener(_loadForCurrentWidth);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadForCurrentWidth();
  }

  @override
  void dispose() {
    _ads.isReady.removeListener(_loadForCurrentWidth);
    unawaited(_ad?.dispose());
    super.dispose();
  }

  void _loadForCurrentWidth() {
    if (mounted) unawaited(_load(MediaQuery.sizeOf(context).width));
  }

  Future<void> _load(double width) async {
    if (!_ads.isReady.value || _loadedForWidth == width) return;
    _loadedForWidth = width;

    final size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSizeWithOrientation(
          Orientation.portrait,
          width.truncate(),
        );
    if (size == null || !mounted) return;

    final previous = _ad;
    final ad = BannerAd(
      size: size,
      adUnitId: _ads.menuBannerUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          // No retry: an empty slot is a fine outcome, and a retry loop on a
          // unit with no fill just drains the battery.
          log('menu banner failed to load: $error');
          unawaited(ad.dispose());
          if (mounted) setState(() => _isLoaded = false);
        },
      ),
    );

    _ad = ad;
    unawaited(previous?.dispose());
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_isLoaded || ad == null) return const SizedBox.shrink();

    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
