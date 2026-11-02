import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/theme/melo_theme.dart';
import '../models/track.dart';
import '../services/artwork_service.dart';

class SongArtwork extends StatefulWidget {
  final Track track;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final bool showShadow;
  final Widget? fallbackPlaceholder;

  const SongArtwork({
    super.key,
    required this.track,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.showShadow = false,
    this.fallbackPlaceholder,
  });

  @override
  State<SongArtwork> createState() => _SongArtworkState();
}

class _SongArtworkState extends State<SongArtwork> {
  final ArtworkService _artworkService = ArtworkService();
  Uint8List? _embeddedBytes;
  String? _onlineUrl;

  @override
  void initState() {
    super.initState();
    _artworkService.addListener(_onArtworkUpdated);
    _loadArtwork();
  }

  @override
  void didUpdateWidget(covariant SongArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id || oldWidget.track.uri != widget.track.uri) {
      _loadArtwork();
    }
  }

  @override
  void dispose() {
    _artworkService.removeListener(_onArtworkUpdated);
    super.dispose();
  }

  void _onArtworkUpdated() {
    if (!mounted) return;
    final cachedBytes = _artworkService.getCachedEmbeddedArt(widget.track.id);
    final cachedUrl = _artworkService.getCachedOnlineUrl(widget.track);
    if (cachedBytes != _embeddedBytes || cachedUrl != _onlineUrl) {
      setState(() {
        _embeddedBytes = cachedBytes;
        _onlineUrl = cachedUrl;
      });
    }
  }

  Future<void> _loadArtwork() async {
    // 1. Check local embedded artwork
    final embedded = await _artworkService.getEmbeddedArt(widget.track);
    if (!mounted) return;

    if (embedded != null) {
      setState(() {
        _embeddedBytes = embedded;
      });
      return;
    }

    // 2. Check cached online URL
    final cachedUrl = _artworkService.getCachedOnlineUrl(widget.track);
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      setState(() {
        _onlineUrl = cachedUrl;
      });
      return;
    }

    // 3. Attempt to fetch online if no thumbnail found
    final fetchedUrl = await _artworkService.fetchOnlineArtwork(widget.track);
    if (!mounted) return;

    setState(() {
      _onlineUrl = fetchedUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final dominant = Color((widget.track.id.hashCode & 0x00FFFFFF) | 0xFF000000);

    Widget imageContent;

    if (_embeddedBytes != null && _embeddedBytes!.isNotEmpty) {
      imageContent = Image.memory(
        _embeddedBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _buildFallback(dominant),
      );
    } else if (_onlineUrl != null && _onlineUrl!.isNotEmpty) {
      imageContent = Image.network(
        _onlineUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildFallback(dominant),
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ),
            ],
          );
        },
        errorBuilder: (_, _, _) => _buildFallback(dominant),
      );
    } else {
      imageContent = _buildFallback(dominant);
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: widget.showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 14),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: imageContent,
      ),
    );
  }

  Widget _buildFallback(Color dominant) {
    if (widget.fallbackPlaceholder != null) return widget.fallbackPlaceholder!;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [dominant, MeloColors.tealDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.album_rounded,
          size: (widget.width != null) ? (widget.width! * 0.38).clamp(24.0, 96.0) : 48,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}
