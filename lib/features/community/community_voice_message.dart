import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class CommunityVoiceMessage extends StatefulWidget {
  const CommunityVoiceMessage({super.key, required this.url, required this.mine});
  final String url;
  final bool mine;
  @override
  State<CommunityVoiceMessage> createState() => _CommunityVoiceMessageState();
}

class _CommunityVoiceMessageState extends State<CommunityVoiceMessage> {
  late final AudioPlayer _player;
  bool _ready = false;
  bool _playing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _playing = state.playing);
    });
    _player.setUrl(widget.url).then((_) {
      if (mounted) setState(() => _ready = true);
    }).catchError((_) {
      if (mounted) setState(() => _error = 'پخش این پیام صوتی ممکن نیست.');
    });
  }

  @override
  void didUpdateWidget(covariant CommunityVoiceMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _ready = false;
      _player.setUrl(widget.url).then((_) { if (mounted) setState(() => _ready = true); });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _time(Duration d) => '${d.inMinutes.toString().padLeft(2,'0')}:${(d.inSeconds%60).toString().padLeft(2,'0')}';

  @override
  Widget build(BuildContext context) {
    final color = widget.mine ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return SizedBox(width: 230, child: Row(children: [
      IconButton(
        onPressed: !_ready ? null : () async {
          if (_playing) {
            await _player.pause();
          } else {
            if (_player.processingState == ProcessingState.completed) await _player.seek(Duration.zero);
            await _player.play();
          }
        },
        icon: Icon(_playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
          color: widget.mine ? const Color(0xFFBFA9FF) : Theme.of(context).colorScheme.secondary, size: 36),
      ),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_error ?? (_ready ? 'پیام صوتی' : 'در حال آماده‌سازی…'),
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (_, snap) {
            final duration = _player.duration ?? Duration.zero;
            final pos = snap.data ?? Duration.zero;
            final max = duration.inMilliseconds.toDouble().clamp(1, double.infinity);
            return Column(children: [
              Slider(
                value: pos.inMilliseconds.toDouble().clamp(0, max), max: max,
                onChanged: _ready ? (v) => _player.seek(Duration(milliseconds: v.toInt())) : null,
                activeColor: const Color(0xFF9E83FF),
                inactiveColor: color.withValues(alpha: .18),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_time(pos), style: TextStyle(color: color.withValues(alpha: .7), fontSize: 9)),
                Text(_time(duration), style: TextStyle(color: color.withValues(alpha: .7), fontSize: 9)),
              ]),
            ]);
          },
        ),
      ])),
    ]));
  }
}
