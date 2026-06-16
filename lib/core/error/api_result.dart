import 'package:weather_app/core/error/failure.dart';

sealed class ApiResult<T> {
  const ApiResult();
}

class ApiResultSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiResultSuccess(this.data);
}

class ApiResultFailure<T> extends ApiResult<T> {
  final Failure failure;
  const ApiResultFailure(this.failure);
}
