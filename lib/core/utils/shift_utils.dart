/// Determine the current shift based on hour of day.
/// Shift 1: 01:00 – 09:00
/// Shift 2: 09:00 – 17:00
/// Shift 3: 17:00 – 01:00
String getCurrentShift({DateTime? dateTime}) {
  final now = dateTime ?? DateTime.now();
  final hour = now.hour;

  if (hour >= 1 && hour < 9) return 'Shift 1';
  if (hour >= 9 && hour < 17) return 'Shift 2';
  return 'Shift 3';
}

/// Check if a user's assigned shift matches the current shift.
bool isUserInShift(String assignedShift, {DateTime? dateTime}) {
  return assignedShift == getCurrentShift(dateTime: dateTime);
}

/// Get a human-readable time range for a given shift name.
String getShiftTimeRange(String shiftName) {
  switch (shiftName) {
    case 'Shift 1':
      return '01:00 – 09:00';
    case 'Shift 2':
      return '09:00 – 17:00';
    case 'Shift 3':
      return '17:00 – 01:00';
    default:
      return 'Unknown';
  }
}
