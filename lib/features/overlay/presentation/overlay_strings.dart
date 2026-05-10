/// Mongolian UI copy for the floating overlay (engine isolate).
abstract final class OverlayStrings {
  static const String title = 'Байгалаа';
  static const String subtitleIdle = 'Бэлэн';
  static const String recording = 'Бичиж байна…';
  static const String uploading = 'Илгээж байна…';
  static const String playing = 'Хариу тоглуулж байна…';
  static const String micDenied =
      'Микрофоны зөвшөөрөл хэрэгтэй. Тохиргооноос нээнэ үү.';
  static const String recordFailed = 'Дуу бичих боломжгүй байна.';
  static const String emptyRecording = 'Дуу бичигдээгүй байна.';
  static const String hintIdle = 'Дуугаар тушаал өгнө үү.';
  /// While recording — mirrors assistant “Recording… speak now.”
  static const String recordingSpeakNow =
      'Ярьж байна. Зогсоох: мик дахин дарна уу.';
  static const String voiceMessageLabel = 'Дууны мессеж';
  static const String loginRequired =
      'Нэвтэрсэн эсвэл API түлхүүр тохируулна уу.';
  static const String closeTooltip = 'Хаах';
  static const String again = 'Дахин';
  static const String done = 'Дуусгах';

  static String errorBrief(Object e) =>
      'Алдаа: ${e.toString().length > 80 ? "${e.toString().substring(0, 80)}…" : e}';
}
