import 'package:audio_record/record_list.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
// Import the new page

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late Record audioRecord;
  late AudioPlayer audioPlayer;
  bool isRecording = false;
  bool isRecordingSaved = false;
  String audioPath = "";
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioRecord = Record();

    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {});
    });

    audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });

    audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    audioRecord.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        audioPath =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await audioRecord.start(path: audioPath);
        setState(() {
          isRecording = true;
          isRecordingSaved = false; // Reset saved status
        });
        print("Recording started and will be saved to $audioPath");
      }
    } catch (e) {
      print("Error start recording: $e");
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      if (path != null) {
        setState(() {
          isRecording = false;
          audioPath = path;
        });
        print("Recording stopped and saved at $audioPath");
      }
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  Future<void> saveRecording() async {
    if (audioPath.isNotEmpty) {
      setState(() {
        isRecordingSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Recording saved successfully at $audioPath")),
      );
      // Navigate to the RecordListPage after saving
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RecordListPage()),
      );
    }
  }

  Future<void> playRecording() async {
    if (audioPath.isEmpty) {
      print("No recording found");
      return;
    }

    try {
      await audioPlayer.play(UrlSource(audioPath));
    } catch (e) {
      print("Error playing recording: $e");
    }
  }

  Future<void> pauseRecording() async {
    try {
      await audioPlayer.pause();
    } catch (e) {
      print("Error pausing recording: $e");
    }
  }

  Future<void> stopPlayback() async {
    await audioPlayer.stop();
  }

  Future<void> seekTo(Duration duration) async {
    await audioPlayer.seek(duration);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Record Page"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => RecordListPage()));
                },
                child: Text("Record List")),
            if (isRecording) Text("Recording in progress..."),
            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: Text(isRecording ? "Stop Recording" : "Start Recording"),
            ),
            SizedBox(height: 25),
            if (!isRecording && audioPath.isNotEmpty)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (audioPlayer.state == PlayerState.playing) {
                        pauseRecording();
                      } else {
                        playRecording();
                      }
                    },
                    child: Text(audioPlayer.state == PlayerState.playing
                        ? "Pause"
                        : "Play"),
                  ),
                  Slider(
                    min: 0.0,
                    max: duration.inSeconds.toDouble(),
                    value: position.inSeconds.toDouble(),
                    onChanged: (value) async {
                      final newPosition = Duration(seconds: value.toInt());
                      await seekTo(newPosition);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatDuration(position)),
                      Text(formatDuration(duration)),
                    ],
                  ),
                  SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: isRecordingSaved ? null : saveRecording,
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.grey; // Disabled color
                          }
                          return Colors.blue; // Enabled color
                        },
                      ),
                    ),
                    child: Text("Save Recording"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
