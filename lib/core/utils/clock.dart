/// Injectable clock so date-dependent domain logic can be tested deterministically.
abstract class Clock {
  DateTime now();
}

/// Production clock backed by the system time.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
