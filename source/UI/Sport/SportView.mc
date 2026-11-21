import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Shown while recording: time, glucose, speed, distance, last lap and heart
// rate.
class SportView extends WatchUi.View {
  private var _timeFont as Graphics.FontType = Graphics.FONT_NUMBER_MILD;
  private var _speedFont as Graphics.FontType = Graphics.FONT_NUMBER_HOT;
  private var _glucoseFont as Graphics.FontType = Graphics.FONT_SYSTEM_NUMBER_THAI_HOT;
  private var _statusFont as Graphics.FontType = Graphics.FONT_LARGE;
  private var _lapFont as Graphics.FontType = Graphics.FONT_NUMBER_MEDIUM;
  private var _speedUnitJustify as Number = Graphics.TEXT_JUSTIFY_RIGHT;
  private var _timeY as Float = 0.0;
  private var _glucoseY as Float = 0.0;
  private var _arrowY as Float = 0.0;
  private var _markerY as Number = 0;
  private var _sensorX as Float = 0.0;
  private var _sensorY as Float = 0.0;
  private var _speedY as Float = 0.0;
  private var _speedUnitY as Float = 0.0;
  private var _distanceY as Float = 0.0;
  private var _distanceUnitY as Float = 0.0;
  private var _lapNameY as Float = 0.0;
  private var _lapTimeY as Float = 0.0;
  private var _heartY as Float = 0.0;

  private var _laidOut as Boolean = false;

  function initialize() {
    View.initialize();
  }

  // Positions and fonts are hand-tuned per device family.
  private function layout() as Void {
    _laidOut = true;
    var h = Ui.height;
    var edge = Device.isEdge();
    var compact = Device.venuSq2 || Device.fenix8 || Device.fenixE;

    _timeFont = compact || Device.fr965 ? Graphics.FONT_LARGE : Graphics.FONT_NUMBER_MILD;
    _speedFont = compact || Device.fenix7 ? Graphics.FONT_NUMBER_MEDIUM : Graphics.FONT_NUMBER_HOT;
    _glucoseFont = compact || Device.fr965 ? Graphics.FONT_SYSTEM_NUMBER_HOT : Graphics.FONT_SYSTEM_NUMBER_THAI_HOT;
    _statusFont = compact ? Graphics.FONT_MEDIUM : Graphics.FONT_LARGE;
    _lapFont = Device.fenix7 ? Graphics.FONT_LARGE : Graphics.FONT_NUMBER_MEDIUM;
    _speedUnitJustify = Device.fenix7 || Device.venuSq2 || Device.venuSq ? Ui.RIGHT : Graphics.TEXT_JUSTIFY_RIGHT;

    var timeHeight = Graphics.getFontHeight(_timeFont);
    var glucoseHeight = Graphics.getFontHeight(_glucoseFont);
    var offset = Device.venuSq2 ? 10 : 0;

    _timeY = Device.isLargeEdge() ? 0.0 : Device.edge830 || Device.fr965 ? -timeHeight * 0.06 : -timeHeight * 0.12;
    _glucoseY = (edge ? h * 0.065 : Device.fr965 ? h * 0.02 : 0) + timeHeight * 0.78 - glucoseHeight * 0.2;
    _arrowY = _glucoseY + glucoseHeight * 0.54;
    _markerY = timeHeight;
    var belowGlucose = _glucoseY + glucoseHeight * 0.8;
    _sensorX = Ui.width * 0.57;
    _sensorY = Device.edge830 || Device.edge1040 ? _glucoseY + glucoseHeight * 0.95 : belowGlucose - offset;

    _speedY = Device.fenix8
      ? h * 0.56
      : Device.fenix7
      ? h * 0.61
      : Device.venuSq2
      ? h * 0.65
      : edge
      ? h * 0.48
      : Device.fr965
      ? h * 0.57
      : h * 0.59;
    _speedUnitY = Device.marq2
      ? h * 0.42
      : Device.fenix7
      ? h * 0.5
      : Device.venuSq2
      ? h * 0.51
      : Device.venuSq
      ? h * 0.45
      : Device.edgeExplore2
      ? h * 0.37
      : Device.mk3
      ? h * 0.41
      : belowGlucose + (Device.venu ? 0 : h * 0.03);

    _distanceY = Device.venuSq || Device.venuSq2 ? h * 0.65 : Device.fenix7 ? h * 0.635 : edge ? h * 0.7 : h * 0.59;
    _distanceUnitY = Device.fenix7 ? h * 0.64 : Device.edgeExplore2 ? h * 0.67 : h * 0.65;

    var lapOffset = offset - h * 0.05;
    _lapNameY = Device.venuSq2
      ? belowGlucose + lapOffset + h * 0.01
      : Device.isLargeEdge()
      ? h * 0.47
      : Device.edge830
      ? h * 0.45
      : belowGlucose + offset + h * 0.01;
    _lapTimeY = Device.fenix8
      ? h * 0.54
      : Device.venuSq2
      ? lapOffset + h * 0.6
      : Device.fr965
      ? h * 0.52
      : Device.edgeExplore2
      ? h * 0.57
      : offset + h * 0.57;

    _heartY = h - timeHeight * 0.88;
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    if (!_laidOut) {
      layout();
    }
    var w = Ui.width;
    var h = Ui.height;
    var now = Time.now().value();
    var today = Gregorian.info(new Time.Moment(now), Time.FORMAT_SHORT);
    dc.drawText(Ui.cx, _timeY, _timeFont, Ui.hhmm(today.hour, today.min), Graphics.TEXT_JUSTIFY_CENTER);

    if (Glucose.isRecent(now)) {
      Ui.drawSensorAge(dc, _sensorX, _sensorY, Glucose.age(now));
      dc.drawText(w * 0.6, _glucoseY, _glucoseFont, Glucose.text, Graphics.TEXT_JUSTIFY_CENTER);
      if (Glucose.alarmLevel != 0) {
        dc.drawText(w * 0.9, _markerY, Graphics.FONT_LARGE, Glucose.alarmLevel < 0 ? ">" : "<", Graphics.TEXT_JUSTIFY_RIGHT);
      } else {
        Ui.drawTrendArrow(dc, w * 0.3, _arrowY, Ui.density * 0.7);
      }
    }

    var position = SportSession.position;
    var speed = position != null ? position.speed : null;
    if (speed != null) {
      dc.drawText(w * 0.99, _speedUnitY, Graphics.FONT_XTINY, Units.speedUnit, _speedUnitJustify);
      dc.drawText(w * 0.98, _speedY, _speedFont, (speed * Units.speedFactor).format("%.0f"), Ui.RIGHT);
    } else {
      var status = SportSession.isActive() ? "Waiting for GPS" : "Finished";
      dc.drawText(Ui.cx, h * 0.54, _statusFont, status, Ui.CENTER);
    }

    var activity = Activity.getActivityInfo();
    var distance = activity != null ? activity.elapsedDistance : null;
    if (distance != null) {
      dc.drawText(w * 0.13, _distanceY, _speedFont, (distance * Units.distanceFactor).format("%.1f"), Graphics.TEXT_JUSTIFY_LEFT);
      if (Units.showDistanceUnit) {
        dc.drawText(w * 0.13, _distanceUnitY, Graphics.FONT_XTINY, Units.distanceUnit, Graphics.TEXT_JUSTIFY_RIGHT);
      }
    }

    if (now < SportSession.lapShownUntil) {
      dc.drawText(w * 0.04, _lapNameY, Graphics.FONT_XTINY, SportSession.lapName, Graphics.TEXT_JUSTIFY_LEFT);
      dc.drawText(0, _lapTimeY, _lapFont, SportSession.lapTime, Ui.LEFT);
    }

    var heartRate = Ui.heartRate();
    if (heartRate != null) {
      dc.drawText(Ui.cx, _heartY, _timeFont, heartRate.format("%d"), Graphics.TEXT_JUSTIFY_CENTER);
    }
  }
}

// Menu, or two taps within two seconds, marks a lap. Any button pauses and
// asks whether to stop. Next page shows more measurements.
class SportDelegate extends BaseDelegate {
  private var _lastTap as Number = 0;

  function initialize() {
    BaseDelegate.initialize();
  }

  function onMenu() as Boolean {
    SportSession.manualLap();
    return true;
  }

  function onTap(event as WatchUi.ClickEvent) as Boolean {
    var now = Time.now().value();
    if (now - _lastTap <= 2) {
      SportSession.manualLap();
      _lastTap = 0;
    } else {
      _lastTap = now;
    }
    return true;
  }

  function onButton(key as WatchUi.Key) as Boolean {
    askStopSport();
    return true;
  }

  function onSwipeLeft() as Boolean {
    return false;
  }

  function onNextPage() as Boolean {
    var view = new MeasureView();
    Ui.push(view, new MeasureDelegate(view));
    return true;
  }

  function onPreviousPage() as Boolean {
    Haptics.bump();
    return true;
  }
}

// Activity measurements, a page of label and value pairs at a time.
class MeasureView extends WatchUi.View {
  private var _first as Number = 0;
  private var _next as Number = 0;
  private var _pageStarts as Array<Number> = [];

  function initialize() {
    View.initialize();
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    var time = System.getClockTime();
    dc.drawText(Ui.cx, Ui.clockY, Ui.clockFont, Ui.hhmm(time.hour, time.min) + ":" + time.sec.format("%02d"), Ui.CENTER);

    _next = _first;
    var info = Activity.getActivityInfo();
    if (info == null) {
      return;
    }
    var labels = Measures.labels();
    var rows = Ui.listRows;
    var slot = Ui.height / (2 * rows + 1);
    for (var row = 0; row < rows && _next < labels.size(); _next++) {
      var value = Measures.value(info, _next);
      if (value != null) {
        dc.drawText(Ui.cx, slot * (2 * row + 1), Graphics.FONT_XTINY, labels[_next], Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(Ui.cx, slot * (2 * row + 2.4), Graphics.FONT_NUMBER_MEDIUM, value, Ui.CENTER);
        row++;
      }
    }
  }

  function nextPage() as Boolean {
    if (_next >= Measures.labels().size()) {
      return false;
    }
    _pageStarts.add(_first);
    _first = _next;
    WatchUi.requestUpdate();
    return true;
  }

  function previousPage() as Boolean {
    var count = _pageStarts.size();
    if (count == 0) {
      return false;
    }
    _first = _pageStarts[count - 1];
    _pageStarts = _pageStarts.slice(0, count - 1);
    WatchUi.requestUpdate();
    return true;
  }
}

class MeasureDelegate extends SportDelegate {
  private var _view as MeasureView;

  function initialize(view as MeasureView) {
    SportDelegate.initialize();
    _view = view;
  }

  function onNextPage() as Boolean {
    if (!_view.nextPage()) {
      Haptics.bump();
    }
    return true;
  }

  // Leaves at the first page.
  function onPreviousPage() as Boolean {
    if (!_view.previousPage()) {
      Ui.pop();
    }
    return true;
  }
}
