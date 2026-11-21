import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Sets up a recording: autolap distance, sport and sub sport. GPS starts
// searching as soon as this screen opens.
class SportStartView extends WatchUi.View {
  private var _gpsSignaled as Boolean = false;

  function initialize() {
    View.initialize();
  }

  function onHide() as Void {
    Sports.save();
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    Ui.drawClock(dc);
    var row = Ui.height / 5;
    var lap = Sports.lapLength;
    var lapText = lap == 0.0 ? "no autolap" : (lap * Units.distanceFactor).format("%.1f") + " " + Units.distanceUnit + " laps";
    dc.drawText(Ui.cx, row, Graphics.FONT_TINY, lapText, Ui.CENTER);
    dc.drawText(Ui.cx, 2 * row, Graphics.FONT_TINY, Sports.name(Sports.current()), Ui.CENTER);
    if (Sports.subIndex >= 0) {
      dc.drawText(Ui.cx, 3 * row, Graphics.FONT_TINY, Sports.subSportName(Sports.subSportId()), Ui.CENTER);
    }
    if (Glucose.isRecent(Time.now().value())) {
      dc.drawText(0, Ui.height * 0.5, Graphics.FONT_XTINY, Glucose.label(), Ui.LEFT);
    }
    if (SportSession.position != null) {
      dc.drawText(Ui.width * 0.3, 4 * row + 10, Ui.clockFont, "GPS", Ui.RIGHT);
      if (!_gpsSignaled) {
        _gpsSignaled = true;
        Haptics.ramp();
      }
    }
    dc.drawText(Ui.width * 0.6, 4 * row + 10, Graphics.FONT_TINY, "Start", Ui.LEFT);
  }
}

// Rows: autolap distance, sport, sub sport, and Start on the right.
class SportStartDelegate extends BaseDelegate {
  function initialize() {
    BaseDelegate.initialize();
    SportSession.enableGps();
  }

  function onBack() as Boolean {
    if (!SportSession.isActive()) {
      SportSession.disableGps();
    }
    Ui.pop();
    return true;
  }

  function onTap(event as WatchUi.ClickEvent) as Boolean {
    var point = event.getCoordinates();
    switch ((point[1] * 4) / Ui.height) {
      case 0:
        openDial(new LapLengthTarget(), Units.distanceUnit + " (0=no)");
        break;
      case 1:
        var sports = new ListView(Sports.names(), Graphics.FONT_XTINY, 0);
        Ui.push(sports, new SportPickerDelegate(sports));
        break;
      case 2:
        if (Sports.subIndex >= 0) {
          var subSports = new ListView(Sports.subSportNames(), Graphics.FONT_MEDIUM, Sports.subIndex);
          Ui.push(subSports, new SubSportPickerDelegate(subSports));
        }
        break;
      default:
        if (point[0] * 2 >= Ui.width) {
          start();
        }
        break;
    }
    return true;
  }

  // Any button starts the recording.
  function onButton(key as WatchUi.Key) as Boolean {
    start();
    return true;
  }

  function onNextPage() as Boolean {
    return true;
  }

  function onPreviousPage() as Boolean {
    return true;
  }

  private function start() as Void {
    SportSession.start();
    WatchUi.switchToView(new SportView(), new SportDelegate(), WatchUi.SLIDE_IMMEDIATE);
  }
}

class SportPickerDelegate extends ListDelegate {
  function initialize(view as ListView) {
    ListDelegate.initialize(view);
  }

  function onItem(index as Number) as Void {
    Sports.select(Sports.order[index]);
    Ui.pop();
  }
}

class SubSportPickerDelegate extends ListDelegate {
  function initialize(view as ListView) {
    ListDelegate.initialize(view);
  }

  function onItem(index as Number) as Void {
    Sports.selectSubSport(index);
    Ui.pop();
  }
}
