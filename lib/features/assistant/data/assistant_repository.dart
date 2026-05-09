class AssistantReply {
  const AssistantReply(this.text);

  final String text;
}

abstract class AssistantRepository {
  Future<AssistantReply> replyTo(String input);
}

class MockAssistantRepository implements AssistantRepository {
  const MockAssistantRepository();

  @override
  Future<AssistantReply> replyTo(String input) async {
    final text = input.trim();
    final normalized = text.toLowerCase();

    if (text.isEmpty) {
      return const AssistantReply("I didn't catch that. Try again.");
    }
    if (normalized.contains('hello') ||
        normalized.contains('hi') ||
        normalized.contains('hey')) {
      return const AssistantReply('Hi, I am Baigalaa. I am ready.');
    }
    if (normalized.contains('time')) {
      final now = DateTime.now();
      final minute = now.minute.toString().padLeft(2, '0');
      return AssistantReply('It is ${now.hour}:$minute.');
    }

    return AssistantReply(
      'I heard: $text. Backend answers will connect here next.',
    );
  }
}
