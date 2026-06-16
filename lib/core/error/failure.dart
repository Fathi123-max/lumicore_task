sealed class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred. Please try again later.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please check your network connection.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'No cached data was found.']);
}

class InvalidInputFailure extends Failure {
  const InvalidInputFailure([super.message = 'Invalid city name. Please try another one.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
