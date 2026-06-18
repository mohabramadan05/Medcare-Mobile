import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/baby_model.dart';

// ── Service ───────────────────────────────────────────────────────────────────
//
// All monitoring data comes straight from Supabase tables, keyed by patient
// code (e.g. "B-0001"). For each we fetch the most recently created row.

class BabyMonitoringService {
  static Future<BabySensorReading?> getLatestSensorReading(
      String patientCode) async {
    final data = await Supabase.instance.client
        .from('baby_sensor_readings')
        .select()
        .eq('patient_code', patientCode)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle(); // null instead of throwing when no rows yet
    if (data == null) return null;
    return BabySensorReading.fromJson(data);
  }

  /// Emits the latest sensor reading immediately, then re-checks every [interval]
  /// (default 1 minute) for a newer record.
  static Stream<BabySensorReading?> sensorReadingStream(
    String patientCode, {
    Duration interval = const Duration(minutes: 1),
  }) {
    return _pollingStream(
      fetch: () => getLatestSensorReading(patientCode),
      interval: interval,
    );
  }

  /// Fetches the most recent [limit] sensor readings, newest first.
  static Future<List<BabySensorReading>> getRecentSensorReadings(
    String patientCode, {
    int limit = 5,
  }) async {
    final data = await Supabase.instance.client
        .from('baby_sensor_readings')
        .select()
        .eq('patient_code', patientCode)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => BabySensorReading.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Emits the most recent [limit] sensor readings immediately, then re-checks
  /// every [interval] (default 1 minute) for newer records.
  static Stream<List<BabySensorReading>> recentSensorReadingsStream(
    String patientCode, {
    int limit = 5,
    Duration interval = const Duration(minutes: 1),
  }) {
    return _pollingStream(
      fetch: () => getRecentSensorReadings(patientCode, limit: limit),
      interval: interval,
    );
  }

  static Future<BandReading?> getLatestBandReading(String patientCode) async {
    final data = await Supabase.instance.client
        .from('band_readings')
        .select()
        .eq('patient_code', patientCode)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle(); // null instead of throwing when no rows yet
    if (data == null) return null;
    return BandReading.fromJson(data);
  }

  /// Emits the latest band reading immediately, then re-checks every [interval]
  /// (default 1 minute) for a newer record.
  static Stream<BandReading?> bandReadingStream(
    String patientCode, {
    Duration interval = const Duration(minutes: 1),
  }) {
    return _pollingStream(
      fetch: () => getLatestBandReading(patientCode),
      interval: interval,
    );
  }

  /// Fetches the most recent [limit] band readings, newest first.
  static Future<List<BandReading>> getRecentBandReadings(
    String patientCode, {
    int limit = 5,
  }) async {
    final data = await Supabase.instance.client
        .from('band_readings')
        .select()
        .eq('patient_code', patientCode)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => BandReading.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Emits the most recent [limit] band readings immediately, then re-checks
  /// every [interval] (default 1 minute) for newer records.
  static Stream<List<BandReading>> recentBandReadingsStream(
    String patientCode, {
    int limit = 5,
    Duration interval = const Duration(minutes: 1),
  }) {
    return _pollingStream(
      fetch: () => getRecentBandReadings(patientCode, limit: limit),
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
