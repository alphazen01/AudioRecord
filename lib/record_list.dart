import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'tracker_page.dart';

class RecordListPage extends StatefulWidget {
  const RecordListPage({super.key});

  @override
  State<RecordListPage> createState() => _RecordListPageState();
}

class _RecordListPageState extends State<RecordListPage> {
  late AudioPlayer audioPlayer;
  List<String> recordings = [];
  String? currentPlayingPath;
  bool isPlaying = false;
  List<String> selectedRecordings = [];
  bool isInSelectionMode = false;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _loadRecordings();

    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = (state == PlayerState.playing);
      });
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    setState(() {
      recordings = files
          .where((file) => file.path.endsWith('.m4a'))
          .map((file) => file.path)
          .toList();
    });
  }

  Future<void> _playRecording(String path) async {
    setState(() {
      currentPlayingPath = path;
    });
    await audioPlayer.play(UrlSource(path));
  }

  Future<void> _pausePlayback() async {
    await audioPlayer.pause();
  }

  Future<void> _stopPlayback() async {
    await audioPlayer.stop();
    setState(() {
      currentPlayingPath = null;
    });
  }

  Future<void> _deleteRecordings(List<String> paths) async {
    for (String path in paths) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    setState(() {
      _loadRecordings();
      selectedRecordings.clear();
      isInSelectionMode = false;
    });
  }

  void _toggleSelection(String path) {
    setState(() {
      if (selectedRecordings.contains(path)) {
        selectedRecordings.remove(path);
      } else {
        selectedRecordings.add(path);
      }
    });
  }

  Future<void> _renameRecording(String oldPath) async {
    final newNameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rename Recording'),
          content: TextField(
            controller: newNameController,
            decoration:
                InputDecoration(hintText: 'New name (without extension)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, newNameController.text),
              child: Text('Rename'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/$result.m4a';
      final file = File(oldPath);

      if (await file.exists()) {
        await file.rename(newPath);
        _loadRecordings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isInSelectionMode
            ? "${selectedRecordings.length} selected"
            : "Recordings"),
        actions: isInSelectionMode
            ? [
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteRecordings(selectedRecordings),
                ),
                IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      isInSelectionMode = false;
                      selectedRecordings.clear();
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    if (selectedRecordings.isNotEmpty) {
                      _deleteRecordings(selectedRecordings);
                    }
                  },
                ),
              ],
      ),
      body: ListView.builder(
        itemCount: recordings.length,
        itemBuilder: (context, index) {
          final path = recordings[index];
          final fileName = path.split('/').last;
          final isSelected = selectedRecordings.contains(path);

          return ListTile(
            title: Text(fileName),
            trailing: currentPlayingPath == path
                ? isPlaying
                    ? IconButton(
                        icon: Icon(Icons.pause),
                        onPressed: _pausePlayback,
                      )
                    : IconButton(
                        icon: Icon(Icons.play_arrow),
                        onPressed: () => _playRecording(path),
                      )
                : IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () => _playRecording(path),
                  ),
            leading: isInSelectionMode
                ? IconButton(
                    icon: Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: isSelected ? Colors.blue : null,
                    ),
                    onPressed: () => _toggleSelection(path),
                  )
                : IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _renameRecording(path),
                  ),
            onTap: () {
              if (isInSelectionMode) {
                _toggleSelection(path);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrackerPage(audioPath: path),
                  ),
                );
              }
            },
            onLongPress: () {
              setState(() {
                isInSelectionMode = true;
                _toggleSelection(path);
              });
            },
          );
        },
      ),
    );
  }
}
