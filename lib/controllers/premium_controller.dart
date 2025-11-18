import 'package:get/get.dart';
import '../services/points_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PremiumController extends GetxController {
  final RxBool isPremium = false.obs;
  final RxInt remainingDays = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadPremiumStatus();

    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((_) {
      loadPremiumStatus();
    });
  }

  Future<void> loadPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final pointsService = PointsService();
      isPremium.value = await pointsService.isPremiumUnlocked();
      remainingDays.value = await pointsService.getRemainingPremiumDays();
    } else {
      isPremium.value = false;
      remainingDays.value = 0;
    }
  }

  Future<void> refreshPremiumStatus() async {
    await loadPremiumStatus();
  }
}
