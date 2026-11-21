import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// The records of both rings merged, newest first. Each row shows the time
// (and the date when it differs from the row above) and the label and value,
// in colors that depend on the label.
class HistoryView extends WatchUi.View {
  // Newest index per base to show at the top of the page.
  private var _top as Array<Number>;
  // Indexes per base to continue with on the next (older) page.
  private var _next as Array<Number> = [-1, -1];
  // The rows on screen: base and index of each.
  private var _shownBase as Array<Number>;
  private var _shownId as Array<Number>;
  private var _shownCount as Number = 0;

  private var _rows as Number;
  private var _laidOut as Boolean = false;
  private var _valueFont as Graphics.FontType = Graphics.FONT_TINY;
  private var _timeFont as Graphics.FontType = Graphics.FONT_XTINY;
  private var _rowHeight as Float = 0.0;
  private var _valueOffset as Float = 0.0;
  private var _raise as Float = 0.0;

  function initialize() {
    View.initialize();
    _rows = Device.edge1040 ? 8 : Device.edgeExplore2 ? 7 : Device.edge830 ? 5 : 4;
    _shownBase = new [_rows] as Array<Number>;
    _shownId = new [_rows] as Array<Number>;
    _top = [Records.ends[0] - 1, Records.ends[1] - 1];
  }

  // Positions and fonts are hand-tuned per device family.
  private function layout() as Void {
    _laidOut = true;
    var h = Ui.height;
    var clock = Ui.clockY;
    var largeFonts = Device.edge1040 || Device.edge840;
    var mediumFonts = Device.edgeExplore2 || Device.edge830;
    _valueFont = largeFonts ? Graphics.FONT_GLANCE_NUMBER : mediumFonts ? Graphics.FONT_MEDIUM : Graphics.FONT_TINY;
    _timeFont = largeFonts ? Graphics.FONT_GLANCE_NUMBER : mediumFonts ? Graphics.FONT_SMALL : Graphics.FONT_XTINY;
    _valueOffset = clock * (
      Device.edgeExplore2 || Device.edge840 || Device.fr165
        ? 0.9
        : Device.edge1040 || Device.venuSq || Device.venuSq2
        ? 0.8
        : Device.edge830
        ? 0.7
        : 0.85
    );
    _raise = Device.venuSq2
      ? h * 0.0357
      : Device.isLargeEdge()
      ? h * 0.029
      : Device.edge830
      ? h * 0.06
      : Device.venuSq
      ? h * 0.03
      : 0.0;
    var spacing = Device.venuSq || Device.venuSq2 || Device.edge830 ? 0.03 : Device.isLargeEdge() ? 0.01 : 0.0;
    _rowHeight = (h - clock) * (spacing + 1.0 / (_rows + 1));
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    if (!_laidOut) {
      layout();
    }
    Ui.drawClock(dc);
    collect(_top);

    var previousDay = null as Gregorian.Info?;
    for (var i = 0; i < _shownCount; i++) {
      var record = Records.get(_shownBase[i], _shownId[i]) as Array;
      var center = _rowHeight * (i + 1) - _raise;
      if (!Labels.isValid(record[2] as Number)) {
        dc.setColor(Graphics.COLOR_PINK, Graphics.COLOR_PURPLE);
        dc.drawText(Ui.cx, center + _valueOffset, _valueFont, "Deleted", Ui.CENTER);
        continue;
      }
      var label = record[2] as Number;
      var colors = labelColors(label);
      var day = Gregorian.info(new Time.Moment(record[0] as Number), Time.FORMAT_SHORT);
      var timeText = Ui.hhmm(day.hour, day.min);
      if (previousDay == null || previousDay.day != day.day || previousDay.month != day.month || previousDay.year != day.year) {
        timeText += " " + day.day + "-" + Dates.monthName((day.month as Number) - 1) + "-" + day.year;
        previousDay = day;
      }
      drawBand(dc, center - _valueOffset, _timeFont, timeText, colors);
      drawBand(dc, center + 2 * _valueOffset, _valueFont, Labels.names[label] + " " + (record[1] as Numeric).format("%g"), colors);
    }
  }

  // Fills the row's width with the label background behind the text.
  private function drawBand(dc as Graphics.Dc, y as Float, font as Graphics.FontType, text as String, colors as [Number, Number]) as Void {
    var height = dc.getFontHeight(font);
    dc.setColor(colors[1], colors[1]);
    dc.fillRectangle(0, y - height / 2, Ui.width, height);
    dc.setColor(colors[0], Graphics.COLOR_TRANSPARENT);
    dc.drawText(Ui.cx, y, font, text, Ui.CENTER);
  }

  // Foreground and background color for a label.
  private function labelColors(label as Number) as [Number, Number] {
    var colors = [
      Graphics.COLOR_PURPLE, Graphics.COLOR_WHITE,
      Graphics.COLOR_RED, Graphics.COLOR_BLACK,
      Graphics.COLOR_WHITE, Graphics.COLOR_DK_RED,
      Graphics.COLOR_GREEN, Graphics.COLOR_BLACK,
      Graphics.COLOR_WHITE, Graphics.COLOR_DK_BLUE,
      Graphics.COLOR_WHITE, Graphics.COLOR_BLACK,
      Graphics.COLOR_DK_BLUE, Graphics.COLOR_WHITE,
      Graphics.COLOR_ORANGE, Graphics.COLOR_BLACK,
      Graphics.COLOR_DK_GRAY, Graphics.COLOR_WHITE,
      Graphics.COLOR_WHITE, Graphics.COLOR_ORANGE,
      Graphics.COLOR_DK_GREEN, Graphics.COLOR_WHITE,
      Graphics.COLOR_WHITE, Graphics.COLOR_RED,
      Graphics.COLOR_PINK, Graphics.COLOR_BLACK,
      Graphics.COLOR_DK_RED, Graphics.COLOR_WHITE,
      Graphics.COLOR_ORANGE, Graphics.COLOR_WHITE,
      Graphics.COLOR_PINK, Graphics.COLOR_WHITE,
      Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK,
      Graphics.COLOR_RED, Graphics.COLOR_WHITE,
      Graphics.COLOR_WHITE, Graphics.COLOR_PURPLE,
      Graphics.COLOR_DK_GREEN, Graphics.COLOR_BLACK,
    ];
    var i = 2 * label;
    return i + 1 < colors.size() ? [colors[i], colors[i + 1]] : [Graphics.COLOR_BLACK, Graphics.COLOR_WHITE];
  }

  // Fills the shown rows starting at `top`, merging both rings by time.
  private function collect(top as Array<Number>) as Void {
    var cursor = [clampIndex(0, top[0]), clampIndex(1, top[1])];
    _shownCount = 0;
    while (_shownCount < _rows) {
      var newest = -1;
      var newestTime = -1;
      for (var base = 0; base < 2; base++) {
        var time = timeAtOrBefore(base, cursor);
        // Ties go to base 0.
        if (time >= 0 && time > newestTime) {
          newest = base;
          newestTime = time;
        }
      }
      if (newest < 0) {
        break;
      }
      _shownBase[_shownCount] = newest;
      _shownId[_shownCount] = cursor[newest];
      _shownCount++;
      cursor[newest]--;
    }
    _next = cursor;
  }

  // Moves cursor[base] down to the nearest record and returns its time, or
  // -1 when there is none.
  private function timeAtOrBefore(base as Number, cursor as Array<Number>) as Number {
    while (cursor[base] >= Records.first(base)) {
      var record = Records.get(base, cursor[base]);
      if (record != null) {
        return (record[0] as Numeric).toNumber();
      }
      cursor[base]--;
    }
    return -1;
  }

  private function clampIndex(base as Number, id as Number) as Number {
    return id < Records.ends[base] ? id : Records.ends[base] - 1;
  }

  // The record shown in the row nearest to y, as [base, id], or null.
  function recordAt(y as Number) as [Number, Number]? {
    var best = -1;
    var bestDistance = 0;
    for (var i = 0; i < _shownCount; i++) {
      var middle = _rowHeight * (i + 1) - _raise + _valueOffset / 2;
      var distance = (y - middle).abs();
      if (best < 0 || distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    return best < 0 ? null : [_shownBase[best], _shownId[best]];
  }

  // Older page.
  function nextPage() as Boolean {
    if (_next[0] < Records.first(0) && _next[1] < Records.first(1)) {
      return false;
    }
    _top = _next;
    WatchUi.requestUpdate();
    return true;
  }

  // Newer page: walk forward over as many records as fit on a page.
  function previousPage() as Boolean {
    var cursor = [_top[0] + 1, _top[1] + 1];
    var moved = false;
    for (var i = 0; i < _rows; i++) {
      var oldest = -1;
      var oldestTime = 0;
      for (var base = 0; base < 2; base++) {
        while (cursor[base] < Records.ends[base]) {
          var record = Records.get(base, cursor[base]);
          if (record != null) {
            var time = (record[0] as Numeric).toNumber();
            // Ties go to base 1, the reverse of collect().
            if (oldest < 0 || time <= oldestTime) {
              oldest = base;
              oldestTime = time;
            }
            break;
          }
          cursor[base]++;
        }
      }
      if (oldest < 0) {
        break;
      }
      cursor[oldest]++;
      moved = true;
    }
    _top = [cursor[0] - 1, cursor[1] - 1];
    WatchUi.requestUpdate();
    return moved;
  }

  // Jumps to the records from about a day before the bottom row.
  function dayBack() as Boolean {
    if (_next[0] < Records.first(0) && _next[1] < Records.first(1)) {
      return false;
    }
    var limit = 0x7fffffff;
    if (_shownCount > 0) {
      var last = Records.get(_shownBase[_shownCount - 1], _shownId[_shownCount - 1]);
      if (last != null) {
        limit = (last[0] as Numeric).toNumber() - 23 * 3600;
      }
    }
    var top = [_next[0], _next[1]];
    for (var base = 0; base < 2; base++) {
      while (top[base] >= Records.first(base)) {
        var record = Records.get(base, top[base]);
        if (record != null && record[0] < limit) {
          break;
        }
        top[base]--;
      }
    }
    _top = top;
    WatchUi.requestUpdate();
    return true;
  }
}

class HistoryDelegate extends BaseDelegate {
  private var _view as HistoryView;

  function initialize(view as HistoryView) {
    BaseDelegate.initialize();
    _view = view;
  }

  function onTap(event as WatchUi.ClickEvent) as Boolean {
    var shown = _view.recordAt(event.getCoordinates()[1]);
    if (shown != null) {
      var record = Records.get(shown[0], shown[1]);
      if (record != null && Labels.isValid(record[2] as Number)) {
        Ui.push(new ItemView(record), new ItemDelegate(shown[0], shown[1], record));
      }
    }
    return true;
  }

  // Any button leaves the history.
  function onButton(key as WatchUi.Key) as Boolean {
    Ui.pop();
    return true;
  }

  function onSwipeLeft() as Boolean {
    return _view.dayBack();
  }

  function onNextPage() as Boolean {
    if (!_view.nextPage()) {
      Haptics.pulse();
    }
    return true;
  }

  function onPreviousPage() as Boolean {
    _view.previousPage();
    return true;
  }

}

function openHistory() as Void {
  var view = new HistoryView();
  Ui.push(view, new HistoryDelegate(view));
}