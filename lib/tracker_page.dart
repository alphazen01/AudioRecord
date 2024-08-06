import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class TrackerPage extends StatefulWidget {
  final String audioPath;

  const TrackerPage({super.key, required this.audioPath});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  late AudioPlayer audioPlayer;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();

    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = (state == PlayerState.playing);
      });
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
    super.dispose();
  }

  Future<void> _playRecording() async {
    await audioPlayer.play(UrlSource(widget.audioPath));
  }

  Future<void> _pausePlayback() async {
    await audioPlayer.pause();
  }

  Future<void> _stopPlayback() async {
    await audioPlayer.stop();
  }

  Future<void> _seekTo(Duration newPosition) async {
    await audioPlayer.seek(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Playback"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Playing ${widget.audioPath.split('/').last}"),
            SizedBox(height: 20),
            if (isPlaying)
              ElevatedButton(
                onPressed: _pausePlayback,
                child: Text("Pause"),
              )
            else
              ElevatedButton(
                onPressed: _playRecording,
                child: Text("Play"),
              ),
            ElevatedButton(
              onPressed: _stopPlayback,
              child: Text("Stop"),
            ),
            SizedBox(height: 20),
            Slider(
              min: 0.0,
              max: duration.inSeconds.toDouble(),
              value: position.inSeconds.toDouble(),
              onChanged: (value) {
                final newPosition = Duration(seconds: value.toInt());
                _seekTo(newPosition);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(position)),
                Text(formatDuration(duration)),
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
