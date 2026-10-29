// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Web ortamında tarayıcı / iOS Safari / macOS Apple Bildirim Merkezine bildirim ilet
Future<void> platformTriggerWebNotification({
  required String title,
  required String body,
  String? icon,
}) async {
  try {
    if (html.Notification.supported) {
      if (html.Notification.permission == 'granted') {
        html.Notification(title, body: body, icon: icon ?? '/favicon.png');
      } else if (html.Notification.permission != 'denied') {
        final perm = await html.Notification.requestPermission();
        if (perm == 'granted') {
          html.Notification(title, body: body, icon: icon ?? '/favicon.png');
        }
      }
    }

    // Telefon titreşim motoru tetikleme (iOS Safari / Android haptic)
    try {
      js.context.callMethod('eval', [
        'if (window.navigator && window.navigator.vibrate) { window.navigator.vibrate([100, 60, 140]); }'
      ]);
    } catch (_) {}
  } catch (_) {
    // Tarayıcı güvenlik veya izin istisnalarını sessizce yut
  }
}

/// Kullanıcı etkileşimi ile Apple Bildirim Merkezi izin penceresini aç
Future<bool> platformRequestNotificationPermission() async {
  try {
    if (html.Notification.supported) {
      final perm = await html.Notification.requestPermission();
      return perm == 'granted';
    }
  } catch (_) {}
  return false;
}

/// Mevcut bildirim izin durumu ('granted', 'denied', 'default', 'unsupported')
String platformGetNotificationPermissionStatus() {
  try {
    if (html.Notification.supported) {
      return html.Notification.permission ?? 'default';
    }
  } catch (_) {}
  return 'unsupported';
}

/// Web Audio API ile saf Apple Tri-Tone / Glass bildirim sesi sentezleme
Future<void> platformPlayIosChime() async {
  try {
    js.context.callMethod('eval', [r'''
      try {
        var AudioCtx = window.AudioContext || window.webkitAudioContext;
        if (AudioCtx) {
          var ctx = new AudioCtx();
          var now = ctx.currentTime;

          // 1. Ton: 659.25 Hz (E5)
          var osc1 = ctx.createOscillator();
          var gain1 = ctx.createGain();
          osc1.type = 'sine';
          osc1.frequency.setValueAtTime(659.25, now);
          gain1.gain.setValueAtTime(0.2, now);
          gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.18);
          osc1.connect(gain1);
          gain1.connect(ctx.destination);
          osc1.start(now);
          osc1.stop(now + 0.18);

          // 2. Ton: 880 Hz (A5 - Klasik Apple Tri-Tone)
          var osc2 = ctx.createOscillator();
          var gain2 = ctx.createGain();
          osc2.type = 'sine';
          osc2.frequency.setValueAtTime(880.0, now + 0.1);
          gain2.gain.setValueAtTime(0.25, now + 0.1);
          gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.38);
          osc2.connect(gain2);
          gain2.connect(ctx.destination);
          osc2.start(now + 0.1);
          osc2.stop(now + 0.38);
        }
      } catch(e) {}
    ''']);
  } catch (_) {
    // Audio context desteklenmiyorsa sessiz devam et
  }
}
