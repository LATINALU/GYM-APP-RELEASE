/// Selector por plataforma del servicio de media de ejercicios:
/// dart:io (móvil/desktop) descarga y persiste GIFs; web usa un no-op
/// y sirve los GIFs por red con el caché del navegador.
export 'exercise_media_factory_io.dart'
    if (dart.library.js_interop) 'exercise_media_factory_web.dart';
