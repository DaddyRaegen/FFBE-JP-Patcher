// main.dart

import 'package:ffbe_patcher/constants/strings.dart';
import 'package:ffbe_patcher/models/Data.dart';
import 'package:ffbe_patcher/screens/backup_screen.dart';
import 'package:ffbe_patcher/services/download.dart';
import 'package:ffbe_patcher/services/network.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Data data = Data();
  String? path;
  String? otherPath;
  Map<String, double> downloadProgress = {};

  bool isDownloading = false;
  String progressMessage = '';
  double progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    Data updatedData = await fetchData();
    String? updatedPath = await findGameFolder();
    String? otherUpdatedPath = await findCpkFolder("FF_EXVIUS.exe");
    setState(() {
      data = updatedData;
      path = updatedPath;
      otherPath = otherUpdatedPath;
    });
  }

  downloadFile({
    required String baseUrl,
    required List<String> files,
    List<String>? otherFiles,
    required String eventName,
  }) {
    setState(() {
      isDownloading = true;
      progressMessage = 'Starting download...';
      progressValue = 0.0;
    });

    downloadAndReplaceFilesWithProgress(
      baseUrl: baseUrl,
      fileNames: files,
      targetDirectory: path!,
      otherFileNames: otherFiles,
      otherTargetDirectory: otherPath,
      onProgressUpdate: (progress) {
        setState(() {
          progressValue = progress;
        });
      },
      onMessageUpdate: (message) {
        setState(() {
          progressMessage = message;
        });
      },
    ).then((_) {
      setState(() {
        isDownloading = false;
        progressMessage = '';
        progressValue = 0.0;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Done'),
          content: const Text('Patching complete!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  checkForUpdate(int version, String updateUrl) {
    if (version > appVersion) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Update Available'),
            content:
                const Text('There\'s a new version of FFBE Patcher available.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ignore'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  downloadAndUpdate(updateUrl);
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Update Required'),
            content: const Text(
                'Awesome, you\'re on the latest version. Thanks for checking in!'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "FFBE Patcher",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 67, 2, 92),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BackupScreen()),
              );
            },
            icon: const Icon(Icons.backup),
            tooltip: "Backups",
          ),
          IconButton(
            onPressed: () {
              getData();
            },
            icon: const Icon(Icons.move_to_inbox),
            tooltip: "Refresh Data",
          ),
          IconButton(
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: "FFBE Patcher",
                applicationLegalese:
                    "FFBE Patcher, a software to patch the Japanese PC version of FFBE on PC.\nCreated by Daddy Raegen.",
              );
            },
            icon: const Icon(Icons.info),
            tooltip: "App Info",
          ),
          IconButton(
            onPressed: () {
              checkForUpdate(data.version!, data.updateUrl!);
            },
            icon: const Icon(Icons.update),
            tooltip: "Check For Update",
          ),
          const SizedBox(width: 10)
        ],
      ),
      body: Stack(
        children: [
          data.events == null
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(10),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2,
                      ),
                      itemCount: data.events!.length,
                      itemBuilder: (context, index) {
                        final event = data.events![index];
                        final progress = downloadProgress[event.name] ?? 0.0;
                        return GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Confirm Patch'),
                              content:
                                  Text('Do you want to patch ${event.name}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    downloadFile(
                                      baseUrl: event.url!,
                                      otherFiles: event.payloadFiles,
                                      files: event.files!,
                                      eventName: event.name!,
                                    );
                                  },
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          ),
                          child: Container(
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              color: Colors.black,
                              child: Column(
                                children: [
                                  const SizedBox(height: 15),
                                  Image.network("${event.url}${event.banner}"),
                                  Text(
                                    event.name!,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                  if (progress > 0)
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      margin: const EdgeInsets.all(5),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 5,
                                        backgroundColor: Colors.grey,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                Colors.purple),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
          // Modal for progress
          if (isDownloading)
            PopScope(
              canPop: false, // Prevent back button
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: SizedBox(
                      width: 1000,
                      child: AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              value: progressValue > 0 ? progressValue : null,
                            ),
                            const SizedBox(height: 20),
                            Text(progressMessage),
                          ],
                        ),
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
