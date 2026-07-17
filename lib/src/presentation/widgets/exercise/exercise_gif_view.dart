import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../domain/data/dataset_exercise_catalog.dart';
import '../../../domain/data/exercise_gifs.dart';
import '../../../domain/ports/output/exercise_media_port.dart';

/// Vista unificada de media de un ejercicio, con soporte offline completo.
///
/// Orden de resolución:
/// 1. GIF descargado en almacenamiento local → [Image.file] (sin red)
/// 2. Thumbnail empaquetado en assets (siempre disponible offline)
///    y, si hay red, el GIF remoto encima + descarga persistente en 2º plano
/// 3. Placeholder con ícono
class ExerciseGifView extends StatefulWidget {
  /// URL remota del GIF (p. ej. `Exercise.animationUrl` o `ExerciseTemplate.gifUrl`)
  final String? gifUrl;

  /// ID de plantilla o nombre del ejercicio; se usa para resolver la URL vía
  /// [ExerciseGifs.getGifUrl] cuando [gifUrl] es null (rutinas antiguas)
  final String? exerciseKey;

  /// Ruta de asset del thumbnail; si es null se deriva de la URL del dataset
  final String? thumbAsset;

  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Si es false, muestra solo el thumbnail estático (listas largas);
  /// si es true, intenta mostrar el GIF animado (vista de detalle/workout)
  final bool animated;

  const ExerciseGifView({
    super.key,
    this.gifUrl,
    this.exerciseKey,
    this.thumbAsset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.animated = true,
  });

  @override
  State<ExerciseGifView> createState() => _ExerciseGifViewState();
}

class _ExerciseGifViewState extends State<ExerciseGifView> {
  String? _localGifPath;

  String? get _resolvedGifUrl {
    if (widget.gifUrl != null) return widget.gifUrl;
    final key = widget.exerciseKey;
    return key != null ? ExerciseGifs.getGifUrl(key) : null;
  }

  String? get _resolvedThumbAsset {
    if (widget.thumbAsset != null) return widget.thumbAsset;
    final key = widget.exerciseKey;
    final byKey = key != null ? DatasetExerciseCatalog.thumbAssetPath(key) : null;
    if (byKey != null) return byKey;
    final url = _resolvedGifUrl;
    return url != null
        ? DatasetExerciseCatalog.thumbAssetForRemoteUrl(url)
        : null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.animated) _resolveLocal();
  }

  @override
  void didUpdateWidget(ExerciseGifView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gifUrl != widget.gifUrl ||
        oldWidget.exerciseKey != widget.exerciseKey) {
      _localGifPath = null;
      if (widget.animated) _resolveLocal();
    }
  }

  Future<void> _resolveLocal() async {
    final url = _resolvedGifUrl;
    if (url == null) return;
    if (!GetIt.I.isRegistered<ExerciseMediaPort>()) return;
    final media = GetIt.I<ExerciseMediaPort>();

    // 1. ¿Ya está en disco?
    var path = await media.localPath(url);
    if (path != null) {
      if (mounted) setState(() => _localGifPath = path);
      return;
    }
    // 2. Descargar y persistir (si hay red); mientras tanto se ve el thumbnail
    path = await media.ensureDownloaded(url);
    if (path != null && mounted) setState(() => _localGifPath = path);
  }

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: widget.width,
      height: widget.height,
      child: _buildMedia(),
    );
    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildMedia() {
    // GIF ya descargado: servir desde disco, cero red
    if (widget.animated && _localGifPath != null) {
      return Image.file(
        File(_localGifPath!),
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _thumbnailOrPlaceholder(),
      );
    }

    final thumb = _resolvedThumbAsset;
    final gifUrl = _resolvedGifUrl;

    // Sin GIF local aún: thumbnail del APK al instante; el GIF aparece solo
    // cuando la descarga en 2º plano termina (ver _resolveLocal)
    if (thumb != null) return _thumbnail(thumb);

    // Ejercicio legacy sin thumbnail: GIF por red con caché
    if (widget.animated && gifUrl != null) {
      return CachedNetworkImage(
        imageUrl: gifUrl,
        fit: widget.fit,
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _thumbnail(String asset) {
    return Image.asset(
      asset,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _thumbnailOrPlaceholder() {
    final thumb = _resolvedThumbAsset;
    return thumb != null ? _thumbnail(thumb) : _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF374151),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fitness_center,
        color: Color(0xFF9CA3AF),
        size: 32,
      ),
    );
  }
}
