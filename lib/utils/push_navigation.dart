import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../screens/rescue/rescue_list_screen.dart';

/// Navigator of the main app, so a tapped notification can open a screen.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

bool _pendingRescueOpen = false;

/// A rescue notification (data `type: rescue`, sent by the
/// notifyNearbyRescuers Cloud Function).
bool isRescuePush(Map<String, dynamic> data) => data['type'] == 'rescue';

/// True once if the app was launched by tapping a rescue notification.
/// HomeScreen calls this when it first appears, because at launch the splash
/// and login flow still own the navigator.
bool takePendingRescueOpen() {
  final pending = _pendingRescueOpen;
  _pendingRescueOpen = false;
  return pending;
}

@visibleForTesting
void setPendingRescueOpenForTest(bool value) => _pendingRescueOpen = value;

void openRescueList(NavigatorState navigator) {
  navigator.push(MaterialPageRoute(builder: (_) => const RescueListScreen()));
}

/// Opens the rescue list when a rescue notification is tapped. Call once
/// after Firebase is initialised. Does nothing where push is not set up.
Future<void> initPushNavigation() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    // App was closed: remember it for HomeScreen.
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null && isRescuePush(initial.data)) _pendingRescueOpen = true;

    // App was in the background: go straight there.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (!isRescuePush(message.data)) return;
      final navigator = appNavigatorKey.currentState;
      if (navigator != null) {
        openRescueList(navigator);
      } else {
        _pendingRescueOpen = true;
      }
    });
  } catch (_) {
    // Push is optional: never block app start on it.
  }
}
