import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;

import '../../../../api/model/task.dart';
import '../../../../util/file_explorer.dart';
import '../../../../util/util.dart';
import '../../../routes/app_pages.dart';
import '../../../views/copy_button.dart';
import '../controllers/task_controller.dart';
import '../controllers/task_all_controller.dart';
import '../controllers/task_downloaded_controller.dart';
import '../controllers/task_downloading_controller.dart';
import '../controllers/task_error_controller.dart';
import 'task_all_view.dart';
import 'task_downloaded_view.dart';
import 'task_downloading_view.dart';
import 'task_error_view.dart';

class TaskView extends GetView<TaskController> {
  const TaskView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectTask = controller.selectTask;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        key: controller.scaffoldKey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(102),
          child: AppBar(
            title: const Text('1DM'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // reserved for future search
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // reserved for future menu
                },
              ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabs: const [
                Tab(text: 'ALL'),
                Tab(text: 'DOWNLOADING'),
                Tab(text: 'FINISHED'),
                Tab(text: 'ERROR'),
              ],
              onTap: (index) {
                if (controller.tabIndex.value == index) return;

                controller.tabIndex.value = index;

                // Start/stop polling to reduce load.
                final all = Get.find<TaskAllController>();
                final downloading = Get.find<TaskDownloadingController>();
                final downloaded = Get.find<TaskDownloadedController>();
                final error = Get.find<TaskErrorController>();

                all.stop();
                downloading.stop();
                downloaded.stop();
                error.stop();

                switch (index) {
                  case 0:
                    all.start();
                    break;
                  case 1:
                    downloading.start();
                    break;
                  case 2:
                    downloaded.start();
                    break;
                  case 3:
                    error.start();
                    break;
                }
              },
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            TaskAllView(),
            TaskDownloadingView(),
            TaskDownloadedView(),
            TaskErrorView(),
          ],
        ),
        endDrawer: Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: Obx(() => ListView(
                // Important: Remove any padding from the ListView.
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).padding.top + 65,
                    child: DrawerHeader(
                        child: Text(
                      'taskDetail'.tr,
                      style: Theme.of(context).textTheme.titleLarge,
                    )),
                  ),
                  ListTile(
                      title: Text('taskName'.tr),
                      subtitle: buildTooltipSubtitle(selectTask.value?.name)),
                  ListTile(
                    title: Text('taskUrl'.tr),
                    subtitle:
                        buildTooltipSubtitle(selectTask.value?.meta.req.url),
                    trailing: CopyButton(selectTask.value?.meta.req.url),
                  ),
                  ListTile(
                    title: Text('downloadPath'.tr),
                    subtitle:
                        buildTooltipSubtitle(selectTask.value?.explorerUrl),
                    trailing: IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: () {
                        selectTask.value?.explorer();
                      },
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }

  Widget buildTooltipSubtitle(String? text) {
    final showText = text ?? "";
    return Tooltip(
      message: showText,
      child: Text(
        showText,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

extension TaskEnhance on Task {
  bool get isFolder {
    return meta.res?.name.isNotEmpty ?? false;
  }

  String get explorerUrl {
    return path.join(Util.safeDir(meta.opts.path), Util.safeDir(name));
  }

  Future<void> explorer() async {
    if (Util.isDesktop()) {
      await FileExplorer.openAndSelectFile(explorerUrl);
    } else {
      Get.rootDelegate.toNamed(Routes.TASK_FILES, parameters: {'id': id});
    }
  }

  Future<void> open() async {
    if (status != Status.done) {
      return;
    }

    if (isFolder) {
      await explorer();
    } else {
      await OpenFilex.open(explorerUrl);
    }
  }
}
