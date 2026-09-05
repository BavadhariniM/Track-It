/// `Result`/`Either`-style return value for domain/use-case failures.
/// `GoalService` use-cases return this instead of throwing for expected
/// domain failures (Data conventions).
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.message);

  final String message;
}
