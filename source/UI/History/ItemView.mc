import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Edits one record: tap the time, date, label or value to change it.
class ItemView extends WatchUi.View {
  private var _record as Array;

  function initialize(record as Array) {
    View.initialize();
    _record = record;
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    Ui.drawClock(dc);
    var cx = Ui.cx;
    var row = Ui.height / 5;
    var time = Gregorian.info(new Time.Moment(_record[0] as Number), Time.FORMAT_MEDIUM);

    dc.drawText((cx * 2) / 3, row, Graphics.FONT_MEDIUM, time.hour.format("%02d"), Ui.RIGHT);
    dc.drawText(cx, row, Graphics.FONT_MEDIUM, ":", Ui.CENTER);
    dc.drawText((cx * 4) / 3, row, Graphics.FONT_MEDIUM, time.min.format("%02d"), Ui.LEFT);

    dc.drawText(cx / 2, 2 * row, Graphics.FONT_TINY, time.day.toString(), Ui.RIGHT);
    dc.drawText(cx, 2 * row, Graphics.FONT_TINY, time.month.toString(), Ui.CENTER);
    dc.drawText((cx * 3) / 2, 2 * row, Graphics.FONT_TINY, time.year.toString(), Ui.LEFT);

    dc.drawText(cx / 10, 3 * row, Graphics.FONT_TINY, Labels.name(_record[2] as Number), Ui.LEFT);
    dc.drawText((cx * 19) / 10, 3 * row, Graphics.FONT_TINY, (_record[1] as Numeric).format("%g"), Ui.RIGHT);

    // Buttons: text on a filled background.
    dc.setColor(Ui.bg, Ui.fg);
    dc.drawText((cx * 2) / 3, 4 * row + 10, Graphics.FONT_TINY, "Del", Ui.CENTER);
    dc.drawText((cx * 4) / 3, 4 * row + 10, Graphics.FONT_TINY, "Save", Ui.CENTER);
  }
}

class ItemDelegate extends BaseDelegate {
  private var _base as Number;
  private var _id as Number;
  private var _record as Array;
  private var _original as Array;

  function initialize(base as Number, id as Number, record as Array) {
    BaseDelegate.initialize();
    _base = base;
    _id = id;
    _record = record;
    _original = [record[0], record[1], record[2]];
  }

  function onBack() as Boolean {
    if (isChanged()) {
      confirm("Cancel modification?", method(:close));
    } else {
      close();
    }
    return true;
  }

  // Rows: time (hour | minute), date (day | month | year),
  // label | value, and Del | Save.
  function onTap(event as WatchUi.ClickEvent) as Boolean {
    var point = event.getCoordinates();
    var x = point[0];
    switch ((point[1] * 4) / Ui.height) {
      case 0:
        if (x < Ui.cx) {
          openDial(new RecordTimeTarget(_record, :hour), "Hour");
        } else {
          openDial(new RecordTimeTarget(_record, :minute), "Minute");
        }
        break;
      case 1:
        if (x * 3 < Ui.width) {
          openDial(new RecordTimeTarget(_record, :day), "Day");
        } else if (x * 3 < 2 * Ui.width) {
          Ui.push(new MonthView(), new MonthDelegate(_record));
        } else {
          openDial(new RecordTimeTarget(_record, :year), "Year");
        }
        break;
      case 2:
        if (x < Ui.cx) {
          var view = new ListView(Labels.names, Graphics.FONT_MEDIUM, 0);
          Ui.push(view, new LabelDelegate(view, LabelDelegate.NEW_RECORD, _record));
        } else {
          openDial(new RecordValueTarget(_record), Labels.name(_record[2] as Number));
        }
        break;
      default:
        if (x < Ui.cx) {
          var question = "Delete " + Labels.name(_original[2] as Number) + " " + (_original[1] as Numeric).format("%g") + "?";
          confirm(question, method(:deleteRecord));
        } else {
          save();
        }
        break;
    }
    return true;
  }

  function close() as Void {
    Ui.pop();
  }

  function deleteRecord() as Void {
    Records.deleteRecord(_base, _id);
    Ui.pop();
  }

  function moveRecord() as Void {
    Records.moveToTime(_base, _id, _record);
    Comm.sendChanges(_base);
    Ui.pop();
  }

  private function save() as Void {
    if (!isChanged()) {
      Ui.pop();
      return;
    }
    if (!Records.isSynced(_base)) {
      Comm.requestSync();
      Haptics.triple();
      return;
    }
    if (_record[0] == _original[0]) {
      Records.update(_base, _id, _record);
      Comm.sendChanges(_base);
      Ui.pop();
    } else if (isNearbyTime()) {
      moveRecord();
    } else {
      var date = Gregorian.info(new Time.Moment(_record[0] as Number), Time.FORMAT_SHORT);
      var question = "Move to " + date.day + "-" + Dates.monthName((date.month as Number) - 1) + "-" + date.year + "?";
      confirm(question, method(:moveRecord));
    }
  }

  // False when the new time is far in the future, or older than records a
  // quarter of the ring back; such moves are confirmed first.
  private function isNearbyTime() as Boolean {
    var time = _record[0] as Number;
    if (time - Time.now().value() > 60 * 24 * 3600) {
      Haptics.ramp();
      return false;
    }
    var older = _id - maxstorage / 4;
    if (older > Records.first(_base)) {
      var other = Records.get(_base, older);
      if (other != null && other[0] > time) {
        return false;
      }
    }
    return true;
  }

  private function isChanged() as Boolean {
    for (var i = 0; i < 3; i++) {
      if (_record[i] != _original[i]) {
        return true;
      }
    }
    return false;
  }
}

// Months on a ring, November and December in the center.
class MonthView extends WatchUi.View {
  function initialize() {
    View.initialize();
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    Ui.drawClock(dc);
    var font = Device.venuSq2 ? Graphics.FONT_SMALL : Graphics.FONT_MEDIUM;
    var radius = Ui.width / 2.0 - (dc.getTextWidthInPixels(Dates.monthName(0), font) * 4) / 5.0;
    for (var i = 0; i < 10; i++) {
      var point = Ui.ringPoint(i, 10, radius);
      dc.drawText(point[0], point[1], font, Dates.monthName(i), Ui.CENTER);
    }
    dc.drawText(Ui.cx, (Ui.height * 2) / 5, font, Dates.monthName(10), Ui.CENTER);
    dc.drawText(Ui.cx, (Ui.height * 3) / 5, font, Dates.monthName(11), Ui.CENTER);
  }
}

class MonthDelegate extends BaseDelegate {
  private var _record as Array;

  function initialize(record as Array) {
    BaseDelegate.initialize();
    _record = record;
  }

  function onTap(event as WatchUi.ClickEvent) as Boolean {
    var point = event.getCoordinates();
    var month0;
    if (Ui.isNearCenter(point[0], point[1], Ui.height / 4)) {
      month0 = point[1] > Ui.height / 2 ? 11 : 10;
    } else {
      month0 = Ui.sectorAt(point[0], point[1], 10);
    }
    var time = Dates.withField(_record[0] as Number, :month, month0 + 1);
    if (time != null) {
      _record[0] = time;
    }
    Ui.pop();
    return true;
  }
}
