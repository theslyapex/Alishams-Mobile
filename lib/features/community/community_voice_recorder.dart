import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class CommunityVoiceRecorder extends StatefulWidget {
  const CommunityVoiceRecorder({super.key});
  @override
  State<CommunityVoiceRecorder> createState() => _CommunityVoiceRecorderState();
}

class _CommunityVoiceRecorderState extends State<CommunityVoiceRecorder> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  Timer? _ticker;
  String? _path;
  Duration _elapsed = Duration.zero;
  bool _recording = false;
  bool _paused = false;
  bool _review = false;
  bool _playing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((s) {
      if (mounted) setState(() => _playing = s.playing);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      _toast('دسترسی میکروفون فعال نیست.');
      return;
    }
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/alishams-voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(
      encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100,
      numChannels: 1, echoCancel: true, noiseSuppress: true, autoGain: true,
    ), path: _path!);
    _elapsed = Duration.zero;
    _recording = true;
    _paused = false;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recording && !_paused && mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    if (mounted) setState(() {});
  }

  Future<void> _pauseResume() async {
    if (_paused) {
      await _recorder.resume();
    } else {
      await _recorder.pause();
    }
    if (mounted) setState(() => _paused = !_paused);
  }

  Future<void> _stop() async {
    await _recorder.stop();
    _ticker?.cancel();
    if (mounted) setState(() { _recording = false; _paused = false; _review = true; });
    if (_path != null) await _player.setFilePath(_path!);
  }

  Future<void> _rerecord() async {
    await _player.stop();
    if (_path != null) {
      final old = File(_path!);
      if (await old.exists()) await old.delete();
    }
    setState(() { _review = false; _elapsed = Duration.zero; _path = null; });
    await _start();
  }

  Future<void> _send() async {
    if (_path == null || _elapsed.inSeconds < 1) return;
    setState(() => _busy = true);
    await _player.stop();
    if (mounted) Navigator.pop(context, File(_path!));
  }

  void _toast(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: AlertDialog(
      backgroundColor: const Color(0xFF171D2D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(children: [
        Icon(Icons.graphic_eq_rounded, color: Color(0xFFBCA7FF)),
        SizedBox(width: 10),
        Text('پیام صوتی', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ]),
      content: SizedBox(width: 330, child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF222C43), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF8B72E8).withValues(alpha: .35)),
            ),
            child: Column(children: [
              Icon(_review ? Icons.headphones_rounded : (_paused ? Icons.pause_circle_filled_rounded : Icons.mic_rounded),
                color: const Color(0xFFBCA7FF), size: 44),
              const SizedBox(height: 12),
              Text(_format(_elapsed), style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(_review ? 'پیش‌نمایش پیام صوتی' : (_paused ? 'ضبط متوقف شده' : (_recording ? 'در حال ضبط…' : 'آماده ضبط')),
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
              if (_review) ...[
                const SizedBox(height: 14),
                StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (_, snap) {
                    final duration = _player.duration ?? _elapsed;
                    final position = snap.data ?? Duration.zero;
                    final max = duration.inMilliseconds.toDouble().clamp(1.0, double.infinity).toDouble();
                    return Column(children: [
                      Slider(value: position.inMilliseconds.toDouble().clamp(0.0, max).toDouble(), max: max,
                        onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt()))),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(_format(position), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        Text(_format(duration), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ]),
                    ]);
                  },
                ),
                IconButton.filled(
                  onPressed: () async {
                    if (_playing) { await _player.pause(); }
                    else {
                      if (_player.processingState == ProcessingState.completed) await _player.seek(Duration.zero);
                      await _player.play();
                    }
                  },
                  icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 14),
          if (!_review && !_recording)
            FilledButton.icon(onPressed: _start, icon: const Icon(Icons.mic_rounded), label: const Text('شروع ضبط')),
          if (_recording)
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _pauseResume,
                icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                label: Text(_paused ? 'ادامه ضبط' : 'توقف موقت'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _stop,
                icon: const Icon(Icons.stop_rounded), label: const Text('پایان ضبط'))),
            ]),
          if (_review)
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _rerecord,
                icon: const Icon(Icons.refresh_rounded), label: const Text('ضبط دوباره'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: _busy ? null : _send,
                icon: const Icon(Icons.send_rounded), label: const Text('تأیید و ارسال'))),
            ]),
        ],
      )),
      actions: [TextButton(onPressed: () async {
        await _recorder.cancel();
        if (context.mounted) Navigator.pop(context);
      }, child: const Text('انصراف'))],
    ),
  );
}
