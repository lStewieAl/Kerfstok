import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Graph of the recent glucose readings with the target range, opened by
// double tapping the home screen.
class GlucoseGraphView extends WatchUi.View {
  const WINDOW_SECONDS = 1 * 3600;
  // Grid lines every quarter, labels every half hour.
  const GRID_SECONDS = 15 * 60;
  const LABEL_SECONDS = 30 * 60;

  function initialize() {
    View.initialize();
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    Ui.drawClock(dc);
    var w = Ui.width;
    var h = Ui.height;
    var now = Time.now().value();
    var start = now - WINDOW_SECONDS;
    var times = Glucose.historyTimes;
    var values = Glucose.historyValues;

    var first = times.size();
    for (var i = 0; i < times.size(); i++) {
      if (times[i] >= start) {
        first = i;
        break;
      }
    }
    if (first >= times.size()) {
      dc.drawText(Ui.cx, h / 2, Graphics.FONT_SMALL, "No glucose data", Ui.CENTER);
      return;
    }

    var mmol = Glucose.unit == 1;
    var low = mmol ? 3.9 : 70.0;
    var high = mmol ? 10.0 : 180.0;
    var min = low;
    var max = high;
    for (var i = first; i < values.size(); i++) {
      var v = values[i];
      if (v < min) {
        min = v;
      }
      if (v > max) {
        max = v;
      }
    }
    var pad = (max - min) * 0.05;
    min -= pad;
    max += pad;

    var left = w * 0.18;
    var right = w * 0.86;
    var top = h * 0.22;
    var bottom = h * 0.72;
    var xScale = (right - left) / WINDOW_SECONDS;
    var yScale = (bottom - top) / (max - min);

    // Target range and time grid.
    dc.setPenWidth(1);
    dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    var lowY = bottom - (low - min) * yScale;
    var highY = bottom - (high - min) * yScale;
    dc.drawLine(left, lowY, right, lowY);
    dc.drawLine(left, highY, right, highY);
    var info = Gregorian.info(new Time.Moment(now), Time.FORMAT_SHORT);
    var secondsOfDay = (info.hour as Number) * 3600 + (info.min as Number) * 60 + (info.sec as Number);
    var offset = secondsOfDay % GRID_SECONDS;
    var mark = now - offset;
    var markOfDay = secondsOfDay - offset;
    var labelY = bottom + dc.getFontHeight(Graphics.FONT_XTINY) * 0.6;
    while (mark > start) {
      var x = left + (mark - start) * xScale;
      dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
      dc.drawLine(x, top, x, bottom);
      if (markOfDay % LABEL_SECONDS == 0) {
        dc.setColor(Ui.fg, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, labelY, Graphics.FONT_XTINY, Ui.hhmm(markOfDay / 3600, (markOfDay % 3600) / 60), Ui.CENTER);
      }
      mark -= GRID_SECONDS;
      markOfDay = (markOfDay - GRID_SECONDS + 24 * 3600) % (24 * 3600);
    }
    dc.setColor(Ui.fg, Graphics.COLOR_TRANSPARENT);
    var format = mmol ? "%.1f" : "%.0f";
    dc.drawText(left - 4, lowY, Graphics.FONT_XTINY, low.format(format), Ui.RIGHT);
    dc.drawText(left - 4, highY, Graphics.FONT_XTINY, high.format(format), Ui.RIGHT);

    // Readings; gaps in the stream break the line.
    if (dc has :setAntiAlias) {
      dc.setAntiAlias(true);
    }
    var pen = (Ui.density * 2.5).toNumber();
    if (pen < 2) {
      pen = 2;
    }
    dc.setPenWidth(pen);
    var prevX = 0.0;
    var prevY = 0.0;
    var prevTime = 0;
    for (var i = first; i < times.size(); i++) {
      var v = values[i];
      var x = left + (times[i] - start) * xScale;
      var y = bottom - (v - min) * yScale;
      dc.setColor(v < low ? Graphics.COLOR_RED : v > high ? Graphics.COLOR_ORANGE : Ui.fg, Graphics.COLOR_TRANSPARENT);
      var connected = i > first && times[i] - prevTime <= Glucose.STREAM_GAP;
      var nextConnected = i + 1 < times.size() && times[i + 1] - times[i] <= Glucose.STREAM_GAP;
      if (connected) {
        dc.drawLine(prevX, prevY, x, y);
      } else if (!nextConnected) {
        dc.fillCircle(x, y, pen);
      }
      prevX = x;
      prevY = y;
      prevTime = times[i];
    }
    dc.setPenWidth(1);
    dc.setColor(Ui.fg, Graphics.COLOR_TRANSPARENT);

    if (Glucose.isRecent(now)) {
      dc.drawText(Ui.cx, h * 0.86, Graphics.FONT_MEDIUM, Glucose.label(), Ui.CENTER);
    }
  }
}

class GlucoseGraphDelegate extends BaseDelegate {
  function initialize() {
    BaseDelegate.initialize();
  }

  function onTap(event as WatchUi.ClickEvent) as Boolean {
    if (!silenceAlarm()) {
      Ui.pop();
    }
    return true;
  }
}
