import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/utils/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should store data', () {
        final result = Result.success('hello');
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.dataOrNull, equals('hello'));
        expect(result.errorOrNull, isNull);
      });

      test('when() should call success callback', () {
        final result = Result.success(42);
        final value = result.when(
          success: (data) => data * 2,
          failure: (_) => -1,
        );
        expect(value, equals(84));
      });
    });

    group('Failure', () {
      test('should store message', () {
        final result = Result.failure('error message');
        expect(result.isFailure, isTrue);
        expect(result.isSuccess, isFalse);
        expect(result.dataOrNull, isNull);
        expect(result.errorOrNull, equals('error message'));
      });

      test('when() should call failure callback', () {
        final result = Result.failure('something broke');
        final value = result.when(
          success: (_) => 'ok',
          failure: (msg) => 'error: $msg',
        );
        expect(value, equals('error: something broke'));
      });

      test('should store error and stackTrace', () {
        final error = Exception('test');
        final stack = StackTrace.current;
        final result = Result.failure(
          'msg',
          error: error,
          stackTrace: stack,
        );
        expect(result.errorOrNull, equals('msg'));
      });
    });
  });
}
