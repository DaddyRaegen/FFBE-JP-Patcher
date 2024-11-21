import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:timeago/timeago.dart' as timeago;

class BackupScreen extends StatefulWidget {
  @override
  _BackupScreenState createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  List<BackupItem> backups = [];

  bool isProcessing = false;
  String progressMessage = '';

  @override
  void initState() {
    super.initState();
    loadBackups();
  }

  void loadBackups() async {
    String backupBasePath =
        path.join(Directory.systemTemp.path, 'ffbe_patcher_backups');
    Directory backupBaseDir = Directory(backupBasePath);

    if (await backupBaseDir.exists()) {
      List<BackupItem> loadedBackups = [];

      List<FileSystemEntity> entities = backupBaseDir.listSync();

      for (FileSystemEntity entity in entities) {
        if (entity is Directory) {
          String folderName = path.basename(entity.path);
          DateTime backupTime =
              await entity.stat().then((stat) => stat.modified);
          loadedBackups.add(BackupItem(
            folderName: folderName,
            folderPath: entity.path,
            backupTime: backupTime,
          ));
        }
      }

      setState(() {
        backups = loadedBackups;
      });
    }
  }

  void openInFileExplorer(String folderPath) async {
    try {
      if (Platform.isWindows) {
        // Windows
        await Process.run('explorer', [folderPath]);
      } else if (Platform.isMacOS) {
        // macOS
        await Process.run('open', [folderPath]);
      } else if (Platform.isLinux) {
        // Linux
        await Process.run('xdg-open', [folderPath]);
      } else {
        throw UnsupportedError('Unsupported platform');
      }
    } catch (e) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to open folder: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void restoreBackup(BackupItem backup) async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: Text('Do you want to restore backup "${backup.folderName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isProcessing = true;
      progressMessage = 'Restoring backup...';
    });

    try {
      // Read the paths.json file
      String jsonFilePath = path.join(backup.folderPath, 'paths.json');
      File jsonFile = File(jsonFilePath);
      if (await jsonFile.exists()) {
        String jsonContent = await jsonFile.readAsString();
        List<dynamic> originalFilePaths = jsonDecode(jsonContent);

        // Restore each file
        for (var item in originalFilePaths) {
          String fileName = item['fileName'];
          String originalPath = item['originalPath'];
          String backupFilePath = path.join(backup.folderPath, fileName);

          File backupFile = File(backupFilePath);
          if (await backupFile.exists()) {
            setState(() {
              progressMessage = 'Restoring $fileName...';
            });
            await backupFile.rename(originalPath);
          }
        }

        // Delete the backup folder
        await Directory(backup.folderPath).delete(recursive: true);

        // Refresh the backup list
        loadBackups();

        setState(() {
          isProcessing = false;
          progressMessage = '';
        });

        // Show completion dialog
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Done'),
            content: const Text('Backup restored successfully.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('paths.json not found in backup folder.');
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
        progressMessage = '';
      });

      // Show error dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to restore backup: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void deleteBackup(BackupItem backup) async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Do you want to delete backup "${backup.folderName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isProcessing = true;
      progressMessage = 'Deleting backup...';
    });

    try {
      // Delete the backup folder
      await Directory(backup.folderPath).delete(recursive: true);

      // Refresh the backup list
      loadBackups();

      setState(() {
        isProcessing = false;
        progressMessage = '';
      });

      // Show completion dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Done'),
          content: const Text('Backup deleted successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        isProcessing = false;
        progressMessage = '';
      });

      // Show error dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to delete backup: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backups'),
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: backups.length,
            itemBuilder: (context, index) {
              BackupItem backup = backups[index];
              String timeAgo = timeago.format(backup.backupTime);

              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(backup.folderName),
                subtitle: Text('Backup created $timeAgo'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: () => openInFileExplorer(backup.folderPath),
                      tooltip: 'Open in File Explorer',
                    ),
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: () => restoreBackup(backup),
                      tooltip: 'Restore Backup',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => deleteBackup(backup),
                      tooltip: 'Delete Backup',
                    ),
                  ],
                ),
              );
            },
          ),
          if (isProcessing)
            PopScope(
              canPop: false,
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(progressMessage),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BackupItem {
  final String folderName;
  final String folderPath;
  final DateTime backupTime;

  BackupItem({
    required this.folderName,
    required this.folderPath,
    required this.backupTime,
  });
}
