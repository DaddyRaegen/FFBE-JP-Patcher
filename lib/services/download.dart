import 'dart:io';
import 'dart:convert'; // Import for JSON decoding
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

Future<void> downloadAndReplaceFilesWithProgress({
  required String baseUrl,
  required List<String> fileNames,
  List<String>? otherFileNames,
  required String targetDirectory,
  String? otherTargetDirectory,
  required Function(double) onProgressUpdate,
  required Function(String) onMessageUpdate,
}) async {
  Dio dio = Dio();

  // Function to download and replace files
  Future<void> downloadAndReplaceFile(
      String fileName, String destinationPath) async {
    String fileUrl = '$baseUrl/$fileName';
    String tempDir = Directory.systemTemp.path;
    String savePath = path.join(tempDir, fileName);
    String backupPath = path.join(tempDir, 'backup_$fileName');

    try {
      // Check if file already exists in the target directory
      File targetFile = File(destinationPath);

      if (await targetFile.exists()) {
        // Backup the existing file
        onMessageUpdate('Backing up $fileName...');
        await targetFile.copy(backupPath);
        print("Existing file $fileName backed up to $backupPath.");
      }

      // Start downloading the file
      onMessageUpdate('Downloading $fileName...');
      await dio.download(
        fileUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            onProgressUpdate(progress);
          }
        },
      );

      print("Download of $fileName complete!");

      // Replace the old file with the new one
      onMessageUpdate('Replacing $fileName...');
      File downloadedFile = File(savePath);
      await downloadedFile.rename(destinationPath);
      print("File $fileName moved to: $destinationPath.");
    } catch (e) {
      print("Error downloading or replacing $fileName: $e");
    }
    onProgressUpdate(0);
  }

  // Download and replace main files
  for (String fileName in fileNames) {
    await downloadAndReplaceFile(
        fileName, path.join(targetDirectory, fileName));
  }

  // Download and replace other files if any
  if (otherFileNames != null && otherTargetDirectory != null) {
    for (String fileName in otherFileNames) {
      await downloadAndReplaceFile(
          fileName, path.join(otherTargetDirectory, fileName));
    }
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

Future<String?> findCpkFolder(String gameName) async {
  // Get the user's AppData\Roaming directory
  final appDataPath = Directory(Platform.environment['APPDATA'] ?? '');
  if (!appDataPath.existsSync()) {
    print('AppData directory does not exist');
    return null;
  }

  // Define the base path: AndApp\Apps
  final appsPath = path.join(appDataPath.path, 'AndApp', 'Apps');
  final appsDir = Directory(appsPath);

  if (!appsDir.existsSync()) {
    print('Apps directory does not exist');
    return null;
  }

  // Traverse through all subdirectories in Apps (numbered folders)
  final appDirectories = appsDir.listSync().whereType<Directory>();

  for (var dir in appDirectories) {
    // Check if Payload\manifest.json exists
    final payloadDir = Directory(path.join(dir.path, 'Payload'));
    final manifestFile = File(path.join(payloadDir.path, 'manifest.json'));

    if (await manifestFile.exists()) {
      // Read manifest.json
      try {
        final manifestContent = await manifestFile.readAsString();
        final manifestJson = json.decode(manifestContent);

        if (manifestJson['entryPointBaseName'] == gameName) {
          // Found the game folder
          final cpkDir = Directory(path.join(payloadDir.path, 'cpk'));

          if (await cpkDir.exists()) {
            print("cpk folder found: ${cpkDir.path}");
            return cpkDir.path;
          } else {
            print("cpk folder does not exist in ${payloadDir.path}");
            return null;
          }
        }
      } catch (e) {
        print("Error reading manifest.json in ${payloadDir.path}: $e");
      }
    }
  }
  print("Game folder not found.");
  return null;
}

Future<void> downloadAndUpdate(String url) async {
  var tempDir = Directory.systemTemp;
  var filePath = path.join(tempDir.path, 'FFBE_Patcher_Update.exe');

  try {
    Response response = await Dio().download(url, filePath);
    if (response.statusCode == 200) {
      await Process.start('cmd.exe', ['/c', filePath]);
      exit(0);
    }
  } catch (e) {
    print('Error updating: $e');
  }
}
