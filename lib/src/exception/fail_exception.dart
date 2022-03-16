abstract class FailException {}

class TimeoutException extends FailException {}

class FailWriteSocketException extends FailException {}
