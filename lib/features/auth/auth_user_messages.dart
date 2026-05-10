import 'dart:async';

import 'data/auth_repository.dart';

/// Mongolian strings for client-side form validation.
abstract final class AuthValidationMessages {
  static const String emailRequired = 'И-мэйл хаягаа оруулна уу.';
  static const String emailInvalid = 'Зөв и-мэйл хаяг оруулна уу.';
  static const String emailTooLong = 'И-мэйл хаяг хэт урт байна.';

  static const String nameRequired = 'Бүтэн нэрээ оруулна уу.';
  static const String nameTooShort = 'Бүтэн нэр хамгийн багадаа 2 тэмдэгт байна.';
  static const String nameTooLong = 'Бүтэн нэр хэт урт байна.';

  static const String phoneRequired = 'Утасны дугаараа оруулна уу.';
  static const String phoneInvalid = 'Зөв утасны дугаар оруулна уу.';
  static const String phoneTooLong = 'Утасны дугаар хэт урт байна.';

  static const String otpRequired = 'И-мэйлээс илгээсэн кодыг оруулна уу.';
  static const String otpTooShort = 'Код хамгийн багадаа 4 оронтой байна.';
}

/// Maps repository, network, and parsing errors to short Mongolian text for the UI.
abstract final class AuthExceptionHandler {
  AuthExceptionHandler._();

  static String userMessage(Object error) {
    if (error is AuthApiException) {
      final code = error.statusCode;
      if (code == 401 || code == 403) {
        return 'Нэвтрэх эрх хүрэлцэхгүй байна. Дахин оролдоно уу.';
      }
      if (code == 404) {
        return 'Үйлчилгээ олдсонгүй. Дараа дахин оролдоно уу.';
      }
      if (code != null && code >= 500) {
        return 'Серверийн алдаа гарлаа. Түр хүлээгээд дахин оролдоно уу.';
      }
      if (code == 408 || code == 429) {
        return 'Хүсэлт түр завгүй байна. Хэдэн секундын дараа дахин оролдоно уу.';
      }
      return 'Хүсэлт амжилтгүй боллоо. Дахин оролдоно уу.';
    }
    if (error is TimeoutException) {
      return 'Хүсэлт хэт удаан үргэлжиллээ. Дахин оролдоно уу.';
    }
    if (error is FormatException) {
      return 'Өгөгдөл буруу форматтай байна.';
    }
    final s = error.toString();
    if (s.contains('SocketException') ||
        s.contains('Failed host lookup') ||
        s.contains('Network is unreachable')) {
      return 'Сүлжээний алдаа. Интернэт холболтоо шалгаад дахин оролдоно уу.';
    }
    return 'Алдаа гарлаа. Дахин оролдоно уу.';
  }
}
