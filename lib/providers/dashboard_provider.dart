import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardProvider = StateNotifierProvider<DashboardNotifier, int>((ref) {
  return DashboardNotifier();
});

class DashboardNotifier extends StateNotifier<int> {
  DashboardNotifier() : super(0);

  void setSelectedIndex(int index) {
    state = index;
  }
}
