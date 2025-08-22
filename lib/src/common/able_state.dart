
enum AbleState {
  idle,
  busy,
  success,
  error,
}

extension AbleStateExtension on AbleState {
  AbleState operator +(AbleState other) {
    if (this == AbleState.idle || other == AbleState.idle) {
      return AbleState.idle;
    } else if (this == AbleState.busy || other == AbleState.busy) {
      return AbleState.busy;
    } else if (this == AbleState.success && other == AbleState.success) {
      return AbleState.success;
    } else if (this == AbleState.error || other == AbleState.error) {
      return AbleState.error;
    }
    throw StateError('no case for this $name}');
  }
}
