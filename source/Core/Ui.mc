import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;

// Screen metrics, theme and drawing helpers shared by all screens.
module Ui {
  const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
  const LEFT = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
  const RIGHT = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;

  var width as Number = 0;
  var height as Number = 0;
  var cx as Number = 0;
  var isRect as Boolean = false;
  // Scale for drawings designed on a 396 pixel wide screen.
  var density as Float = 1.0;

  var fg as Number = Graphics.COLOR_BLACK;
  var bg as Number = Graphics.COLOR_WHITE;

  // Small clock shown at the top of most screens.
  var clockFont as Graphics.FontType = Graphics.FONT_XTINY;
  var clockY as Float = 0.0;
  // Height of FONT_NUMBER_HOT, the base for several layouts.
  var hotHeight as Number = 0;
  // Maximum number of rows in list screens.
  var listRows as Number = 4;

  function init() as Void {
    var settings = System.getDeviceSettings();
    setSize(settings.screenWidth, settings.screenHeight);
    isRect = settings.screenShape == System.SCREEN_SHAPE_RECTANGLE;
    clockFont = Device.isEdge() ? Graphics.FONT_TINY : Graphics.FONT_XTINY;
    var divisor = Device.edge1040 || Device.edge840 ? 1.8 : Device.edge830 ? 2.1 : 2.7;
    clockY = Graphics.getFontHeight(clockFont) / divisor;
    hotHeight = Graphics.getFontHeight(Graphics.FONT_NUMBER_HOT);
    listRows = Device.isLargeEdge() ? 6 : 4;
    setTheme(Application.Storage.getValue("reversecolor"));
  }

  // Juggluco sends 1 for white on black; anything else is black on white.
  function setTheme(value as Object?) as Void {
    if (value == 1) {
      fg = Graphics.COLOR_WHITE;
      bg = Graphics.COLOR_BLACK;
    } else {
      fg = Graphics.COLOR_BLACK;
      bg = Graphics.COLOR_WHITE;
    }
    WatchUi.requestUpdate();
  }

  // The app area can be smaller than the screen (Edge devices show a title
  // bar), so the size is taken from the Dc once it is known.
  function setSize(w as Number, h as Number) as Void {
    width = w;
    height = h;
    cx = w / 2;
    density = (2.0 * w) / 396.0;
  }

  // Clears the screen in the theme colors and leaves the foreground color set.
  function begin(dc as Graphics.Dc) as Void {
    if (dc.getWidth() != width || dc.getHeight() != height) {
      setSize(dc.getWidth(), dc.getHeight());
    }
    dc.clearClip();
    dc.setColor(fg, bg);
    dc.clear();
    dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
  }

  function drawClock(dc as Graphics.Dc) as Void {
    var time = System.getClockTime();
    dc.drawText(cx, clockY, clockFont, hhmm(time.hour, time.min), CENTER);
  }

  function hhmm(hour as Number, min as Number) as String {
    return hour.format("%02d") + ":" + min.format("%02d");
  }

  // Index of the row nearest to y when `rows` rows are spread evenly over the
  // screen with their centers at (i + 1) * height / (rows + 1).
  function rowAt(y as Number, rows as Number) as Number {
    var row = (2 * y * (rows + 1) + height) / (2 * height) - 1;
    return row < 0 ? 0 : row >= rows ? rows - 1 : row;
  }

  // Ring layouts (dial, operators, months) start at 12 o'clock and run
  // clockwise. The ring is drawn slightly above the screen center.
  function ringPoint(index as Number, count as Number, radius as Numeric) as [Float, Float] {
    var angle = (Math.PI * 3) / 2 + (2 * Math.PI * index) / count;
    return [
      (Math.cos(angle) * radius + width / 2.0).toFloat(),
      (Math.sin(angle) * radius + (39.0 * height) / 80.0).toFloat(),
    ];
  }

  // Ring sector that contains the point, sector 0 centered at 12 o'clock.
  function sectorAt(x as Number, y as Number, count as Number) as Number {
    var dx = x - width / 2.0;
    var dy = y - height / 2.0;
    var degrees = 180.0 * (1.0 - Math.atan2(dx, dy) / Math.PI);
    var part = 360.0 / count;
    return ((degrees + part / 2) / part).toNumber() % count;
  }

  function isNearCenter(x as Number, y as Number, radius as Numeric) as Boolean {
    var dx = x - width / 2;
    var dy = y - height / 2;
    return dx * dx + dy * dy < radius * radius;
  }

  function push(view as WatchUi.Views, delegate as WatchUi.InputDelegates) as Void {
    WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
  }

  function pop() as Void {
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
  }

  // Current heart rate, falling back to the most recent recorded sample.
  function heartRate() as Number? {
    var info = Activity.getActivityInfo();
    if (info != null && info.currentHeartRate != null && info.currentHeartRate != 0) {
      return info.currentHeartRate;
    }
    if (Toybox has :ActivityMonitor && ActivityMonitor has :getHeartRateHistory) {
      var history = ActivityMonitor.getHeartRateHistory(1, true);
      var sample = history != null ? history.next() : null;
      if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
        return sample.heartRate;
      }
    }
    return null;
  }

  // Sensor name underlined by a bar that grows with the age of the reading.
  function drawSensorAge(dc as Graphics.Dc, x as Numeric, y as Numeric, age as Number) as Void {
    var dims = dc.getTextDimensions(Glucose.sensor, Graphics.FONT_XTINY);
    var barWidth = age <= 0 ? 0 : (dims[0] * age) / Glucose.MAX_AGE;
    dc.setColor(Graphics.COLOR_PURPLE, Graphics.COLOR_TRANSPARENT);
    dc.fillRectangle(x - dims[0] / 2, y, barWidth, dims[1]);
    dc.setColor(fg, Graphics.COLOR_TRANSPARENT);
    dc.drawText(x, y, Graphics.FONT_XTINY, Glucose.sensor, Graphics.TEXT_JUSTIFY_CENTER);
  }

  // Arrow pointing at (x, y) whose slope shows the glucose rate of change.
  function drawTrendArrow(dc as Graphics.Dc, x as Float, y as Float, scale as Float) as Void {
    if (dc has :setAntiAlias) {
      dc.setAntiAlias(true);
    }
    dc.setPenWidth((scale * 5.0).toNumber());
    var x1 = x - scale * 40.0;
    var y1 = y + Glucose.rate * scale * 30.0;
    var rx = x - x1;
    var ry = y - y1;
    var length = Math.sqrt(rx * rx + ry * ry);
    rx /= length;
    ry /= length;

    var head = scale * 12.0;
    var addX = head * rx;
    var addY = head * ry;
    var baseX = x - 2.0 * addX;
    var baseY = y - 2.0 * addY;
    var notchX = x - 1.5 * addX;
    var notchY = y - 1.5 * addY;
    dc.drawLine(x1, y1, notchX, notchY);
    dc.fillPolygon([
      [baseX + head * ry, baseY - head * rx],
      [x, y],
      [baseX - head * ry, baseY + head * rx],
      [notchX, notchY],
    ]);
  }
}
