import 'package:get/get.dart';
import '../services/points_service.dart';

class PointsController extends GetxController {
  final RxInt totalPoints = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshPoints();
  }

  Future<void> refreshPoints() async {
    try {
      isLoading.value = true;
      final points = await PointsService().getTotalPoints();
      totalPoints.value = points;
    } catch (e) {
      print('Error refreshing points: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
