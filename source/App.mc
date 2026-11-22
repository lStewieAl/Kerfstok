import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

class KerfstokApp extends Application.AppBase {
  // Screens are redrawn on ticks aligned to the wall clock, so the displayed
  // minute changes promptly. The tick also repeats an active glucose alarm.
  private const TICK_SECONDS = 10;

  private var _loaded as Boolean = false;
  private var _timer as Timer.Timer?;

  function initialize() {
    AppBase.initialize();
  }

  function onStart(state as Dictionary?) as Void {
    // onStart() also runs when resuming from a suspension (for example after
    // a notification). The persisted state only has to be loaded once.
    var firstStart = !_loaded;
    if (firstStart) {
      _loaded = true;
      Device.init();
      Ui.init();
      Units.init();
      Records.load();
      Labels.load();
      Memory.load();
      Glucose.load();
      Sports.load();
    }

    // Neither the message listener nor the timer survive a suspension.
    listenForMessages();
    startTimer();
    Comm.startStream();

    if (firstStart) {
      Insulin.repairLegacyEntries();
    }
  }

  function onStop(state as Dictionary?) as Void {
    stopTimer();
    Glucose.saveHistory();
    if (state != null && state[:suspend] == true) {
      // Not a real stop: keep everything and restart the phone stream in
      // onStart(). Transmitting from this path is unreliable.
      Comm.streaming = false;
      return;
    }
    SportSession.stop();
    Comm.stopStream();
  }

  // On devices with an app switcher the app can become inactive without
  // being suspended. The BLE connection is released in that state.
  function onInactive(state as Dictionary?) as Void {
    if (Comm.streaming) {
      Comm.streamStale = true;
    }
  }

  // Restarting makes Juggluco resend everything, so it is only done when the
  // readings actually stopped arriving.
  function onActive(state as Dictionary?) as Void {
    if (!Comm.streaming || (Comm.streamStale && !Glucose.isArriving(Time.now().value()))) {
      Comm.startStream();
    } else {
      Comm.streamStale = false;
    }
  }

  function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
    return [new GlucoseView(), new GlucoseDelegate()];
  }

  function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
    Comm.handle(msg.data);
    WatchUi.requestUpdate();
  }

  function onAlign() as Void {
    _timer = new Timer.Timer();
    _timer.start(method(:onTick), TICK_SECONDS * 1000, true);
    onTick();
  }

  function onTick() as Void {
    WatchUi.requestUpdate();
    Alarm.tick();
  }

  private function listenForMessages() as Void {
    Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
  }

  private function startTimer() as Void {
    stopTimer();
    var delay = TICK_SECONDS - (System.getClockTime().sec % TICK_SECONDS);
    _timer = new Timer.Timer();
    _timer.start(method(:onAlign), delay * 1000, false);
  }

  private function stopTimer() as Void {
    if (_timer != null) {
      _timer.stop();
      _timer = null;
    }
  }
}
