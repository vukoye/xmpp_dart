abstract class QueueApi<T> {
  QueueApi();
  put(T content);
  resume();

  bool isEligible();
  Future<bool> execute(T content);
  Future<bool> pop();
  clear();
}
