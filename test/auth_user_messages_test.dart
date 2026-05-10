import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:minimax/features/auth/auth_user_messages.dart';
import 'package:minimax/features/auth/data/auth_repository.dart';

void main() {
  test('AuthExceptionHandler maps AuthApiException 500 to Mongolian', () {
    expect(
      AuthExceptionHandler.userMessage(
        const AuthApiException('bad', statusCode: 500),
      ),
      contains('Серверийн'),
    );
  });

  test('AuthExceptionHandler maps TimeoutException', () {
    expect(
      AuthExceptionHandler.userMessage(TimeoutException('x')),
      contains('удаан'),
    );
  });

  test('AuthExceptionHandler maps unknown errors', () {
    expect(
      AuthExceptionHandler.userMessage(Object()),
      'Алдаа гарлаа. Дахин оролдоно уу.',
    );
  });
}
