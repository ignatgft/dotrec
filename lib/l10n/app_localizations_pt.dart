// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'DotRec';

  @override
  String get start => 'Iniciar gravação';

  @override
  String get stop => 'Parar';

  @override
  String get pause => 'Pausar';

  @override
  String get resume => 'Continuar';

  @override
  String get saved => 'Gravação salva';

  @override
  String get open => 'Abrir';

  @override
  String get share => 'Compartilhar';

  @override
  String get delete => 'Excluir';

  @override
  String get err_space => 'Pouco espaço. Libere pelo menos 200 MB';

  @override
  String get err_consent => 'Não iniciado. Sem acesso à tela';

  @override
  String get err_mic => 'Sem acesso ao microfone. Abra as configurações';

  @override
  String fps_cap(int n) {
    return 'Sua tela suporta até $n Hz';
  }

  @override
  String get audio_blocked => 'Alguns apps bloquearam a captura de áudio';

  @override
  String get empty_lib_title => 'Suas gravações aparecerão aqui';

  @override
  String get ready => 'PRONTO';

  @override
  String get paused => 'PAUSA';

  @override
  String get saving => 'SALVANDO';

  @override
  String get settings => 'Configurações';

  @override
  String get library => 'Gravações';

  @override
  String get presetFast => 'Rápido';

  @override
  String get presetBalanced => 'Equilíbrio';

  @override
  String get presetQuality => 'Qualidade';

  @override
  String get presetCustom => 'Manual';

  @override
  String get begin => 'Começar';

  @override
  String get presetLabel => 'Predefinição';

  @override
  String get resolutionLabel => 'Resolução';

  @override
  String get micLabel => 'Microfone';

  @override
  String get sysAudioLabel => 'Áudio do sistema';

  @override
  String get videoLabel => 'Vídeo';

  @override
  String bitrateLabel(int n) {
    return 'Bitrate: $n Mbps';
  }

  @override
  String get codecLabel => 'Codec';

  @override
  String get hevcMissing => 'Sem HEVC por hardware';

  @override
  String get audioLabel => 'Áudio';

  @override
  String get sysAudioV11 => 'Áudio do sistema (v1.1)';

  @override
  String get recordingLabel => 'Gravação';

  @override
  String get countdownLabel => 'Contagem regressiva';

  @override
  String get noneLabel => 'Não';

  @override
  String countdownSec(int n) {
    return '$n s';
  }

  @override
  String get appearanceLabel => 'Aparência';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get language => 'Idioma';

  @override
  String get langSystem => 'Sistema';

  @override
  String get quickAccess => 'Acesso rápido';

  @override
  String get quickAccessBody => 'O bloco e o widget iniciam sem abrir o app.';

  @override
  String get addTileBtn => 'Adicionar bloco';

  @override
  String get tileAdded => 'Bloco adicionado';

  @override
  String get tileUnavailable => 'Requer Android 13+';

  @override
  String get aboutLine => 'DotRec funciona off-line.';

  @override
  String get overlayNeedPermission => 'Requer “Exibir sobre outros apps”.';

  @override
  String get openPermission => 'Abrir permissão';

  @override
  String get errorLabel => 'Erro';

  @override
  String get onboardingTitle => 'Grave sua tela, sem mais';

  @override
  String get ob1 => 'Funciona sem internet';

  @override
  String get ob2 => 'Sem anúncios nem marcas d\'água';

  @override
  String get ob3 => 'Arquivos em Movies/DotRec';

  @override
  String get guidesTitle => 'Guias e permissões';

  @override
  String get guides => 'Guias';

  @override
  String get openSettings => 'Abrir configurações';

  @override
  String get guideCaptureTitle => 'Acesso à tela';

  @override
  String get guideCaptureBody =>
      'Ao iniciar, o Android mostra um diálogo de acesso à tela. No Android 14+, a permissão é pedida a cada gravação: é uma limitação do sistema.';

  @override
  String get guideMicTitle => 'Microfone';

  @override
  String get guideMicBody =>
      '1. Ative a chave “Microfone”. 2. Permita o acesso no diálogo do sistema. 3. Se negou, abra as configurações do app e ative o microfone manualmente.';

  @override
  String get guideNotifTitle => 'Notificações';

  @override
  String get guideNotifBody =>
      'A notificação com cronômetro e botões de pausar/parar aparece na primeira gravação. Se não aparecer, permita notificações nas configurações do app.';

  @override
  String get guideOverlayTitle => 'Janela flutuante';

  @override
  String get guideOverlayBody =>
      'Desativada por padrão. 1. Ative nas configurações. 2. Permita “Exibir sobre outros apps” na tela do sistema. Ela não deve aparecer nas gravações.';

  @override
  String get guideBatteryTitle => 'Bateria e segundo plano';

  @override
  String get guideBatteryBody =>
      'Algumas interfaces (Xiaomi, Samsung) encerram a gravação em segundo plano para economizar bateria. Abra as configurações de bateria, encontre o DotRec e permita a atividade em segundo plano.';

  @override
  String get guideTileTitle => 'Bloco rápido';

  @override
  String get guideTileBody =>
      '1. Abra as configurações rápidas e toque em Editar. 2. Arraste o bloco “Gravar” para a área ativa. No Android 13+, use o botão abaixo.';
}
