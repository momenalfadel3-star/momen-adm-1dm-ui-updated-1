import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../views/buid_task_list_view.dart';
import '../controllers/task_all_controller.dart';

class TaskAllView extends GetView<TaskAllController> {
  const TaskAllView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BuildTaskListView(
      listController: controller,
      tasks: controller.tasks,
      selectedTaskIds: controller.selectedTaskIds,
    );
  }
}
