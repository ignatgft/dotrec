// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'DotRec';

  @override
  String get start => 'Iniciar grabación';

  @override
  String get stop => 'Detener';

  @override
  String get pause => 'Pausa';

  @override
  String get resume => 'Continuar';

  @override
  String get saved => 'Grabación guardada';

  @override
  String get open => 'Abrir';

  @override
  String get share => 'Compartir';

  @override
  String get delete => 'Eliminar';

  @override
  String get err_space => 'Poco espacio. Libera al menos 200 MB';

  @override
  String get err_consent => 'No se inició. Sin acceso a la pantalla';

  @override
  String get err_mic => 'Sin acceso al micrófono. Abre los ajustes';

  @override
  String fps_cap(int n) {
    return 'Tu pantalla admite hasta $n Hz';
  }

  @override
  String get audio_blocked => 'Algunas apps bloquearon la captura de audio';

  @override
  String get empty_lib_title => 'Tus grabaciones aparecerán aquí';

  @override
  String get ready => 'LISTO';

  @override
  String get paused => 'PAUSA';

  @override
  String get saving => 'GUARDANDO';

  @override
  String get settings => 'Ajustes';

  @override
  String get library => 'Grabaciones';

  @override
  String get presetFast => 'Rápido';

  @override
  String get presetBalanced => 'Equilibrio';

  @override
  String get presetQuality => 'Calidad';

  @override
  String get presetCustom => 'Manual';

  @override
  String get begin => 'Empezar';

  @override
  String get presetLabel => 'Preajuste';

  @override
  String get resolutionLabel => 'Resolución';

  @override
  String get micLabel => 'Micrófono';

  @override
  String get sysAudioLabel => 'Audio del sistema';

  @override
  String get videoLabel => 'Vídeo';

  @override
  String bitrateLabel(int n) {
    return 'Bitrate: $n Mbps';
  }

  @override
  String get codecLabel => 'Códec';

  @override
  String get hevcMissing => 'Sin HEVC por hardware';

  @override
  String get audioLabel => 'Audio';

  @override
  String get sysAudioV11 => 'Audio del sistema (v1.1)';

  @override
  String get recordingLabel => 'Grabación';

  @override
  String get countdownLabel => 'Cuenta atrás';

  @override
  String get noneLabel => 'No';

  @override
  String countdownSec(int n) {
    return '$n s';
  }

  @override
  String get appearanceLabel => 'Aspecto';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get langSystem => 'Sistema';

  @override
  String get quickAccess => 'Acceso rápido';

  @override
  String get quickAccessBody =>
      'El mosaico y el widget inician sin abrir la app.';

  @override
  String get addTileBtn => 'Añadir mosaico';

  @override
  String get tileAdded => 'Mosaico añadido';

  @override
  String get tileUnavailable => 'Requiere Android 13+';

  @override
  String get aboutLine => 'DotRec funciona sin conexión.';

  @override
  String get overlayNeedPermission => 'Requiere el permiso «Sobre otras apps».';

  @override
  String get openPermission => 'Abrir permiso';

  @override
  String get errorLabel => 'Error';

  @override
  String get onboardingTitle => 'Graba tu pantalla, sin más';

  @override
  String get ob1 => 'Funciona sin internet';

  @override
  String get ob2 => 'Sin anuncios ni marcas de agua';

  @override
  String get ob3 => 'Archivos en Movies/DotRec';

  @override
  String get guidesTitle => 'Guías y permisos';

  @override
  String get guides => 'Guías';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get guideCaptureTitle => 'Acceso a la pantalla';

  @override
  String get guideCaptureBody =>
      'Al iniciar la grabación, Android muestra un diálogo de acceso a la pantalla. En Android 14+ el permiso se pide en cada grabación: es una limitación del sistema.';

  @override
  String get guideMicTitle => 'Micrófono';

  @override
  String get guideMicBody =>
      '1. Activa el interruptor «Micrófono». 2. Permite el acceso en el diálogo del sistema. 3. Si lo denegaste, abre los ajustes de la app y activa el micrófono manualmente.';

  @override
  String get guideNotifTitle => 'Notificaciones';

  @override
  String get guideNotifBody =>
      'La notificación con temporizador y botones de pausa/detener aparece en la primera grabación. Si no la ves, permite las notificaciones en los ajustes de la app.';

  @override
  String get guideOverlayTitle => 'Ventana flotante';

  @override
  String get guideOverlayBody =>
      'Está desactivada por defecto. 1. Actívala en los ajustes. 2. Permite «Mostrar sobre otras apps» en la pantalla del sistema. No debería aparecer en las grabaciones.';

  @override
  String get guideBatteryTitle => 'Batería y segundo plano';

  @override
  String get guideBatteryBody =>
      'Algunas capas (Xiaomi, Samsung) detienen la grabación en segundo plano para ahorrar batería. Abre los ajustes de batería, busca DotRec y permite la actividad en segundo plano.';

  @override
  String get guideTileTitle => 'Mosaico rápido';

  @override
  String get guideTileBody =>
      '1. Abre los ajustes rápidos y pulsa Editar. 2. Arrastra el mosaico «Grabar» a la zona activa. En Android 13+ usa el botón de abajo.';

  @override
  String get linkTitle => 'Transmitir a PC';

  @override
  String get linkMethod => 'Método';

  @override
  String get linkWifiPin => 'Código de emparejamiento Wi-Fi';

  @override
  String get linkPinHint => 'Ingresar en PC. Válido por 2 minutos';

  @override
  String get linkStreamQuality => 'Calidad de transmisión';

  @override
  String get linkAudioToPc => 'Audio en PC';

  @override
  String get linkBlankScreen => 'Apagar pantalla del teléfono';

  @override
  String get linkParallelRecord => 'Grabar en teléfono en paralelo';

  @override
  String get linkStartStream => 'Iniciar transmisión';

  @override
  String get linkStopStream => 'Detener transmisión';

  @override
  String get linkWaiting => 'Esperando a PC...';

  @override
  String get linkConnected => 'Conectado';
}
