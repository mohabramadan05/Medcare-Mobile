import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/baby_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DEV FALLBACK — used only when a baby has no monitor_url stored in Supabase.
// Set this to your test server address while developing without a real Pi.
//
//  • Android emulator   → http://10.0.2.2:5000
//  • Real phone on WiFi → http://<YOUR-PC-LAN-IP>:5000
//  • ngrok              → https://<SUBDOMAIN>.ngrok-free.app
//
// In production each baby's Pi URL comes from Supabase (monitor_url column),
// so you never need to change this constant once real hardware is set up.
// ─────────────────────────────────────────────────────────────────────────────
const String kDevServerUrl = 'http://10.0.2.2:5000';

const _kHeaders = {
  'Content-Type': 'application/json',
  // Skips the ngrok browser-warning interstitial on the free tier.
  // Harmless to include when not using ngrok.
  'ngrok-skip-browser-warning': 'true',
};

// ── Vitals model ──────────────────────────────────────────────────────────────

class BabyVitals {
  final int heartRate;        // bpm
  final double temperature;   // °C
  final int spo2;             // %

  const BabyVitals({
    required this.heartRate,
    required this.temperature,
    required this.spo2,
  });

  factory BabyVitals.fromJson(Map<String, dynamic> json) => BabyVitals(
        heartRate: json['heart_rate'] as int,
        temperature: (json['temperature'] as num).toDouble(),
        spo2: json['spo2'] as int,
      );
}

// ── Service ───────────────────────────────────────────────────────────────────
//
// Every public method accepts an explicit [serverUrl].
// This is the Pi's base URL for THIS baby — each baby has its own Pi,
// each Pi has its own ngrok URL stored in Supabase.
//
// URL format:  https://<subdomain>.ngrok-free.app   (real Pi via ngrok)
//              http://10.0.2.2:5000                 (test server on emulator)

class BabyMonitoringService {
  // ── One-shot fetches ──────────────────────────────────────────────────────

  static Future<List<BabyAlertModel>> getAlerts(
      String babyId, String serverUrl) async {
    final res = await http
        .get(
          Uri.parse('$serverUrl/baby/$babyId/alerts'),
          headers: _kHeaders,
        )
        .timeout(const Duration(seconds: 5));

    if (res.statusCode != 200) {
      throw Exception('GET /alerts -> HTTP ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => BabyAlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<BabyVitals> getVitals(
      String babyId, String serverUrl) async {
    final res = await http
        .get(
          Uri.parse('$serverUrl/baby/$babyId/vitals'),
          headers: _kHeaders,
        )
        .timeout(const Duration(seconds: 5));

    if (res.statusCode != 200) {
      throw Exception('GET /vitals -> HTTP ${res.statusCode}');
    }
    return BabyVitals.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  // ── Polling streams ───────────────────────────────────────────────────────

  static Stream<List<BabyAlertModel>> alertsStream(
    String babyId,
    String serverUrl, {
    Duration interval = const Duration(seconds: 3),
  }) {
    return _pollingStream(
      fetch: () => getAlerts(babyId, serverUrl),
      interval: interval,
    );
  }

  static Stream<BabyVitals> vitalsStream(
    String babyId,
    String serverUrl, {
    Duration interval = const Duration(seconds: 3),
  }) {
    return _pollingStream(
      fetch: () => getVitals(babyId, serverUrl),
      interval: interval,
    );
  }

  // ── Internal helper ───────────────────────────────────────────────────────

  static Stream<T> _pollingStream<T>({
    required Future<T> Function() fetch,
    required Duration interval,
  }) {
    late StreamController<T> controller;
    bool cancelled = false;

    Future<void> poll() async {
      while (!cancelled) {
        try {
          final value = await fetch();
          if (!cancelled && !controller.isClosed) controller.add(value);
        } catch (e, st) {
          if (!cancelled && !controller.isClosed) controller.addError(e, st);
        }
        await Future.delayed(interval);
      }
    }

    controller = StreamController<T>(
      onListen: poll,
      onCancel: () => cancelled = true,
    );

    return controller.stream;
  }
}
