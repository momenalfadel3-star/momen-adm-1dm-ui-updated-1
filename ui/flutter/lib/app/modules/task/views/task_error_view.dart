import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../views/buid_task_list_view.dart';
import '../controllers/task_error_controller.dart';

class TaskErrorView extends GetView<TaskErrorController> {
  const TaskErrorView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BuildTaskListView(
      listController: controller,
      tasks: controller.tasks,
      selectedTaskIds: controller.selectedTaskIds,
    );
  }
}
