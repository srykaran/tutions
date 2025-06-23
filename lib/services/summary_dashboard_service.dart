import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/summary_dashboard.dart';

class SummaryDashboardService {
  static const String _collection = 'summary_dashboard';
  static const String _docId = 'main';
  static const String _cacheKey = 'summary_dashboard_cache';
  final _firestore = FirebaseFirestore.instance;

  // Get summary from local cache, or Firestore if not available
  Future<SummaryDashboard> getSummary() async {
    final cached = await _getSummaryFromCache();
    if (cached != null) return cached;
    try {
      final doc = await _firestore.collection(_collection).doc(_docId).get();
      if (doc.exists) {
        final summary = SummaryDashboard.fromJson(doc.data()!);
        await _setSummaryToCache(summary);
        return summary;
      } else {
        // Initialize if not exists
        final summary = SummaryDashboard(
          totalStudents: 0,
          totalBatches: 0,
          totalFees: 0.0,
          paidFees: 0.0,
        );
        await _firestore
            .collection(_collection)
            .doc(_docId)
            .set(summary.toJson());
        await _setSummaryToCache(summary);
        return summary;
      }
    } catch (e) {
      // On error, fallback to empty summary
      return SummaryDashboard(
        totalStudents: 0,
        totalBatches: 0,
        totalFees: 0.0,
        paidFees: 0.0,
      );
    }
  }

  // Update summary: update local cache first, then Firestore in background
  Future<void> updateSummary({
    int? studentDelta,
    int? batchDelta,
    double? totalFeesDelta,
    double? paidFeesDelta,
  }) async {
    // Update local cache
    final current = await getSummary();
    final updated = SummaryDashboard(
      totalStudents: current.totalStudents + (studentDelta ?? 0),
      totalBatches: current.totalBatches + (batchDelta ?? 0),
      totalFees: current.totalFees + (totalFeesDelta ?? 0.0),
      paidFees: current.paidFees + (paidFeesDelta ?? 0.0),
    );
    await _setSummaryToCache(updated);
    // Update Firestore in background
    _updateFirestoreSummary(updated);
  }

  // Internal: update Firestore (async, don't await in UI)
  Future<void> _updateFirestoreSummary(SummaryDashboard summary) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(_docId)
          .set(summary.toJson());
    } catch (e) {
      // Optionally log error
    }
  }

  // Local cache helpers
  Future<SummaryDashboard?> _getSummaryFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_cacheKey);
    if (jsonStr == null) return null;
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return SummaryDashboard.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  Future<void> _setSummaryToCache(SummaryDashboard summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, json.encode(summary.toJson()));
  }
}
