import 'dart:async';

class TimerBloc {
  StreamController<Duration> timerCount = StreamController<Duration>.broadcast();
  Stream get getTime => timerCount.stream;
  Stopwatch _watch;
  Timer _timer;
  Duration _currentDuration = Duration.zero;

  bool get isRunning => _timer != null;

  TimerBloc(){
    _watch = Stopwatch();
  }

  void updateCount() {
    timerCount.sink.add(_currentDuration); // add whatever data we want into the Sink
  }

  void dispose() {
    timerCount.close(); // close our StreamController to avoid memory leak
  }

  void _onTick(Timer timer) {
    _currentDuration = _watch.elapsed;
    updateCount();
  }

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(Duration(seconds: 1), _onTick);
    _watch.start();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _watch.stop();
    _currentDuration = _watch.elapsed;
  }

  void reset() {
    stop();
    _watch.reset();
    _currentDuration = Duration.zero;
  }
}
final Timerbloc = TimerBloc(); // create an instance of the counter bloc

