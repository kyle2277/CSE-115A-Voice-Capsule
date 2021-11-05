import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'utils.dart';

// todo remove hardcoding of file path
const _audioFilePath = 'recorded_file.mp4';

typedef Fn = void Function();

class SimplePlayback extends StatefulWidget {
  @override
  _SimplePlaybackState createState() => _SimplePlaybackState();
}

class _SimplePlaybackState extends State<SimplePlayback> {
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;
  // Player time indicator
  int time = 0;
  // Total length of recording
  int length = 0;
  StreamSubscription? _playerSubscription;

  @override
  void initState() {
    super.initState();
    _mPlayer!.openAudioSession().then((value) {
      _playerSubscription = _mPlayer!.onProgress!.listen((e) {
        setState (() {
          setTime(e.position.inMilliseconds);
          length = e.duration.inMilliseconds;
        });
      });
      _mPlayer!.setSubscriptionDuration(const Duration(milliseconds:100));
      setState(() {
        _mPlayerIsInited = true;
        _mPlayer!.setVolume(100.0);
      });
    });
  }

  void cancelPlayerSubscriptions() {
    if (_playerSubscription != null) {
      _playerSubscription!.cancel();
      _playerSubscription = null;
    }
  }

  @override
  void dispose() {
    stopPlayer();
    // Be careful : you must `close` the audio session when you have finished with it.
    cancelPlayerSubscriptions();
    _mPlayer!.closeAudioSession();
    _mPlayer = null;
    super.dispose();
  }

  // -------  Here is the code to playback a remote file -----------------------

  // Start playback of specified file
  void startPlayer([filePath = _audioFilePath]) async {
    await _mPlayer!.startPlayer(
        fromURI: filePath,
        codec: Codec.aacMP4,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  // Stop playback
  Future<void> stopPlayer() async {
    if (_mPlayer != null) {
      await _mPlayer!.stopPlayer();
    }
  }

  // Pause playback
  Future<void> pausePlayer() async {
    if(_mPlayer != null) {
      await _mPlayer!.pausePlayer();
    }
  }

  // Resume playback
  Future<void> resumePlayer() async {
    if(_mPlayer != null) {
      await _mPlayer!.resumePlayer();
    }
  }

  Future<void> seek(double d) async {
    if(!_mPlayer!.isStopped) {
      await stopPlayer();
    }
    int seekTo = d.floor();
    await setTime(seekTo);
    await _mPlayer!.seekToPlayer(Duration(milliseconds: seekTo));
  }

  // --------------------- UI -------------------

  Fn? getPlaybackFn() {
    if (!_mPlayerIsInited) {
      return null;
    }
    if(_mPlayer!.isStopped) {
      return startPlayer;
    } else if (_mPlayer!.isPaused) {
      return () {
        resumePlayer().then((value) => setState(() {}));
      };
    } else if (_mPlayer!.isPlaying) {
      return () {
        pausePlayer().then((value) => setState(() {}));
      };
    }
    // return _mPlayer!.isStopped
    //     ? startPlayer
    //     : () {
    //   stopPlayer().then((value) => setState(() {}));
    // };
  }

  // Sets position of track playback
  Future<void> setTime(int d) async {
    if (d > length) {
      d = length;
    } else if (d < 0) {
      d = 0;
    }
    setState(() {
      time = d;
    });
  }

  String getPlaybackTextStatus() {
    if(_mPlayer == null) {
      return "";
    } else if (_mPlayer!.isStopped) {
      return "Stopped";
    } else if (_mPlayer!.isPaused) {
      return "Paused";
    } else if (_mPlayer!.isPlaying) {
      return "Playing";
    } else {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column (
      //mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              splashRadius: 20,
              color:Colors.grey,
              icon: Icon(Icons.fast_rewind),
              tooltip: 'Seek to start',
              onPressed: () {
                seek(0);
              },
            ),
            IconButton(
              splashRadius: 20,
              color: Colors.grey,
              icon: Icon(Icons.replay_5),
              tooltip: 'Go back 5 seconds',
              onPressed: () {
                seek(time - 5000);
              }
            ),
            IconButton(
              splashRadius: 40,
              iconSize: 80.0,
              color: Colors.grey,
              icon: _mPlayer!.isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
              tooltip: _mPlayer!.isPlaying ? 'Tap to pause' : 'Tap to play',
              onPressed: getPlaybackFn(),
            ),
            IconButton(
              splashRadius: 20,
              color: Colors.grey,
              icon: Icon(Icons.forward_5),
              tooltip: 'Go forward 5 seconds',
              onPressed: () {
                seek(time + 5000);
              }
            ),
            IconButton(
              splashRadius: 20,
              color:Colors.grey,
              icon: Icon(Icons.stop),
              tooltip: 'Stop',
              onPressed: () {
                stopPlayer().then((value) => setState(() {
                  setTime(0);
                }));
              }
            ),
          ]
        ),
        // Text(
        //   getPlaybackTextStatus(),
        //   textScaleFactor: 1.5,
        //   style: const TextStyle(fontWeight: FontWeight.bold),
        // ),
        Text(
          '${millisToTimestamp(time)} / ${millisToTimestamp(length)}',
          textScaleFactor: 1.25,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: time + 0.0,
          min: 0.0,
          max: length + 0.0,
          onChanged: seek,
        ),
      ],
    );

    // return Column(
    //   children: [
    //     Container(
    //       margin: const EdgeInsets.all(3),
    //       padding: const EdgeInsets.all(3),
    //       height: 80,
    //       width: double.infinity,
    //       alignment: Alignment.center,
    //       decoration: BoxDecoration(
    //         color: Color(0xFFFAF0E6),
    //         border: Border.all(
    //           color: Colors.indigo,
    //           width: 3,
    //         ),
    //       ),
    //       child: Row(children: [
    //         ElevatedButton(
    //           onPressed: getPlaybackFn(),
    //           //color: Colors.white,
    //           //disabledColor: Colors.grey,
    //           child: Text(_mPlayer!.isPlaying ? 'Stop' : 'Play'),
    //         ),
    //         SizedBox(
    //           width: 20,
    //         ),
    //         Text(_mPlayer!.isPlaying
    //             ? 'Playback in progress'
    //             : 'Player is stopped'),
    //       ]),
    //     ),
    //   ],
    // );
  }
}