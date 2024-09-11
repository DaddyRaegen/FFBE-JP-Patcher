import 'package:ffbe_patcher/constants/strings.dart';
import 'package:ffbe_patcher/models/Data.dart';
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
  Map<String, double> downloadProgress = {};

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    Data updatedData = await fetchData();
    String? updatedPath = await findGameFolder();
    setState(() {
      data = updatedData;
      path = updatedPath;
    });
  }

  downloadFile(String baseUrl, List<String>? files, String eventName) {
    downloadAndReplaceFilesWithProgress(
      baseUrl,
      files!,
      path!,
      (progress) {
        setState(() {
          downloadProgress[eventName] = progress;
        });
      },
    );
  }

  checkForUpdate(int version, String updateUrl) {
    if(version > appVersion){
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Update Available'),
            content: const Text('There\'s a new version of FFBE Patcher available.'),
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
    }
    else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Update Required'),
            content: const Text('Awesome, you\'re on the latest version. Thanks for checking in!'),
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
        title: const Text("FFBE Patcher", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: (){
              showAboutDialog(
                context: context,
                applicationName: "FFBE Patcher",
                applicationLegalese: "FFBE Patcher, a software to patch the Japanese PC version of FFBE on PC.\nCreated by Daddy Raegen."
              );
            }, 
            icon: const Icon(Icons.info),
          ),
          IconButton(
            onPressed: (){
              checkForUpdate(data.version!, data.updateUrl!);
            },
            icon: const Icon(Icons.update),
          ),
          const SizedBox(width: 10)
        ],
      ),
      body: data.events == null ? 
        const Center(child: CircularProgressIndicator()) :
        Center(
          child: 
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2
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
                          content: Text('Do you want to patch ${data.events![index].name}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                downloadFile("${data.events![index].url}", data.events![index].files, data.events![index].name!);
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
                              const SizedBox(height: 15,),
                              Image.network("${data.events![index].url}${data.events![index].banner}"),
                              Text("${data.events![index].name}", style: const TextStyle(color: Colors.white, fontSize: 16),),
                              if (progress > 0 ) 
                              Container(
                                padding: const EdgeInsets.all(5),
                                margin: const EdgeInsets.all(5),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: Colors.grey,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
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
    );
  }
}