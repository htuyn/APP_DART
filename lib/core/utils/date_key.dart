/// Formats a calendar date as yyyy-MM-dd without converting its timezone.
String dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Returns the signed number of calendar-day boundaries between two dates.
/// Time-of-day and timezone offsets do not affect the result.
int calendarDaysBetween(DateTime from, DateTime to) {
  final fromDay = DateTime.utc(from.year, from.month, from.day);
  final toDay = DateTime.utc(to.year, to.month, to.day);
  return toDay.difference(fromDay).inDays;
}

/// Calculates calendar-day distance between stored yyyy-MM-dd keys.
int calendarDaysBetweenKeys(String from, String to) {
  final fromParts = from.split('-').map(int.parse).toList();
  final toParts = to.split('-').map(int.parse).toList();
  if (fromParts.length != 3 || toParts.length != 3) {
    throw FormatException('Invalid date key');
  }
  return calendarDaysBetween(
    DateTime.utc(fromParts[0], fromParts[1], fromParts[2]),
    DateTime.utc(toParts[0], toParts[1], toParts[2]),
  );
}
