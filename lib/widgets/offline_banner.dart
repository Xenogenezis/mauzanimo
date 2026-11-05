import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../lang/app_strings.dart';
import '../providers/language_provider.dart';

/// Thin banner shown across the top of the app while the device has no
/// network. Content keeps working from Firestore's local cache underneath.
class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    final c = Connectivity();
    c.checkConnectivity().then(_update).catchError((_) {});
    _sub = c.onConnectivityChanged.listen(_update, onError: (_) {});
  }

  void _update(List<ConnectivityResult> r) {
    final offline = r.isEmpty || r.every((e) => e == ConnectivityResult.none);
    if (mounted && offline != _offline) setState(() => _offline = offline);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _offline
              ? Material(
                  color: Colors.grey.shade800,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              AppStrings.get('offline_banner', lang),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: _offline,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
