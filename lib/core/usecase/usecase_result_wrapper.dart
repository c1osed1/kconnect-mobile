import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Утилита для обертывания успешных результатов в Either'<'Failure, T'>'
///
/// Преобразует успешный результат в Right(result) для использования
/// с Either типами в Clean Architecture.
///
/// [T] - тип результата
/// [result] - успешный результат операции
Either<Failure, T> resultToEither<T>(T result) => Right(result);

/// Утилита для обработки синхронных операций с try-catch
///
/// Оборачивает синхронную операцию в try-catch блок и преобразует
/// исключения в соответствующие Failure объекты.
///
/// [T] - тип возвращаемого результата
/// [operation] - функция, которая может выбросить исключение
Either<Failure, T> tryCatchToEither<T>(T Function() operation) {
  try {
    return resultToEither(operation());
  } catch (e) {
    // Преобразует исключения в ServerFailure
    if (e is Exception) {
      return Left(ServerFailure(message: e.toString()));
    }
    return Left(ServerFailure());
  }
}

/// Утилита для обработки асинхронных операций с try-catch
///
/// Аналогично [tryCatchToEither], но для асинхронных операций.
/// Оборачивает Future операцию в try-catch и преобразует исключения в Failure.
///
/// [T] - тип возвращаемого результата
/// [operation] - асинхронная функция, которая может выбросить исключение
Future<Either<Failure, T>> asyncTryCatchToEither<T>(Future<T> Function() operation) async {
  try {
    final result = await operation();
    return resultToEither(result);
  } catch (e) {
    if (e is Exception) {
      return Left(ServerFailure(message: e.toString()));
    }
    return Left(ServerFailure());
  }
}
