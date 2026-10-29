import 'dart:async';
import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration scrollDuration;
  final Duration pauseDuration;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.scrollDuration = const Duration(seconds: 5),
    this.pauseDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _animateScroll();
      }
    });
  }

  void _animateScroll() async {
    while (!_isDisposed && mounted) {
      await Future.delayed(widget.pauseDuration);
      if (_isDisposed || !mounted || !_scrollController.hasClients) break;

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        // İleriye doğru kaydır
        await _scrollController.animateTo(
          maxScroll,
          duration: widget.scrollDuration,
          curve: Curves.linear,
        );

        await Future.delayed(widget.pauseDuration);
        if (_isDisposed || !mounted || !_scrollController.hasClients) break;

        // Başlangıç pozisyonuna geri dön
        await _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      } else {
        // Eğer metin sığıyorsa 2 saniye bekle tekrar kontrol et
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}
