import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_schulte_engine.dart';
import '../../services/toolbox_schulte_prefs_service.dart';
import 'toolbox_tool_shell.dart';

class SchulteGridTrainingCard extends StatefulWidget {
  const SchulteGridTrainingCard({super.key});

  @override
  State<SchulteGridTrainingCard> createState() =>
      _SchulteGridTrainingCardState();
}

enum _RunState { idle, running, success, timeout }

const Map<String, Map<String, String>>
_schultePageTexts = <String, Map<String, String>>{
  'en': <String, String>{
    'introTitle': 'Schulte Grid',
    'introSubtitle':
        'Supports 4x4, 5x5, 6x6, 8x8 boards, square and extended shapes, three play modes, custom content, helper switches, and persistent best records.',
    'headlineReady': 'Ready',
    'headlineAddContent': 'Add content first',
    'sublineAddContent':
        'Paste custom text, then train with characters or words in sequence.',
    'sublineReadyTimer': 'Clear the board as fast as possible.',
    'sublineReadyCountdown': 'Finish a single board before time runs out.',
    'sublineReadyJump':
        'Clear as many boards as possible before the timer ends.',
    'headlineTimerRunning': 'Timer is running',
    'headlineCountdownRunning': 'Countdown is running',
    'headlineJumpRunning': 'Jump session is running',
    'sublineCurrentTarget': 'Current target: {token}',
    'headlineTimeUp': 'Time is up',
    'sublineTimeUp': 'Restart to try the countdown again.',
    'headlineJumpEnded': 'Jump session ended',
    'sublineJumpEnded':
        'Final score: {score} correct taps across {boards} boards.',
    'headlineBoardCleared': 'Board cleared',
    'sublineFinishTime': 'Finish time: {time}',
    'headlineBoardRefreshed': 'Board refreshed',
    'sublineContinue': 'Continue with {token}',
    'headlineKeepGoing': 'Keep going',
    'sublineNextTarget': 'Next target: {token}',
    'loadingSavedPreferences': 'Loading saved preferences...',
    'metricNext': 'Next',
    'metricProgress': 'Progress',
    'metricScore': 'Score',
    'metricTime': 'Time',
    'metricBest': 'Best',
    'metricBoards': 'Boards',
    'metricMistakes': 'Mistakes',
    'buttonStart': 'Start',
    'buttonRestart': 'Restart',
    'buttonReshuffle': 'Reshuffle',
    'emptyBoardHint': 'Add content to generate a custom Schulte board.',
    'panelModeBoard': 'Mode and Board',
    'panelCustomContent': 'Custom Content',
    'panelAssistRecords': 'Assist and Records',
    'labelTrainingMode': 'Training mode',
    'labelBoardSize': 'Board size',
    'labelShape': 'Shape',
    'labelCountdown': 'Countdown',
    'labelJumpWindow': 'Jump window',
    'labelSource': 'Source',
    'labelSplitMode': 'Split mode',
    'hintContentInput':
        'Paste a sentence, letters, characters, or a short word list.',
    'chipTrimSpaces': 'Trim spaces',
    'chipIgnorePunctuation': 'Ignore punctuation',
    'contentStats':
        'Tokens {total}, unique {unique}, duplicate groups {groups}. Repeated characters or letters remain valid if the order is correct.',
    'switchHighlightNext': 'Highlight next target',
    'switchHighlightNextSubtitle':
        'All valid matching cells are highlighted in duplicate-content runs.',
    'switchShowUpcoming': 'Show upcoming sequence',
    'switchWrongPenalty': 'Wrong tap penalty',
    'switchWrongPenaltySubtitle':
        'Adds time in timer modes and subtracts one score in jump mode.',
    'switchHaptics': 'Haptics',
    'currentBestTitle': 'Current Best Record',
    'buttonClearCurrent': 'Clear current',
    'buttonClearAll': 'Clear all',
    'noRecord':
        'No record yet for this mode, size, shape, and content combination.',
    'bestResult':
        'Best result: {score} correct taps across {boards} completed boards.',
    'bestCompletionTime': 'Best completion time: {time}.',
    'modeTimer': 'Timer',
    'modeCountdown': 'Countdown',
    'modeJump': 'Jump',
    'shapeSquare': 'Square',
    'shapeTriangle': 'Triangle',
    'shapeCross': 'Cross',
    'shapeDiamond': 'Diamond',
    'shapeRing': 'Ring',
    'sourceNumbers': 'Numbers',
    'sourceCustom': 'Custom',
    'splitCharacters': 'Characters',
    'splitWords': 'Words',
    'durationSecondsShort': '{value} s',
  },
  'zh': <String, String>{
    'introTitle': '舒尔特方格',
    'introSubtitle':
        '支持 4x4、5x5、6x6、8x8 棋盘，支持正方形与扩展形状、三种训练模式、自定义内容、辅助开关与最佳记录持久化。',
    'headlineReady': '准备开始',
    'headlineAddContent': '先输入内容',
    'sublineAddContent': '输入自定义文本后，可按字符或按词顺序训练。',
    'sublineReadyTimer': '以最快速度完成整版。',
    'sublineReadyCountdown': '在倒计时结束前完成这一版。',
    'sublineReadyJump': '在时间结束前尽可能完成更多整版。',
    'headlineTimerRunning': '标准计时进行中',
    'headlineCountdownRunning': '倒计时进行中',
    'headlineJumpRunning': '单位时间跳转进行中',
    'sublineCurrentTarget': '当前目标：{token}',
    'headlineTimeUp': '时间到',
    'sublineTimeUp': '重新开始后可以再试一次。',
    'headlineJumpEnded': '本轮结束',
    'sublineJumpEnded': '最终成绩：正确点击 {score} 次，完成整版 {boards} 次。',
    'headlineBoardCleared': '本局完成',
    'sublineFinishTime': '完成时间：{time}',
    'headlineBoardRefreshed': '已刷新新一版',
    'sublineContinue': '继续点击 {token}',
    'headlineKeepGoing': '继续',
    'sublineNextTarget': '下一个目标：{token}',
    'loadingSavedPreferences': '正在加载已保存的偏好...',
    'metricNext': '目标',
    'metricProgress': '进度',
    'metricScore': '得分',
    'metricTime': '时间',
    'metricBest': '最佳',
    'metricBoards': '整版数',
    'metricMistakes': '失误',
    'buttonStart': '开始',
    'buttonRestart': '重新开始',
    'buttonReshuffle': '重新排版',
    'emptyBoardHint': '输入内容后即可生成自定义舒尔特棋盘。',
    'panelModeBoard': '模式与棋盘',
    'panelCustomContent': '自定义内容',
    'panelAssistRecords': '辅助与记录',
    'labelTrainingMode': '训练模式',
    'labelBoardSize': '棋盘尺寸',
    'labelShape': '形状',
    'labelCountdown': '倒计时',
    'labelJumpWindow': '单位时间窗口',
    'labelSource': '内容来源',
    'labelSplitMode': '拆分方式',
    'hintContentInput': '输入句子、字母、汉字，或一组短词。',
    'chipTrimSpaces': '去除空白',
    'chipIgnorePunctuation': '忽略标点',
    'contentStats':
        '有效元素 {total}，去重后 {unique}，重复组 {groups}。重复字符或字母只要顺序正确仍判定为正确。',
    'switchHighlightNext': '高亮下一个目标',
    'switchHighlightNextSubtitle': '内容重复时，会同时高亮所有符合当前顺序的单元。',
    'switchShowUpcoming': '显示后续序列',
    'switchWrongPenalty': '错误点击惩罚',
    'switchWrongPenaltySubtitle': '计时模式增加用时，单位时间模式扣减 1 次正确点击。',
    'switchHaptics': '触感反馈',
    'currentBestTitle': '当前最佳记录',
    'buttonClearCurrent': '清除当前组合',
    'buttonClearAll': '清除全部',
    'noRecord': '当前模式、尺寸、形状和内容组合还没有记录。',
    'bestResult': '最佳成绩：正确点击 {score} 次，完成整版 {boards} 次。',
    'bestCompletionTime': '最佳完成时间：{time}。',
    'modeTimer': '标准计时',
    'modeCountdown': '倒计时跳转',
    'modeJump': '单位时间跳转',
    'shapeSquare': '正方形',
    'shapeTriangle': '三角',
    'shapeCross': '十字',
    'shapeDiamond': '菱形',
    'shapeRing': '环形',
    'sourceNumbers': '数字',
    'sourceCustom': '自定义',
    'splitCharacters': '字符',
    'splitWords': '词语',
    'durationSecondsShort': '{value} 秒',
  },
  'ja': <String, String>{
    'introTitle': 'シュルテ格子',
    'introSubtitle':
        '4x4、5x5、6x6、8x8 の盤面、正方形と拡張形状、3つのトレーニングモード、カスタム内容、補助スイッチ、ベスト記録の保存に対応。',
    'headlineReady': '準備完了',
    'headlineAddContent': '先に内容を入力',
    'sublineAddContent': 'カスタムテキストを入力すると、文字または単語の順序で練習できます。',
    'sublineReadyTimer': 'できるだけ速く盤面をクリアします。',
    'sublineReadyCountdown': '時間切れ前にこの盤面をクリアします。',
    'sublineReadyJump': '制限時間内にできるだけ多くの盤面をクリアします。',
    'headlineTimerRunning': '通常タイマー進行中',
    'headlineCountdownRunning': 'カウントダウン進行中',
    'headlineJumpRunning': 'ジャンプセッション進行中',
    'sublineCurrentTarget': '現在のターゲット: {token}',
    'headlineTimeUp': '時間切れ',
    'sublineTimeUp': '再スタートしてもう一度挑戦できます。',
    'headlineJumpEnded': 'セッション終了',
    'sublineJumpEnded': '最終結果: 正解タップ {score} 回、完了盤面 {boards} 面。',
    'headlineBoardCleared': '盤面クリア',
    'sublineFinishTime': '完了時間: {time}',
    'headlineBoardRefreshed': '盤面を更新しました',
    'sublineContinue': '{token} から続行',
    'headlineKeepGoing': '続ける',
    'sublineNextTarget': '次のターゲット: {token}',
    'loadingSavedPreferences': '保存済み設定を読み込み中...',
    'metricNext': '次',
    'metricProgress': '進捗',
    'metricScore': 'スコア',
    'metricTime': '時間',
    'metricBest': 'ベスト',
    'metricBoards': '盤面',
    'metricMistakes': 'ミス',
    'buttonStart': '開始',
    'buttonRestart': '再開始',
    'buttonReshuffle': '再シャッフル',
    'emptyBoardHint': '内容を入力してカスタム盤面を生成してください。',
    'panelModeBoard': 'モードと盤面',
    'panelCustomContent': 'カスタム内容',
    'panelAssistRecords': '補助と記録',
    'labelTrainingMode': 'トレーニングモード',
    'labelBoardSize': '盤面サイズ',
    'labelShape': '形状',
    'labelCountdown': 'カウントダウン',
    'labelJumpWindow': 'ジャンプ時間',
    'labelSource': '内容ソース',
    'labelSplitMode': '分割方法',
    'hintContentInput': '文、文字、漢字、または短い単語リストを貼り付けます。',
    'chipTrimSpaces': '空白を削除',
    'chipIgnorePunctuation': '句読点を無視',
    'contentStats':
        '要素 {total}、重複除外後 {unique}、重複グループ {groups}。重複する文字やアルファベットも順序が正しければ正解です。',
    'switchHighlightNext': '次のターゲットを強調',
    'switchHighlightNextSubtitle': '重複内容では、現在の順序に合うすべてのセルを強調表示します。',
    'switchShowUpcoming': '後続シーケンスを表示',
    'switchWrongPenalty': '誤タップのペナルティ',
    'switchWrongPenaltySubtitle': 'タイマーモードでは時間を加算し、ジャンプモードではスコアを 1 減らします。',
    'switchHaptics': '触覚フィードバック',
    'currentBestTitle': '現在のベスト記録',
    'buttonClearCurrent': '現在の組み合わせを消去',
    'buttonClearAll': 'すべて消去',
    'noRecord': 'このモード、サイズ、形状、内容の組み合わせにはまだ記録がありません。',
    'bestResult': 'ベスト結果: 正解タップ {score} 回、完了盤面 {boards} 面。',
    'bestCompletionTime': '最短完了時間: {time}。',
    'modeTimer': '通常タイマー',
    'modeCountdown': 'カウントダウン',
    'modeJump': '時間内ジャンプ',
    'shapeSquare': '正方形',
    'shapeTriangle': '三角',
    'shapeCross': '十字',
    'shapeDiamond': 'ひし形',
    'shapeRing': 'リング',
    'sourceNumbers': '数字',
    'sourceCustom': 'カスタム',
    'splitCharacters': '文字',
    'splitWords': '単語',
    'durationSecondsShort': '{value} 秒',
  },
  'de': <String, String>{
    'introTitle': 'Schulte-Gitter',
    'introSubtitle':
        'Unterstützt 4x4-, 5x5-, 6x6- und 8x8-Felder, quadratische und erweiterte Formen, drei Spielmodi, benutzerdefinierte Inhalte, Hilfsschalter und persistente Bestwerte.',
    'headlineReady': 'Bereit',
    'headlineAddContent': 'Zuerst Inhalt eingeben',
    'sublineAddContent':
        'Füge eigenen Text ein und trainiere dann Zeichen oder Wörter in Reihenfolge.',
    'sublineReadyTimer': 'Räume das Feld so schnell wie möglich ab.',
    'sublineReadyCountdown': 'Schließe dieses Feld ab, bevor die Zeit abläuft.',
    'sublineReadyJump':
        'Schließe vor Ablauf des Timers so viele Felder wie möglich ab.',
    'headlineTimerRunning': 'Timer läuft',
    'headlineCountdownRunning': 'Countdown läuft',
    'headlineJumpRunning': 'Jump-Session läuft',
    'sublineCurrentTarget': 'Aktuelles Ziel: {token}',
    'headlineTimeUp': 'Zeit abgelaufen',
    'sublineTimeUp': 'Starte neu, um den Countdown erneut zu versuchen.',
    'headlineJumpEnded': 'Jump-Session beendet',
    'sublineJumpEnded':
        'Endergebnis: {score} korrekte Treffer über {boards} abgeschlossene Felder.',
    'headlineBoardCleared': 'Feld abgeschlossen',
    'sublineFinishTime': 'Abschlusszeit: {time}',
    'headlineBoardRefreshed': 'Feld aktualisiert',
    'sublineContinue': 'Weiter mit {token}',
    'headlineKeepGoing': 'Weiter',
    'sublineNextTarget': 'Nächstes Ziel: {token}',
    'loadingSavedPreferences': 'Gespeicherte Einstellungen werden geladen...',
    'metricNext': 'Nächstes',
    'metricProgress': 'Fortschritt',
    'metricScore': 'Punkte',
    'metricTime': 'Zeit',
    'metricBest': 'Bestwert',
    'metricBoards': 'Felder',
    'metricMistakes': 'Fehler',
    'buttonStart': 'Start',
    'buttonRestart': 'Neu starten',
    'buttonReshuffle': 'Neu mischen',
    'emptyBoardHint':
        'Füge Inhalt hinzu, um ein eigenes Schulte-Feld zu erzeugen.',
    'panelModeBoard': 'Modus und Feld',
    'panelCustomContent': 'Eigener Inhalt',
    'panelAssistRecords': 'Hilfen und Rekorde',
    'labelTrainingMode': 'Trainingsmodus',
    'labelBoardSize': 'Feldgröße',
    'labelShape': 'Form',
    'labelCountdown': 'Countdown',
    'labelJumpWindow': 'Jump-Fenster',
    'labelSource': 'Quelle',
    'labelSplitMode': 'Aufteilung',
    'hintContentInput':
        'Füge einen Satz, Buchstaben, Zeichen oder eine kurze Wortliste ein.',
    'chipTrimSpaces': 'Leerzeichen entfernen',
    'chipIgnorePunctuation': 'Satzzeichen ignorieren',
    'contentStats':
        'Elemente {total}, eindeutig {unique}, Duplikatgruppen {groups}. Wiederholte Zeichen oder Buchstaben bleiben korrekt, wenn die Reihenfolge stimmt.',
    'switchHighlightNext': 'Nächstes Ziel hervorheben',
    'switchHighlightNextSubtitle':
        'Bei doppelten Inhalten werden alle gültigen passenden Felder hervorgehoben.',
    'switchShowUpcoming': 'Nächste Sequenz anzeigen',
    'switchWrongPenalty': 'Strafe für Fehlklick',
    'switchWrongPenaltySubtitle':
        'Erhöht die Zeit in Zeitmodi und zieht im Jump-Modus einen Punkt ab.',
    'switchHaptics': 'Haptik',
    'currentBestTitle': 'Aktueller Bestwert',
    'buttonClearCurrent': 'Aktuelle Kombination löschen',
    'buttonClearAll': 'Alles löschen',
    'noRecord':
        'Für diese Kombination aus Modus, Größe, Form und Inhalt gibt es noch keinen Rekord.',
    'bestResult':
        'Bestes Ergebnis: {score} korrekte Treffer über {boards} abgeschlossene Felder.',
    'bestCompletionTime': 'Beste Abschlusszeit: {time}.',
    'modeTimer': 'Timer',
    'modeCountdown': 'Countdown',
    'modeJump': 'Jump',
    'shapeSquare': 'Quadrat',
    'shapeTriangle': 'Dreieck',
    'shapeCross': 'Kreuz',
    'shapeDiamond': 'Raute',
    'shapeRing': 'Ring',
    'sourceNumbers': 'Zahlen',
    'sourceCustom': 'Benutzerdefiniert',
    'splitCharacters': 'Zeichen',
    'splitWords': 'Wörter',
    'durationSecondsShort': '{value} s',
  },
  'fr': <String, String>{
    'introTitle': 'Grille de Schulte',
    'introSubtitle':
        'Prend en charge les grilles 4x4, 5x5, 6x6 et 8x8, les formes carrées et étendues, trois modes d\'entraînement, le contenu personnalisé, les aides et la sauvegarde des meilleurs scores.',
    'headlineReady': 'Prêt',
    'headlineAddContent': 'Ajoute d\'abord du contenu',
    'sublineAddContent':
        'Colle un texte personnalisé puis entraîne-toi avec les caractères ou les mots dans l\'ordre.',
    'sublineReadyTimer': 'Termine la grille le plus vite possible.',
    'sublineReadyCountdown': 'Termine cette grille avant la fin du temps.',
    'sublineReadyJump':
        'Termine autant de grilles que possible avant la fin du chrono.',
    'headlineTimerRunning': 'Chrono en cours',
    'headlineCountdownRunning': 'Compte à rebours en cours',
    'headlineJumpRunning': 'Session jump en cours',
    'sublineCurrentTarget': 'Cible actuelle : {token}',
    'headlineTimeUp': 'Temps écoulé',
    'sublineTimeUp': 'Redémarre pour réessayer le compte à rebours.',
    'headlineJumpEnded': 'Session jump terminée',
    'sublineJumpEnded':
        'Score final : {score} clics corrects sur {boards} grilles terminées.',
    'headlineBoardCleared': 'Grille terminée',
    'sublineFinishTime': 'Temps réalisé : {time}',
    'headlineBoardRefreshed': 'Grille actualisée',
    'sublineContinue': 'Continue avec {token}',
    'headlineKeepGoing': 'Continue',
    'sublineNextTarget': 'Cible suivante : {token}',
    'loadingSavedPreferences': 'Chargement des préférences enregistrées...',
    'metricNext': 'Suivant',
    'metricProgress': 'Progression',
    'metricScore': 'Score',
    'metricTime': 'Temps',
    'metricBest': 'Meilleur',
    'metricBoards': 'Grilles',
    'metricMistakes': 'Erreurs',
    'buttonStart': 'Démarrer',
    'buttonRestart': 'Redémarrer',
    'buttonReshuffle': 'Mélanger',
    'emptyBoardHint':
        'Ajoute du contenu pour générer une grille de Schulte personnalisée.',
    'panelModeBoard': 'Mode et grille',
    'panelCustomContent': 'Contenu personnalisé',
    'panelAssistRecords': 'Aides et records',
    'labelTrainingMode': 'Mode d\'entraînement',
    'labelBoardSize': 'Taille de la grille',
    'labelShape': 'Forme',
    'labelCountdown': 'Compte à rebours',
    'labelJumpWindow': 'Fenêtre jump',
    'labelSource': 'Source',
    'labelSplitMode': 'Mode de découpe',
    'hintContentInput':
        'Colle une phrase, des lettres, des caractères ou une courte liste de mots.',
    'chipTrimSpaces': 'Supprimer les espaces',
    'chipIgnorePunctuation': 'Ignorer la ponctuation',
    'contentStats':
        'Éléments {total}, uniques {unique}, groupes dupliqués {groups}. Les caractères ou lettres répétés restent valides si l\'ordre est correct.',
    'switchHighlightNext': 'Mettre en évidence la cible suivante',
    'switchHighlightNextSubtitle':
        'Dans les contenus dupliqués, toutes les cases valides correspondantes sont mises en évidence.',
    'switchShowUpcoming': 'Afficher la suite',
    'switchWrongPenalty': 'Pénalité en cas d\'erreur',
    'switchWrongPenaltySubtitle':
        'Ajoute du temps dans les modes chronométrés et retire un point en mode jump.',
    'switchHaptics': 'Retour haptique',
    'currentBestTitle': 'Meilleur record actuel',
    'buttonClearCurrent': 'Effacer la combinaison actuelle',
    'buttonClearAll': 'Tout effacer',
    'noRecord':
        'Aucun record pour cette combinaison de mode, taille, forme et contenu.',
    'bestResult':
        'Meilleur résultat : {score} clics corrects sur {boards} grilles terminées.',
    'bestCompletionTime': 'Meilleur temps : {time}.',
    'modeTimer': 'Chrono',
    'modeCountdown': 'Compte à rebours',
    'modeJump': 'Jump',
    'shapeSquare': 'Carré',
    'shapeTriangle': 'Triangle',
    'shapeCross': 'Croix',
    'shapeDiamond': 'Losange',
    'shapeRing': 'Anneau',
    'sourceNumbers': 'Nombres',
    'sourceCustom': 'Personnalisé',
    'splitCharacters': 'Caractères',
    'splitWords': 'Mots',
    'durationSecondsShort': '{value} s',
  },
  'es': <String, String>{
    'introTitle': 'Cuadrícula Schulte',
    'introSubtitle':
        'Admite tableros 4x4, 5x5, 6x6 y 8x8, formas cuadradas y extendidas, tres modos de juego, contenido personalizado, ayudas y mejores marcas persistentes.',
    'headlineReady': 'Listo',
    'headlineAddContent': 'Añade contenido primero',
    'sublineAddContent':
        'Pega texto personalizado y luego entrena con caracteres o palabras en orden.',
    'sublineReadyTimer': 'Completa el tablero lo más rápido posible.',
    'sublineReadyCountdown':
        'Termina este tablero antes de que se agote el tiempo.',
    'sublineReadyJump':
        'Completa tantos tableros como puedas antes de que termine el temporizador.',
    'headlineTimerRunning': 'Temporizador en marcha',
    'headlineCountdownRunning': 'Cuenta atrás en marcha',
    'headlineJumpRunning': 'Sesión jump en marcha',
    'sublineCurrentTarget': 'Objetivo actual: {token}',
    'headlineTimeUp': 'Se acabó el tiempo',
    'sublineTimeUp': 'Reinicia para volver a intentar la cuenta atrás.',
    'headlineJumpEnded': 'Sesión jump terminada',
    'sublineJumpEnded':
        'Resultado final: {score} toques correctos en {boards} tableros completados.',
    'headlineBoardCleared': 'Tablero completado',
    'sublineFinishTime': 'Tiempo final: {time}',
    'headlineBoardRefreshed': 'Tablero actualizado',
    'sublineContinue': 'Continúa con {token}',
    'headlineKeepGoing': 'Sigue',
    'sublineNextTarget': 'Siguiente objetivo: {token}',
    'loadingSavedPreferences': 'Cargando preferencias guardadas...',
    'metricNext': 'Siguiente',
    'metricProgress': 'Progreso',
    'metricScore': 'Puntuación',
    'metricTime': 'Tiempo',
    'metricBest': 'Mejor',
    'metricBoards': 'Tableros',
    'metricMistakes': 'Errores',
    'buttonStart': 'Iniciar',
    'buttonRestart': 'Reiniciar',
    'buttonReshuffle': 'Reordenar',
    'emptyBoardHint':
        'Añade contenido para generar un tablero Schulte personalizado.',
    'panelModeBoard': 'Modo y tablero',
    'panelCustomContent': 'Contenido personalizado',
    'panelAssistRecords': 'Ayudas y récords',
    'labelTrainingMode': 'Modo de entrenamiento',
    'labelBoardSize': 'Tamaño del tablero',
    'labelShape': 'Forma',
    'labelCountdown': 'Cuenta atrás',
    'labelJumpWindow': 'Ventana jump',
    'labelSource': 'Fuente',
    'labelSplitMode': 'Modo de división',
    'hintContentInput':
        'Pega una frase, letras, caracteres o una lista corta de palabras.',
    'chipTrimSpaces': 'Quitar espacios',
    'chipIgnorePunctuation': 'Ignorar puntuación',
    'contentStats':
        'Elementos {total}, únicos {unique}, grupos duplicados {groups}. Los caracteres o letras repetidos siguen siendo válidos si el orden es correcto.',
    'switchHighlightNext': 'Resaltar el siguiente objetivo',
    'switchHighlightNextSubtitle':
        'En contenidos duplicados se resaltan todas las celdas válidas coincidentes.',
    'switchShowUpcoming': 'Mostrar la secuencia siguiente',
    'switchWrongPenalty': 'Penalización por error',
    'switchWrongPenaltySubtitle':
        'Añade tiempo en los modos con cronómetro y resta un punto en el modo jump.',
    'switchHaptics': 'Respuesta háptica',
    'currentBestTitle': 'Mejor récord actual',
    'buttonClearCurrent': 'Borrar combinación actual',
    'buttonClearAll': 'Borrar todo',
    'noRecord':
        'Todavía no hay récord para esta combinación de modo, tamaño, forma y contenido.',
    'bestResult':
        'Mejor resultado: {score} toques correctos en {boards} tableros completados.',
    'bestCompletionTime': 'Mejor tiempo: {time}.',
    'modeTimer': 'Temporizador',
    'modeCountdown': 'Cuenta atrás',
    'modeJump': 'Jump',
    'shapeSquare': 'Cuadrado',
    'shapeTriangle': 'Triángulo',
    'shapeCross': 'Cruz',
    'shapeDiamond': 'Rombo',
    'shapeRing': 'Anillo',
    'sourceNumbers': 'Números',
    'sourceCustom': 'Personalizado',
    'splitCharacters': 'Caracteres',
    'splitWords': 'Palabras',
    'durationSecondsShort': '{value} s',
  },
  'ru': <String, String>{
    'introTitle': 'Таблица Шульте',
    'introSubtitle':
        'Поддерживает поля 4x4, 5x5, 6x6 и 8x8, квадратные и расширенные формы, три режима тренировки, пользовательский контент, вспомогательные переключатели и сохранение лучших результатов.',
    'headlineReady': 'Готово',
    'headlineAddContent': 'Сначала добавьте контент',
    'sublineAddContent':
        'Вставьте свой текст и тренируйтесь по символам или словам по порядку.',
    'sublineReadyTimer': 'Очистите поле как можно быстрее.',
    'sublineReadyCountdown': 'Завершите это поле до окончания времени.',
    'sublineReadyJump': 'Пройдите как можно больше полей до конца таймера.',
    'headlineTimerRunning': 'Таймер запущен',
    'headlineCountdownRunning': 'Обратный отсчёт идёт',
    'headlineJumpRunning': 'Jump-сессия идёт',
    'sublineCurrentTarget': 'Текущая цель: {token}',
    'headlineTimeUp': 'Время вышло',
    'sublineTimeUp': 'Перезапустите, чтобы попробовать обратный отсчёт снова.',
    'headlineJumpEnded': 'Jump-сессия завершена',
    'sublineJumpEnded':
        'Итог: {score} правильных нажатий, завершено полей: {boards}.',
    'headlineBoardCleared': 'Поле завершено',
    'sublineFinishTime': 'Время завершения: {time}',
    'headlineBoardRefreshed': 'Поле обновлено',
    'sublineContinue': 'Продолжайте с {token}',
    'headlineKeepGoing': 'Продолжайте',
    'sublineNextTarget': 'Следующая цель: {token}',
    'loadingSavedPreferences': 'Загрузка сохранённых настроек...',
    'metricNext': 'Далее',
    'metricProgress': 'Прогресс',
    'metricScore': 'Счёт',
    'metricTime': 'Время',
    'metricBest': 'Лучшее',
    'metricBoards': 'Поля',
    'metricMistakes': 'Ошибки',
    'buttonStart': 'Старт',
    'buttonRestart': 'Перезапуск',
    'buttonReshuffle': 'Перемешать',
    'emptyBoardHint':
        'Добавьте контент, чтобы создать пользовательское поле Шульте.',
    'panelModeBoard': 'Режим и поле',
    'panelCustomContent': 'Пользовательский контент',
    'panelAssistRecords': 'Помощь и рекорды',
    'labelTrainingMode': 'Режим тренировки',
    'labelBoardSize': 'Размер поля',
    'labelShape': 'Форма',
    'labelCountdown': 'Обратный отсчёт',
    'labelJumpWindow': 'Окно jump',
    'labelSource': 'Источник',
    'labelSplitMode': 'Режим разбиения',
    'hintContentInput':
        'Вставьте предложение, буквы, символы или короткий список слов.',
    'chipTrimSpaces': 'Убрать пробелы',
    'chipIgnorePunctuation': 'Игнорировать пунктуацию',
    'contentStats':
        'Элементов {total}, уникальных {unique}, групп дубликатов {groups}. Повторяющиеся символы или буквы считаются правильными, если соблюдён порядок.',
    'switchHighlightNext': 'Подсветить следующую цель',
    'switchHighlightNextSubtitle':
        'При дубликатах подсвечиваются все подходящие ячейки текущего шага.',
    'switchShowUpcoming': 'Показать следующую последовательность',
    'switchWrongPenalty': 'Штраф за ошибку',
    'switchWrongPenaltySubtitle':
        'Добавляет время в режимах на время и снимает одно очко в режиме jump.',
    'switchHaptics': 'Тактильный отклик',
    'currentBestTitle': 'Текущий лучший рекорд',
    'buttonClearCurrent': 'Очистить текущую комбинацию',
    'buttonClearAll': 'Очистить всё',
    'noRecord':
        'Для этой комбинации режима, размера, формы и контента пока нет рекорда.',
    'bestResult':
        'Лучший результат: {score} правильных нажатий, завершено полей: {boards}.',
    'bestCompletionTime': 'Лучшее время: {time}.',
    'modeTimer': 'Таймер',
    'modeCountdown': 'Обратный отсчёт',
    'modeJump': 'Jump',
    'shapeSquare': 'Квадрат',
    'shapeTriangle': 'Треугольник',
    'shapeCross': 'Крест',
    'shapeDiamond': 'Ромб',
    'shapeRing': 'Кольцо',
    'sourceNumbers': 'Числа',
    'sourceCustom': 'Свой',
    'splitCharacters': 'Символы',
    'splitWords': 'Слова',
    'durationSecondsShort': '{value} с',
  },
};

class _SchulteGridTrainingCardState extends State<SchulteGridTrainingCard> {
  final math.Random _random = math.Random();
  final TextEditingController _contentController = TextEditingController();
  final Set<int> _clearedSlots = <int>{};
  final Map<String, int> _bestTimeMsByKey = <String, int>{};
  final Map<String, SchulteJumpBestRecord> _bestJumpRecordByKey =
      <String, SchulteJumpBestRecord>{};

  Timer? _ticker;
  Timer? _prefsSaveTimer;
  SchulteBoardData? _board;

  SchulteBoardShape _shape = SchulteBoardShape.square;
  SchultePlayMode _mode = SchultePlayMode.timer;
  SchulteSourceMode _sourceMode = SchulteSourceMode.numbers;
  SchulteContentSplitMode _splitMode = SchulteContentSplitMode.character;

  int _boardSize = 5;
  int _countdownSeconds = 45;
  int _jumpSeconds = 60;

  bool _stripWhitespace = true;
  bool _ignorePunctuation = false;
  bool _highlightNextTarget = true;
  bool _showUpcomingStrip = true;
  bool _hapticsEnabled = true;
  bool _wrongTapPenaltyEnabled = false;
  bool _prefsLoaded = false;

  _RunState _runState = _RunState.idle;
  int _expectedIndex = 0;
  int _elapsedMs = 0;
  int _remainingMs = 0;
  int _score = 0;
  int _boardsCompleted = 0;
  int _mistakes = 0;
  String _headlineKey = 'headlineReady';
  Map<String, Object?> _headlineParams = const <String, Object?>{};
  String _sublineKey = 'sublineReadyTimer';
  Map<String, Object?> _sublineParams = const <String, Object?>{};

  @override
  void initState() {
    super.initState();
    _preparePreviewBoard(persist: false);
    unawaited(_loadPrefs());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _prefsSaveTimer?.cancel();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final loaded = await ToolboxSchultePrefsService.load();
    if (!mounted) {
      return;
    }
    _shape = SchulteBoardShape.fromId(loaded.shapeId);
    _mode = SchultePlayMode.fromId(loaded.modeId);
    _sourceMode = SchulteSourceMode.fromId(loaded.sourceModeId);
    _splitMode = SchulteContentSplitMode.fromId(loaded.contentSplitModeId);
    _boardSize = sanitizeSchulteBoardSize(loaded.boardSize);
    _countdownSeconds = sanitizeSchulteCountdownSeconds(
      loaded.countdownSeconds,
    );
    _jumpSeconds = sanitizeSchulteJumpSeconds(loaded.jumpSeconds);
    _stripWhitespace = loaded.stripWhitespace;
    _ignorePunctuation = loaded.ignorePunctuation;
    _highlightNextTarget = loaded.highlightNextTarget;
    _showUpcomingStrip = loaded.showUpcomingStrip;
    _hapticsEnabled = loaded.hapticsEnabled;
    _wrongTapPenaltyEnabled = loaded.wrongTapPenaltyEnabled;
    _contentController.text = loaded.customText;
    _bestTimeMsByKey
      ..clear()
      ..addAll(loaded.bestTimeMsByKey);
    _bestJumpRecordByKey
      ..clear()
      ..addAll(loaded.bestJumpRecordByKey);
    _prefsLoaded = true;
    _preparePreviewBoard(persist: false);
  }

  Future<void> _savePrefs() {
    return ToolboxSchultePrefsService.save(
      SchulteGridPrefsState(
        boardSize: _boardSize,
        shapeId: _shape.id,
        modeId: _mode.id,
        sourceModeId: _sourceMode.id,
        customText: _contentController.text,
        contentSplitModeId: _splitMode.id,
        stripWhitespace: _stripWhitespace,
        ignorePunctuation: _ignorePunctuation,
        countdownSeconds: _countdownSeconds,
        jumpSeconds: _jumpSeconds,
        highlightNextTarget: _highlightNextTarget,
        showUpcomingStrip: _showUpcomingStrip,
        hapticsEnabled: _hapticsEnabled,
        wrongTapPenaltyEnabled: _wrongTapPenaltyEnabled,
        bestTimeMsByKey: Map<String, int>.from(_bestTimeMsByKey),
        bestJumpRecordByKey: Map<String, SchulteJumpBestRecord>.from(
          _bestJumpRecordByKey,
        ),
      ),
    );
  }

  Future<void> _savePrefsNow() {
    _prefsSaveTimer?.cancel();
    return _savePrefs();
  }

  void _queuePrefsSave({Duration delay = const Duration(milliseconds: 220)}) {
    if (!_prefsLoaded) {
      return;
    }
    _prefsSaveTimer?.cancel();
    _prefsSaveTimer = Timer(delay, () {
      unawaited(_savePrefs());
    });
  }

  String _uiText(
    String key, {
    Map<String, Object?> params = const <String, Object?>{},
  }) {
    final locale = Localizations.maybeLocaleOf(context);
    final language = AppI18n.normalizeLanguageCode(
      locale?.languageCode ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    );
    var value =
        _schultePageTexts[language]?[key] ??
        _schultePageTexts['en']?[key] ??
        key;
    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value ?? ''}');
    }
    return value;
  }

  String get _headline => _uiText(_headlineKey, params: _headlineParams);

  String get _subline => _uiText(_sublineKey, params: _sublineParams);

  void _setStatus(
    String headlineKey,
    String sublineKey, {
    Map<String, Object?> headlineParams = const <String, Object?>{},
    Map<String, Object?> sublineParams = const <String, Object?>{},
  }) {
    _headlineKey = headlineKey;
    _headlineParams = Map<String, Object?>.from(headlineParams);
    _sublineKey = sublineKey;
    _sublineParams = Map<String, Object?>.from(sublineParams);
  }

  int get _durationMs {
    return switch (_mode) {
      SchultePlayMode.timer => 0,
      SchultePlayMode.countdown => _countdownSeconds * 1000,
      SchultePlayMode.jump => _jumpSeconds * 1000,
    };
  }

  int get _recordDurationSeconds {
    return switch (_mode) {
      SchultePlayMode.timer => 0,
      SchultePlayMode.countdown => _countdownSeconds,
      SchultePlayMode.jump => _jumpSeconds,
    };
  }

  String get _expectedToken {
    final sequence = _board?.sequence ?? const <String>[];
    if (_expectedIndex < 0 || _expectedIndex >= sequence.length) {
      return '-';
    }
    return sequence[_expectedIndex];
  }

  int get _activeTargetCount => _board?.sequence.length ?? 0;

  String get _recordKey {
    return buildSchulteRecordKey(
      mode: _mode,
      shape: _shape,
      size: _boardSize,
      durationSeconds: _recordDurationSeconds,
      sourceMode: _sourceMode,
      contentSignature: buildSchulteContentSignature(
        sourceMode: _sourceMode,
        customText: _contentController.text,
        splitMode: _splitMode,
        stripWhitespace: _stripWhitespace,
        ignorePunctuation: _ignorePunctuation,
      ),
    );
  }

  SchulteBoardData _buildBoard() {
    return buildSchulteBoard(
      size: _boardSize,
      shape: _shape,
      sourceMode: _sourceMode,
      customText: _contentController.text,
      splitMode: _splitMode,
      stripWhitespace: _stripWhitespace,
      ignorePunctuation: _ignorePunctuation,
      random: _random,
    );
  }

  void _preparePreviewBoard({bool persist = true}) {
    final board = _buildBoard();
    _stopTicker();
    if (!mounted) {
      return;
    }
    setState(() {
      _board = board;
      _runState = _RunState.idle;
      _clearedSlots.clear();
      _expectedIndex = 0;
      _elapsedMs = 0;
      _remainingMs = _durationMs;
      _score = 0;
      _boardsCompleted = 0;
      _mistakes = 0;
      if (board.sequence.isEmpty) {
        _setStatus('headlineAddContent', 'sublineAddContent');
      } else {
        _setStatus('headlineReady', switch (_mode) {
          SchultePlayMode.timer => 'sublineReadyTimer',
          SchultePlayMode.countdown => 'sublineReadyCountdown',
          SchultePlayMode.jump => 'sublineReadyJump',
        });
      }
    });
    if (persist) {
      _queuePrefsSave();
    }
  }

  void _startSession() {
    final board = _buildBoard();
    if (board.sequence.isEmpty) {
      _preparePreviewBoard();
      return;
    }
    _stopTicker();
    setState(() {
      _board = board;
      _runState = _RunState.running;
      _clearedSlots.clear();
      _expectedIndex = 0;
      _elapsedMs = 0;
      _remainingMs = _durationMs;
      _score = 0;
      _boardsCompleted = 0;
      _mistakes = 0;
      _setStatus(
        switch (_mode) {
          SchultePlayMode.timer => 'headlineTimerRunning',
          SchultePlayMode.countdown => 'headlineCountdownRunning',
          SchultePlayMode.jump => 'headlineJumpRunning',
        },
        'sublineCurrentTarget',
        sublineParams: <String, Object?>{'token': _expectedToken},
      );
    });
    _ticker = Timer.periodic(const Duration(milliseconds: 100), _onTick);
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _onTick(Timer timer) {
    if (!mounted || _runState != _RunState.running) {
      return;
    }
    final elapsed = _mode.isTimed
        ? math.min(_elapsedMs + 100, _durationMs)
        : _elapsedMs + 100;
    final remaining = _mode.isTimed ? math.max(0, _durationMs - elapsed) : 0;
    setState(() {
      _elapsedMs = elapsed;
      _remainingMs = remaining;
    });
    if (_mode.isTimed && remaining <= 0) {
      _finishTimeout();
    }
  }

  void _finishTimeout() {
    _stopTicker();
    if (_runState != _RunState.running) {
      return;
    }
    if (_mode == SchultePlayMode.jump) {
      final record = SchulteJumpBestRecord(
        score: _score,
        rounds: _boardsCompleted,
      );
      if (record.isBetterThan(_bestJumpRecordByKey[_recordKey])) {
        _bestJumpRecordByKey[_recordKey] = record;
      }
      setState(() {
        _runState = _RunState.timeout;
        _setStatus(
          'headlineJumpEnded',
          'sublineJumpEnded',
          sublineParams: <String, Object?>{
            'score': _score,
            'boards': _boardsCompleted,
          },
        );
      });
      unawaited(_savePrefsNow());
      return;
    }
    setState(() {
      _runState = _RunState.timeout;
      _setStatus('headlineTimeUp', 'sublineTimeUp');
    });
  }

  void _finishSuccess() {
    _stopTicker();
    if (_runState != _RunState.running) {
      return;
    }
    final current = _bestTimeMsByKey[_recordKey];
    if (current == null || _elapsedMs < current) {
      _bestTimeMsByKey[_recordKey] = _elapsedMs;
    }
    setState(() {
      _runState = _RunState.success;
      _setStatus(
        'headlineBoardCleared',
        'sublineFinishTime',
        sublineParams: <String, Object?>{'time': _formatDuration(_elapsedMs)},
      );
    });
    unawaited(_savePrefsNow());
  }

  void _refreshJumpBoard() {
    final board = _buildBoard();
    if (board.sequence.isEmpty) {
      _finishTimeout();
      return;
    }
    setState(() {
      _board = board;
      _clearedSlots.clear();
      _expectedIndex = 0;
      _boardsCompleted += 1;
      _setStatus(
        'headlineBoardRefreshed',
        'sublineContinue',
        sublineParams: <String, Object?>{'token': _expectedToken},
      );
    });
  }

  void _onCellTap(int slotIndex) {
    final board = _board;
    if (board == null || _runState != _RunState.running) {
      return;
    }
    if (_clearedSlots.contains(slotIndex)) {
      return;
    }
    final token = board.slotTokens[slotIndex];
    if (token == null) {
      return;
    }
    if (token != _expectedToken) {
      _handleWrongTap();
      return;
    }
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }
    final nextIndex = _expectedIndex + 1;
    final completed = nextIndex >= board.sequence.length;
    setState(() {
      _clearedSlots.add(slotIndex);
      _expectedIndex = nextIndex;
      if (_mode == SchultePlayMode.jump) {
        _score += 1;
      }
      if (!completed) {
        _setStatus(
          'headlineKeepGoing',
          'sublineNextTarget',
          sublineParams: <String, Object?>{
            'token': board.sequence[_expectedIndex],
          },
        );
      }
    });
    if (!completed) {
      return;
    }
    if (_mode == SchultePlayMode.jump) {
      _refreshJumpBoard();
      return;
    }
    _finishSuccess();
  }

  void _handleWrongTap() {
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.mediumImpact());
    }
    var timeout = false;
    setState(() {
      _mistakes += 1;
      if (!_wrongTapPenaltyEnabled) {
        return;
      }
      switch (_mode) {
        case SchultePlayMode.timer:
          _elapsedMs += 800;
        case SchultePlayMode.countdown:
          _elapsedMs = math.min(_durationMs, _elapsedMs + 800);
          _remainingMs = math.max(0, _durationMs - _elapsedMs);
          timeout = _remainingMs <= 0;
        case SchultePlayMode.jump:
          _score = math.max(0, _score - 1);
      }
    });
    if (timeout) {
      _finishTimeout();
    }
  }

  void _clearCurrentRecord() {
    setState(() {
      if (_mode == SchultePlayMode.jump) {
        _bestJumpRecordByKey.remove(_recordKey);
      } else {
        _bestTimeMsByKey.remove(_recordKey);
      }
    });
    unawaited(_savePrefsNow());
  }

  void _clearAllRecords() {
    setState(() {
      _bestTimeMsByKey.clear();
      _bestJumpRecordByKey.clear();
    });
    unawaited(_savePrefsNow());
  }

  void _applyBoardConfig(VoidCallback change) {
    change();
    _preparePreviewBoard();
  }

  void _applyToggle(VoidCallback change) {
    setState(change);
    _queuePrefsSave();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final board = _board;
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final boardPane = _buildBoardPane(theme, board);
    final settingsPane = _buildSettingsPane(theme);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildIntro(theme),
            const SizedBox(height: 18),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(flex: 8, child: boardPane),
                  const SizedBox(width: 18),
                  Expanded(flex: 6, child: settingsPane),
                ],
              )
            else ...<Widget>[
              boardPane,
              const SizedBox(height: 18),
              settingsPane,
            ],
            if (!_prefsLoaded) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _uiText('loadingSavedPreferences'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primaryContainer,
            theme.colorScheme.surfaceContainerHigh,
          ],
        ),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _uiText('introTitle'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(_uiText('introSubtitle'), style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildBoardPane(ThemeData theme, SchulteBoardData? board) {
    final urgent =
        _mode.isTimed && _runState == _RunState.running && _remainingMs <= 5000;
    final activeCount = _activeTargetCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(
          color: urgent
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _headline,
            key: const Key('schulte-status-title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(_subline, style: theme.textTheme.bodySmall),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: _uiText('metricNext'),
                value: _expectedToken,
              ),
              ToolboxMetricCard(
                label: _uiText('metricProgress'),
                value: activeCount == 0
                    ? '-'
                    : '$_expectedIndex / $activeCount',
              ),
              ToolboxMetricCard(
                label: _mode == SchultePlayMode.jump
                    ? _uiText('metricScore')
                    : _uiText('metricTime'),
                value: _mode == SchultePlayMode.jump
                    ? '$_score'
                    : _mode.isTimed
                    ? _formatRemaining(_remainingMs)
                    : _formatDuration(_elapsedMs),
              ),
              ToolboxMetricCard(
                label: _uiText('metricBest'),
                value: _bestValueText(),
              ),
              if (_mode == SchultePlayMode.jump)
                ToolboxMetricCard(
                  label: _uiText('metricBoards'),
                  value: '$_boardsCompleted',
                ),
              ToolboxMetricCard(
                label: _uiText('metricMistakes'),
                value: '$_mistakes',
              ),
            ],
          ),
          if (_showUpcomingStrip && board != null && board.sequence.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _buildUpcomingStrip(theme, board),
            ),
          const SizedBox(height: 16),
          _buildBoardSurface(theme, board, urgent),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                key: const Key('schulte-start-button'),
                onPressed: board == null || board.sequence.isEmpty
                    ? null
                    : _startSession,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _uiText(
                    _runState == _RunState.running
                        ? 'buttonRestart'
                        : 'buttonStart',
                  ),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('schulte-preview-button'),
                onPressed: _preparePreviewBoard,
                icon: const Icon(Icons.shuffle_rounded),
                label: Text(_uiText('buttonReshuffle')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingStrip(ThemeData theme, SchulteBoardData board) {
    final tokens = board.sequence
        .skip(_expectedIndex)
        .take(6)
        .toList(growable: false);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tokens
            .asMap()
            .entries
            .map(
              (entry) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: entry.key == 0
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: entry.key == 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _buildBoardSurface(
    ThemeData theme,
    SchulteBoardData? board,
    bool urgent,
  ) {
    if (board == null) {
      return const SizedBox.shrink();
    }
    final activeSlots = board.activeSlots.toSet();
    final allowHighlight =
        _highlightNextTarget && _runState == _RunState.running;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHigh,
          ],
        ),
        border: Border.all(
          color: urgent
              ? theme.colorScheme.error.withValues(alpha: 0.8)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: board.size * board.size,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: board.size,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                if (!activeSlots.contains(index)) {
                  return const SizedBox.shrink();
                }
                final token = board.slotTokens[index];
                final cleared = _clearedSlots.contains(index);
                final highlighted =
                    allowHighlight &&
                    !cleared &&
                    token != null &&
                    token == _expectedToken;
                return _BoardTile(
                  key: token != null && _sourceMode == SchulteSourceMode.numbers
                      ? Key('schulte-cell-$token')
                      : Key('schulte-cell-slot-$index'),
                  token: token,
                  cleared: cleared,
                  highlighted: highlighted,
                  onTap: token == null ? null : () => _onCellTap(index),
                );
              },
            ),
            if (board.sequence.isEmpty)
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    _uiText('emptyBoardHint'),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPane(ThemeData theme) {
    final stats = _contentStats();
    return Column(
      children: <Widget>[
        _Panel(
          title: _uiText('panelModeBoard'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _choiceGroup<SchultePlayMode>(
                title: _uiText('labelTrainingMode'),
                values: SchultePlayMode.values,
                selected: _mode,
                keyBuilder: (value) => Key('schulte-mode-${value.id}'),
                labelBuilder: _modeLabel,
                onSelected: (value) => _applyBoardConfig(() {
                  _mode = value;
                }),
              ),
              const SizedBox(height: 14),
              _choiceGroup<int>(
                title: _uiText('labelBoardSize'),
                values: schulteBoardSizes,
                selected: _boardSize,
                keyBuilder: (value) => Key('schulte-size-$value'),
                labelBuilder: (value) => '$value x $value',
                onSelected: (value) => _applyBoardConfig(() {
                  _boardSize = value;
                }),
              ),
              const SizedBox(height: 14),
              _choiceGroup<SchulteBoardShape>(
                title: _uiText('labelShape'),
                values: SchulteBoardShape.values,
                selected: _shape,
                keyBuilder: (value) => Key('schulte-shape-${value.id}'),
                labelBuilder: _shapeLabel,
                onSelected: (value) => _applyBoardConfig(() {
                  _shape = value;
                }),
              ),
              if (_mode == SchultePlayMode.countdown) ...<Widget>[
                const SizedBox(height: 14),
                _choiceGroup<int>(
                  title: _uiText('labelCountdown'),
                  values: schulteCountdownOptions,
                  selected: _countdownSeconds,
                  keyBuilder: (value) => Key('schulte-countdown-$value'),
                  labelBuilder: _secondsChoiceLabel,
                  onSelected: (value) => _applyBoardConfig(() {
                    _countdownSeconds = value;
                  }),
                ),
              ],
              if (_mode == SchultePlayMode.jump) ...<Widget>[
                const SizedBox(height: 14),
                _choiceGroup<int>(
                  title: _uiText('labelJumpWindow'),
                  values: schulteJumpOptions,
                  selected: _jumpSeconds,
                  keyBuilder: (value) => Key('schulte-jump-$value'),
                  labelBuilder: _secondsChoiceLabel,
                  onSelected: (value) => _applyBoardConfig(() {
                    _jumpSeconds = value;
                  }),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Panel(
          title: _uiText('panelCustomContent'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _choiceGroup<SchulteSourceMode>(
                title: _uiText('labelSource'),
                values: SchulteSourceMode.values,
                selected: _sourceMode,
                keyBuilder: (value) => Key('schulte-source-${value.id}'),
                labelBuilder: _sourceLabel,
                onSelected: (value) => _applyBoardConfig(() {
                  _sourceMode = value;
                }),
              ),
              const SizedBox(height: 14),
              _choiceGroup<SchulteContentSplitMode>(
                title: _uiText('labelSplitMode'),
                values: SchulteContentSplitMode.values,
                selected: _splitMode,
                keyBuilder: (value) => Key('schulte-split-${value.id}'),
                labelBuilder: _splitModeLabel,
                onSelected: (value) => _applyBoardConfig(() {
                  _splitMode = value;
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('schulte-content-input'),
                controller: _contentController,
                minLines: 5,
                maxLines: 8,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: _uiText('hintContentInput'),
                ),
                onChanged: (_) => _preparePreviewBoard(),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilterChip(
                    key: const Key('schulte-strip-whitespace'),
                    selected: _stripWhitespace,
                    label: Text(_uiText('chipTrimSpaces')),
                    onSelected: (_) => _applyBoardConfig(() {
                      _stripWhitespace = !_stripWhitespace;
                    }),
                  ),
                  FilterChip(
                    key: const Key('schulte-ignore-punctuation'),
                    selected: _ignorePunctuation,
                    label: Text(_uiText('chipIgnorePunctuation')),
                    onSelected: (_) => _applyBoardConfig(() {
                      _ignorePunctuation = !_ignorePunctuation;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  _uiText(
                    'contentStats',
                    params: <String, Object?>{
                      'total': stats.total,
                      'unique': stats.unique,
                      'groups': stats.duplicateKinds,
                    },
                  ),
                  key: const Key('schulte-content-stats'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Panel(
          title: _uiText('panelAssistRecords'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SwitchListTile(
                key: const Key('schulte-highlight-next-switch'),
                value: _highlightNextTarget,
                contentPadding: EdgeInsets.zero,
                title: Text(_uiText('switchHighlightNext')),
                subtitle: Text(_uiText('switchHighlightNextSubtitle')),
                onChanged: (_) => _applyToggle(() {
                  _highlightNextTarget = !_highlightNextTarget;
                }),
              ),
              SwitchListTile(
                value: _showUpcomingStrip,
                contentPadding: EdgeInsets.zero,
                title: Text(_uiText('switchShowUpcoming')),
                onChanged: (_) => _applyToggle(() {
                  _showUpcomingStrip = !_showUpcomingStrip;
                }),
              ),
              SwitchListTile(
                value: _wrongTapPenaltyEnabled,
                contentPadding: EdgeInsets.zero,
                title: Text(_uiText('switchWrongPenalty')),
                subtitle: Text(_uiText('switchWrongPenaltySubtitle')),
                onChanged: (_) => _applyToggle(() {
                  _wrongTapPenaltyEnabled = !_wrongTapPenaltyEnabled;
                }),
              ),
              SwitchListTile(
                value: _hapticsEnabled,
                contentPadding: EdgeInsets.zero,
                title: Text(_uiText('switchHaptics')),
                onChanged: (_) => _applyToggle(() {
                  _hapticsEnabled = !_hapticsEnabled;
                }),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _uiText('currentBestTitle'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _bestDescription(),
                      key: const Key('schulte-best-record-text'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton.icon(
                          key: const Key('schulte-clear-current-record'),
                          onPressed: _clearCurrentRecord,
                          icon: const Icon(Icons.cleaning_services_outlined),
                          label: Text(_uiText('buttonClearCurrent')),
                        ),
                        OutlinedButton.icon(
                          key: const Key('schulte-clear-all-records'),
                          onPressed: _clearAllRecords,
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: Text(_uiText('buttonClearAll')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _choiceGroup<T>({
    required String title,
    required List<T> values,
    required T selected,
    required Key Function(T value) keyBuilder,
    required String Function(T value) labelBuilder,
    required ValueChanged<T> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => ChoiceChip(
                  key: keyBuilder(value),
                  selected: value == selected,
                  label: Text(labelBuilder(value)),
                  onSelected: (_) => onSelected(value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  ({int total, int unique, int duplicateKinds}) _contentStats() {
    final tokens = buildSchulteContentTokens(
      _contentController.text,
      splitMode: _splitMode,
      stripWhitespace: _stripWhitespace,
      ignorePunctuation: _ignorePunctuation,
    );
    if (tokens.isEmpty) {
      return (total: 0, unique: 0, duplicateKinds: 0);
    }
    final counts = <String, int>{};
    for (final token in tokens) {
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return (
      total: tokens.length,
      unique: counts.length,
      duplicateKinds: counts.values.where((count) => count > 1).length,
    );
  }

  String _modeLabel(SchultePlayMode mode) {
    return switch (mode) {
      SchultePlayMode.timer => _uiText('modeTimer'),
      SchultePlayMode.countdown => _uiText('modeCountdown'),
      SchultePlayMode.jump => _uiText('modeJump'),
    };
  }

  String _shapeLabel(SchulteBoardShape shape) {
    return switch (shape) {
      SchulteBoardShape.square => _uiText('shapeSquare'),
      SchulteBoardShape.triangle => _uiText('shapeTriangle'),
      SchulteBoardShape.cross => _uiText('shapeCross'),
      SchulteBoardShape.diamond => _uiText('shapeDiamond'),
      SchulteBoardShape.ring => _uiText('shapeRing'),
    };
  }

  String _sourceLabel(SchulteSourceMode mode) {
    return switch (mode) {
      SchulteSourceMode.numbers => _uiText('sourceNumbers'),
      SchulteSourceMode.custom => _uiText('sourceCustom'),
    };
  }

  String _splitModeLabel(SchulteContentSplitMode mode) {
    return switch (mode) {
      SchulteContentSplitMode.character => _uiText('splitCharacters'),
      SchulteContentSplitMode.word => _uiText('splitWords'),
    };
  }

  String _secondsChoiceLabel(int value) {
    return _uiText(
      'durationSecondsShort',
      params: <String, Object?>{'value': value},
    );
  }

  String _bestValueText() {
    if (_mode == SchultePlayMode.jump) {
      final record = _bestJumpRecordByKey[_recordKey];
      return record == null ? '--' : '${record.score}';
    }
    final best = _bestTimeMsByKey[_recordKey];
    return best == null ? '--' : _formatDuration(best);
  }

  String _bestDescription() {
    if (_mode == SchultePlayMode.jump) {
      final record = _bestJumpRecordByKey[_recordKey];
      if (record == null) {
        return _uiText('noRecord');
      }
      return _uiText(
        'bestResult',
        params: <String, Object?>{
          'score': record.score,
          'boards': record.rounds,
        },
      );
    }
    final best = _bestTimeMsByKey[_recordKey];
    if (best == null) {
      return _uiText('noRecord');
    }
    return _uiText(
      'bestCompletionTime',
      params: <String, Object?>{'time': _formatDuration(best)},
    );
  }

  String _formatDuration(int milliseconds) {
    final safe = math.max(0, milliseconds);
    final minutes = safe ~/ 60000;
    final seconds = (safe % 60000) ~/ 1000;
    final tenths = (safe % 1000) ~/ 100;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
    }
    return _uiText(
      'durationSecondsShort',
      params: <String, Object?>{'value': '$seconds.$tenths'},
    );
  }

  String _formatRemaining(int milliseconds) {
    final safe = math.max(0, milliseconds);
    final seconds = (safe / 1000).floor();
    final tenths = ((safe % 1000) / 100).floor();
    return _uiText(
      'durationSecondsShort',
      params: <String, Object?>{'value': '$seconds.$tenths'},
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BoardTile extends StatelessWidget {
  const _BoardTile({
    super.key,
    required this.token,
    required this.cleared,
    required this.highlighted,
    required this.onTap,
  });

  final String? token;
  final bool cleared;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: cleared
              ? theme.colorScheme.primaryContainer
              : highlighted
              ? theme.colorScheme.secondaryContainer
              : token == null
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surface,
          border: Border.all(
            color: cleared
                ? theme.colorScheme.primary
                : highlighted
                ? theme.colorScheme.secondary
                : theme.colorScheme.outlineVariant,
            width: highlighted ? 1.8 : 1,
          ),
          boxShadow: highlighted
              ? <BoxShadow>[
                  BoxShadow(
                    blurRadius: 18,
                    spreadRadius: 1,
                    color: theme.colorScheme.secondary.withValues(alpha: 0.18),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                token ?? '',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
