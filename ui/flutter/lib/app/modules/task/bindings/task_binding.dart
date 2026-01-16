import 'package:get/get.dart';

import '../controllers/task_controller.dart';
import '../controllers/task_all_controller.dart';
import '../controllers/task_downloaded_controller.dart';
import '../controllers/task_downloading_controller.dart';
import '../controllers/task_error_controller.dart';

class TaskBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TaskController>(
      () => TaskController(),
    );
    Get.lazyPut<TaskDownloadingController>(
      () => TaskDownloadingController(),
    );
    Get.lazyPut<TaskAllController>(
      () => TaskAllController(),
    );
    Get.lazyPut<TaskDownloadedController>(
      () => TaskDownloadedController(),
    );
    Get.lazyPut<TaskErrorController>(
      () => TaskErrorController(),
    );
  }
}
