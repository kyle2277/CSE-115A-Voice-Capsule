import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'utils.dart';

// todo remove hardcoding of file path
const double FIVE_SECONDS_IN_MILLIS = 5000;

class SimplePlayback extends StatefulWidget {
  //const SimplePlayback({Key? key}) : super(key: key);
  SimplePlayback({
    required this.audioFileUrl,
  });
  String audioFileUrl;
  @override
  _SimplePlaybackState createState() => _SimplePlaybackState();
}

class _SimplePlaybackState extends State<SimplePlayback> {

  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;
  // Player time indicator
  int time = 0;
  // Length of recording
  int duration = 0;
  StreamSubscription? _playerSubscription;

  @override
  void initState() {
    print("RUNNING INIT");
    super.initState();
    _mPlayer!.openAudioSession().then((value) {
      _playerSubscription = _mPlayer!.onProgress!.listen((e) {
        setState (() {
          setTime(e.position.inMilliseconds);
          duration = e.duration.inMilliseconds;
        });
      });
      _mPlayer!.setSubscriptionDuration(const Duration(milliseconds:100));
      setState(() async {
        _mPlayer!.setVolume(1.0);
        // Somewhat of a hack to get duration from player subscription
        startPlayer();
        await stopPlayer().then((value) {
          _mPlayerIsInited = true;
          print("PLAYER IS INITED");
        });
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
  Future<void> startPlayer() async {
    if (time == duration) {
      await seek(0);
    }
    await _mPlayer!.startPlayer(
        fromURI: widget.audioFileUrl,
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

  // Seek to given point in milliseconds
  Future<void> seek(double d) async {
    bool wasPlaying = _mPlayer!.isPlaying;
    if(!_mPlayer!.isStopped) {
      await stopPlayer();
    }
    int seekTo = d.floor();
    if(seekTo > duration) {
      seekTo = duration;
    }
    await setTime(seekTo);
    _mPlayer!.seekToPlayer(Duration(milliseconds: seekTo)).then((value) {
      if (time != duration && wasPlaying) {
        startPlayer();
      }
    });
  }

  // --------------------- UI -------------------

  void Function()? getPlaybackFn() {
    if(!_mPlayerIsInited) {
      return null;
    }
    if(_mPlayer!.isStopped) {
      return () {
        startPlayer().then((value) => setState (() {}));
      };
    } else if (_mPlayer!.isPaused) {
      return () {
        resumePlayer().then((value) => setState(() {}));
      };
    } else if (_mPlayer!.isPlaying) {
      return () {
        pausePlayer().then((value) => setState(() {}));
      };
    }
  }

  // Sets position of track playback
  Future<void> setTime(int d) async {
    if (d > duration) {
      d = duration;
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

  Icon getPlayIcon() {
    if (!_mPlayerIsInited) {
      return Icon(Icons.play_arrow);
    } else if (_mPlayer!.isPlaying) {
      return Icon(Icons.pause);
    } else {
      return Icon(Icons.play_arrow);
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
              tooltip: 'Restart',
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
                seek(time - FIVE_SECONDS_IN_MILLIS);
              }
            ),
            IconButton(
              splashRadius: 40,
              iconSize: 80.0,
              color: Colors.grey,
              icon: getPlayIcon(),
              tooltip: _mPlayer!.isPlaying ? 'Tap to pause' : 'Tap to play',
              onPressed: getPlaybackFn(),
            ),
            IconButton(
              splashRadius: 20,
              color: Colors.grey,
              icon: Icon(Icons.forward_5),
              tooltip: 'Go forward 5 seconds',
              onPressed: () {
                seek(time + FIVE_SECONDS_IN_MILLIS);
              }
            ),
            IconButton(
              splashRadius: 20,
              color:Colors.grey,
              icon: Icon(Icons.stop),
              tooltip: 'Stop',
              onPressed: () {
                stopPlayer().then((value) => setState(() {
                  seek(0);
                }));
              }
            ),
          ]
        ),
        Text(
          '${millisToTimestamp(time)} / ${millisToTimestamp(duration)}',
          textScaleFactor: 1.25,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          activeColor: Colors.purple,
          value: time + 0.0,
          min: 0.0,
          max: duration + 0.0,
          onChanged: seek,
        ),
      ],
    );
  }
}