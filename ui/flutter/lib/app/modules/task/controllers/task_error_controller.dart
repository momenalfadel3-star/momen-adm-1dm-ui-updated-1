import '../../../../api/model/task.dart';
import 'task_list_controller.dart';

/// Failed tasks (1DM "ERROR" tab).
class TaskErrorController extends TaskListController {
  TaskErrorController()
      : super(const [Status.error], (a, b) => b.updatedAt.compareTo(a.updatedAt));
}
