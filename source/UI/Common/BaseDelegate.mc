import Toybox.Lang;
import Toybox.WatchUi;

// Input handling shared by all screens. The app is driven by touch; any
// button first silences a glucose alarm, otherwise the screen decides what it
// does (by default nothing).
class BaseDelegate extends WatchUi.BehaviorDelegate {
  function initialize() {
    BehaviorDelegate.initialize();
  }

  // A button or tap first silences a glucose alarm. Returns true when it did,
  // so the input is consumed and the screen's normal action is skipped.
  function silenceAlarm() as Boolean {
    if (!Alarm.active) {
      return false;
    }
    Alarm.silence();
    return true;
  }

  function onKey(event as WatchUi.KeyEvent) as Boolean {
    if (silenceAlarm()) {
      return true;
    }
    return onButton(event.getKey());
  }

  function onButton(key as WatchUi.Key) as Boolean {
    return true;
  }

  function onSwipe(event as WatchUi.SwipeEvent) as Boolean {
    return event.getDirection() == WatchUi.SWIPE_LEFT ? onSwipeLeft() : false;
  }

  function onSwipeLeft() as Boolean {
    return true;
  }

  function onBack() as Boolean {
    Ui.pop();
    return true;
  }
}

// Calls a method when a WatchUi.Confirmation is answered with yes.
class ConfirmDelegate extends WatchUi.ConfirmationDelegate {
  private var _onYes as Method() as Void;

  function initialize(onYes as Method() as Void) {
    ConfirmationDelegate.initialize();
    _onYes = onYes;
  }

  function onResponse(response as WatchUi.Confirm) as Boolean {
    if (response == WatchUi.CONFIRM_YES) {
      _onYes.invoke();
    }
    return true;
  }
}

function confirm(question as String, onYes as Method() as Void) as Void {
  Ui.push(new WatchUi.Confirmation(question), new ConfirmDelegate(onYes));
}
