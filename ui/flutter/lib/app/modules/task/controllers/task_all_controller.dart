import '../../../../api/model/task.dart';
import 'task_list_controller.dart';

/// All tasks (like 1DM "ALL" tab).
class TaskAllController extends TaskListController {
  TaskAllController()
      : super(
          const [
            Status.ready,
            Status.running,
            Status.pause,
            Status.wait,
            Status.error,
            Status.done,
          ],
          (a, b) {
            // running first, then latest updated.
            if (a.status == Status.running && b.status != Status.running) {
              return -1;
            }
            if (a.status != Status.running && b.status == Status.running) {
              return 1;
            }
            return b.updatedAt.compareTo(a.updatedAt);
          },
        );
}
