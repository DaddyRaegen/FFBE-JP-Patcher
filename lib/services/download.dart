import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher_string.dart';

void downloadAndReplaceFilesWithProgress(
  String baseUrl,
  List<String> fileNames,
  String targetDirectory,
  Function(double) onProgressUpdate,
) async {
  Dio dio = Dio();

  for (String fileName in fileNames) {
    String fileUrl = '$baseUrl/$fileName';
    String savePath = path.join(Directory.systemTemp.path, fileName);
    String destinationPath = path.join(targetDirectory, fileName);

    try {
      // Start downloading the file
      Response response = await dio.download(fileUrl, savePath,
          onReceiveProgress: (received, total) {
        if (total != -1) {
          double progress = received / total;
          onProgressUpdate(progress);
        }
      });

      if (response.statusCode == 200) {
        print("Download of $fileName complete!");

        // Check if file already exists in the target directory
        File targetFile = File(destinationPath);

        if (await targetFile.exists()) {
          // If file exists, delete it first
          await targetFile.delete();
          print("Existing file $fileName deleted.");
        }

        // Move the newly downloaded file to the target directory
        File downloadedFile = File(savePath);
        await downloadedFile.rename(destinationPath);
        print("File $fileName moved to: $destinationPath");
      }
    } catch (e) {
      print("Error downloading or replacing $fileName: $e");
    }
    onProgressUpdate(0);
  }
}

Future<String?> findGameFolder() async {
  // Get the user's AppData directory
  final appDataPath = Directory(Platform.environment['APPDATA'] ?? '');
  if (!appDataPath.existsSync()) {
    print('AppData directory does not exist');
    return null;
  }

  // Define the base path: AndApp/GameData
  final gameDataPath = path.join(appDataPath.path, 'AndApp', 'GameData');
  final gameDataDir = Directory(gameDataPath);

  if (!gameDataDir.existsSync()) {
    print('GameData directory does not exist');
    return null;
  }

  // Traverse through all subdirectories in GameData (first level of random numbers)
  final gameDirectories = gameDataDir.listSync().whereType<Directory>();

  for (var dir in gameDirectories) {
    // Traverse through the second level of random number directories
    final subDirectories = dir.listSync().whereType<Directory>();

    for (var subDir in subDirectories) {
      // Check if the "public" folder exists
      final publicDir = Directory(path.join(subDir.path, 'public'));

      if (publicDir.existsSync()) {
        // Check if "units1.cpk" exists inside the "public" folder
        final unitsCpkFile = File(path.join(publicDir.path, 'unit1.cpk'));
        if (await unitsCpkFile.exists()) {
          // Return the path to the "public" folder if "units1.cpk" is found
          print("Game folder found: ${publicDir.path}");
          return publicDir.path;
        }
      }
    }
  }
  print("Game folder not found.");
  return null;
}

  Future<void> downloadAndUpdate(String url) async {
    var tempDir = Directory.systemTemp;
    var filePath = '${tempDir.path}/FFBE_Patcher_Update.exe';

    try {
      Response response = await Dio().download(url, filePath);
      if (response.statusCode == 200) {
        if (await canLaunchUrlString(filePath)) {
          await launchUrlString(filePath);
          exit(0);
        } else {
          throw 'Could not launch $filePath';
        }
      } else {
        throw 'Failed to download file';
      }
    } catch (e) {
      print('Error updating: $e');
    }
  }