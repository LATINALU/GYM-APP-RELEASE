/// Selector por plataforma para mostrar un GIF desde archivo local
/// (Image.file no existe en web).
export 'local_gif_image_io.dart'
    if (dart.library.js_interop) 'local_gif_image_web.dart';
