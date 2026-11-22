import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// A yes/no question with the glucose value still visible.
class AskView extends WatchUi.View {
  private var _comment as String;
  private var _question as String;

  function initialize(comment as String, question as String) {
    View.initialize();
    _comment = comment;
    _question = question;
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    Ui.drawClock(dc);
    var w = Ui.width;
    var h = Ui.height;
    if (Glucose.isRecent(Time.now().value())) {
      dc.drawText(w * 0.95, h * 0.35, Graphics.FONT_XTINY, Glucose.label(), Ui.RIGHT);
    }
    dc.drawText(Ui.cx, h * 0.2, Graphics.FONT_LARGE, _comment, Ui.CENTER);
    dc.drawText(Ui.cx, h * 0.5, Graphics.FONT_LARGE, _question, Ui.CENTER);
    dc.drawText(w * 0.4, h * 0.8, Graphics.FONT_LARGE, "No", Ui.RIGHT);
    dc.drawText(w * 0.6, h * 0.8, Graphics.FONT_LARGE, "Yes", Ui.LEFT);
  }
}

// Back (or swipe right) answers yes; next page answers no. Taps on the lower half pick the side tapped.
// Subclasses implement onAnswer().
class AskDelegate extends BaseDelegate {
  function initialize() {
    BaseDelegate.initialize();
  }

  function onAnswer(yes as Boolean) as Void {}

  function onBack() as Boolean {
    answer(true);
    return true;
  }

  function onNextPage() as Boolean {
    answer(false);
    return true;
  }

  function onPreviousPage() as Boolean {
    return true;
  }

  function onTap(event as WatchUi.ClickEvent) as Boolean {
    var point = event.getCoordinates();
    if (point[1] * 2 > Ui.height) {
      answer(point[0] * 2 > Ui.width);
    }
    return true;
  }

  private function answer(yes as Boolean) as Void {
    Ui.pop();
    onAnswer(yes);
  }
}

class StopSportDelegate extends AskDelegate {
  function initialize() {
    AskDelegate.initialize();
  }

  function onAnswer(yes as Boolean) as Void {
    if (yes) {
      SportSession.stop();
    } else {
      SportSession.resume();
    }
  }
}

// Any button pauses a recording and asks whether to stop it.
// Returns false when nothing is being recorded.
function askStopSport() as Boolean {
  if (!SportSession.isRecording()) {
    return false;
  }
  SportSession.pause();
  Ui.push(new AskView("Paused", "Stop " + Sports.name(Sports.current()) + "?"), new StopSportDelegate());
  return true;
}
