
enum AbleState {
  idle,
  busy,
  success,
  error,
}

extension AbleStateExtension on AbleState {
  /// Combines two states. Precedence: error, then idle, then busy; success
  /// only when both are success. An error shows as soon as any input fails.
  AbleState operator +(AbleState other) {
    if (this == AbleState.error || other == AbleState.error) {
      return AbleState.error;
    } else if (this == AbleState.idle || other == AbleState.idle) {
      return AbleState.idle;
    } else if (this == AbleState.busy || other == AbleState.busy) {
      return AbleState.busy;
    }
    return AbleState.success;
  }
}
