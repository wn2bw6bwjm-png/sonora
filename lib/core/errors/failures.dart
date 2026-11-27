abstract class Failure implements Exception {
  final String message;
  Failure._(this.message);
  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  ServerFailure([dynamic error]) : super._(error.toString());
}