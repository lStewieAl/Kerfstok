import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Home screen: time, date, glucose with trend, insulin on board, battery and
// heart rate.
class GlucoseView extends WatchUi.View {
  private var _heartFont as Graphics.FontType = Graphics.FONT_NUMBER_MEDIUM;
  private var _glucoseFont as Graphics.FontType = Graphics.FONT_SYSTEM_NUMBER_THAI_HOT;
  private var _heartY as Float = 0.0;
  private var _timeY as Float = 0.0;
  private var _dateY as Float = 0.0;
  private var _arrowX as Float = 0.0;
  private var _laidOut as Boolean = false;

  function initialize() {
    View.initialize();
  }

  // Positions are hand-tuned per device family.
  private function layout() as Void {
    _laidOut = true;
    var w = Ui.width;
    var h = Ui.height;
    var hot = Ui.hotHeight;
    _heartFont = Device.fenixE || Device.fenix8 ? Graphics.FONT_NUMBER_MILD : Graphics.FONT_NUMBER_MEDIUM;
    _glucoseFont = Device.fenixE
      ? Graphics.FONT_SYSTEM_NUMBER_MEDIUM
      : Device.fenix8
      ? Graphics.FONT_SYSTEM_NUMBER_HOT
      : Graphics.FONT_SYSTEM_NUMBER_THAI_HOT;
    _heartY = h - Graphics.getFontHeight(_heartFont) * 0.88;
    _arrowX = Device.venuSq2 ? w * 0.22 : w * 0.3;
    if (Ui.isRect) {
      _timeY = Device.isEdge() ? 0.0 : -hot * 0.15;
    } else {
      _timeY = w > 340 || Device.fr965 ? hot * 0.14 : 0.0;
    }
    _dateY = (Device.isLargeEdge() ? h * 0.05 : 0) + hot * 0.8 + _timeY;
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    if (!_laidOut) {
      layout();
    }
    var w = Ui.width;
    var h = Ui.height;
    var now = Time.now().value();
    var today = Gregorian.info(new Time.Moment(now), Time.FORMAT_MEDIUM);

    dc.drawText(Ui.cx * 0.99, _timeY, Graphics.FONT_NUMBER_HOT, Ui.hhmm(today.hour, today.min), Graphics.TEXT_JUSTIFY_CENTER);
    dc.drawText(
      Ui.cx,
      _dateY,
      Graphics.FONT_TINY,
      today.day_of_week + " " + today.day + " " + today.month,
      Graphics.TEXT_JUSTIFY_CENTER
    );
    var battery = System.getSystemStats().battery;
    dc.drawText(w * 0.95, h * (Device.fr965 ? 0.37 : 0.33), Graphics.FONT_XTINY, battery.format("%.0f") + "%", Ui.RIGHT);

    if (Glucose.isRecent(now)) {
      drawGlucose(dc, now);
    }
    drawInsulin(dc, now);

    var heartRate = Ui.heartRate();
    if (heartRate != null) {
      dc.drawText(Ui.cx, _heartY, _heartFont, heartRate.format("%d"), Graphics.TEXT_JUSTIFY_CENTER);
    }
  }

  private function drawGlucose(dc as Graphics.Dc, now as Number) as Void {
    var w = Ui.width;
    var y = Ui.height * 0.58;
    var x = w * 0.615;
    dc.drawText(x, y, _glucoseFont, Glucose.text, Ui.CENTER);
    if (Glucose.alarmLevel != 0) {
      dc.drawText(w * 0.9, y, Graphics.FONT_LARGE, Glucose.alarmLevel < 0 ? ">" : "<", Ui.RIGHT);
    } else {
      Ui.drawTrendArrow(dc, _arrowX, y, Ui.density * 0.95);
    }
    Ui.drawSensorAge(dc, x, y + Ui.height * 0.12, Glucose.age(now));
  }

  private function drawInsulin(dc as Graphics.Dc, now as Number) as Void {
    Insulin.refresh(now);
    if (Insulin.onBoard <= 0.05) {
      return;
    }
    var x = Ui.width * 0.975;
    var y = Ui.height * (Device.fr965 ? 0.43 : 0.41);
    dc.drawText(x, y, Graphics.FONT_XTINY, Insulin.onBoard.format("%.2f") + " U", Ui.RIGHT);
    // Expected change over the next minutes; hidden when it rounds to 0.00.
    var change = Insulin.change;
    if (change < -0.005 || change > 0.005) {
      var lineHeight = dc.getFontHeight(Graphics.FONT_XTINY) * 1.1;
      dc.drawText(x, y + lineHeight, Graphics.FONT_XTINY, change.format("%.2f") + " U", Ui.RIGHT);
    }
  }
}

class GlucoseDelegate extends BaseDelegate {
  function initialize() {
    BaseDelegate.initialize();
  }

  function onBack() as Boolean {
    Ui.push(new AskView("", "Quit?"), new QuitDelegate());
    return true;
  }

  function onButton(key as WatchUi.Key) as Boolean {
    if (!askStopSport() && key == WatchUi.KEY_ENTER) {
      openMenu();
    }
    return true;
  }

  function onTap(event as WatchUi.ClickEvent) as Boolean {
    if (silenceAlarm()) {
      return true;
    }
    if (Device.isEdge()) {
      openMenu();
    }
    return true;
  }

  function onMenu() as Boolean {
    openMenu();
    return true;
  }

  private function openMenu() as Void {
    Ui.push(new MainMenuView(), new MainMenuDelegate());
  }

  function onSwipeLeft() as Boolean {
    return false;
  }

  function onNextPage() as Boolean {
    return true;
  }

  function onPreviousPage() as Boolean {
    return true;
  }
}
