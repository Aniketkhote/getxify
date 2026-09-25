/// Exception thrown when [Obx] or [GetX] widgets are used improperly.
///
/// This error commonly occurs if no observable variables (`Rx` types) are detected
/// within the build scope of the reactive widget.
class ObxError implements Exception {
  /// Creates a constant instance of [ObxError].
  const ObxError();

  @override
  String toString() {
    return """
      [Get] the improper use of a GetX has been detected. 
      You should only use GetX or Obx for the specific widget that will be updated.
      If you are seeing this error, you probably did not insert any observable variables into GetX/Obx 
      or insert them outside the scope that GetX considers suitable for an update 
      (example: GetX => HeavyWidget => variableObservable).
      If you need to update a parent widget and a child widget, wrap each one in an Obx/GetX.
      """;
  }
}
