/// Mongolian strings for reminders UI and socket prompts.
abstract final class RemindersStrings {
  static const pageTitle = 'Сануулга';
  static const subtitle = 'Товлосон үүрэг, сануулгууд';
  static const tabOpen = 'Идэвхтэй';
  static const tabClosed = 'Хаагдсан';
  static const emptyOpen = 'Идэвхтэй сануулга алга.';
  static const emptyClosed = 'Хаагдсан сануулга алга.';
  static const loadError = 'Ачаалахад алдаа гарлаа.';
  static const sendError = 'Илгээхэд алдаа гарлаа.';
  static const activeChip = 'Идэвхтэй';
  static const pausedChip = 'Зам дээр зогсоосон';
  static const nextRun = 'Дараагийн ажиллагаа';
  static const scheduleDaily = 'Өдөр бүр';
  static const createTitle = 'Шинэ сануулга';
  static const fieldTitle = 'Гарчиг';
  static const fieldNotes = 'Тайлбар';
  static const fieldSchedule = 'Цаг / давталт (сонголттой)';
  static const fieldScheduleHint = 'Жишээ нь: өдөр бүр 07:00';
  static const submitCreate = 'Илгээх';
  static const cancel = 'Болих';
  static const goAssistantVoice = 'Дуутай үүсгэх';
  static const ttsError = 'Дуу тоглуулахад алдаа гарлаа.';
  static const pausedExplain =
      'Зогсоосон сануулгууд энэ төхөөрөмж дээр дохио илгээхгүй.';

  /// Same WebSocket `user_message` path as the assistant; intent prefix for the agent.
  static String wrapQuickTask(String userText) =>
      'Сануулга эсвэл даалгавар үүсгэнэ үү: ${userText.trim()}';

  static String buildCreationPrompt({
    required String title,
    required String notes,
    String scheduleHint = '',
  }) {
    final b = StringBuffer()
      ..writeln('Шинэ сануулга үүсгэнэ үү.')
      ..writeln('Гарчиг: ${title.trim()}');
    if (notes.trim().isNotEmpty) {
      b.writeln('Тайлбар: ${notes.trim()}');
    }
    if (scheduleHint.trim().isNotEmpty) {
      b.writeln('Цаг ба давталт: ${scheduleHint.trim()}');
    }
    return b.toString().trim();
  }

  static String pauseSocketMessage(String reminderId) =>
      'Сануулга түр зогсоох, дугаар: $reminderId';

  static String resumeSocketMessage(String reminderId) =>
      'Сануулга дахин идэвхжүүлэх, дугаар: $reminderId';
}
