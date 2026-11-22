import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// The latest glucose reading streamed by Juggluco.
module Glucose {
  // Seconds a reading stays on screen.
  const MAX_AGE = 330;
  // Juggluco sends a reading every minute; a longer gap means the stream
  // stopped.
  const STREAM_GAP = 180;

  var text as String = " ";
  var time as Number = 0;
  var rate as Float = 0.0;
  var sensor as String = "";
  // 0: mg/dL, 1: mmol/L.
  var unit as Number = 0;
  // High (1) or low (-1) glucose alarm, shown instead of the trend arrow.
  var alarmLevel as Number = 0;

  // Recent readings for the graph, oldest first, in the current unit.
  // Juggluco sends one reading per minute, so this covers about 1 hour.
  const HISTORY_SIZE = 60;
  const MGDL_PER_MMOL = 18.0182;
  var historyTimes as Array<Number> = [] as Array<Number>;
  var historyValues as Array<Float> = [] as Array<Float>;

  function load() as Void {
    var stored = Application.Storage.getValue("glunits");
    unit = stored instanceof Number && stored == 1 ? 1 : 0;
    loadHistory();
  }

  function setUnit(value as Object?) as Void {
    var newUnit = value == 1 ? 1 : 0;
    if (newUnit != unit) {
      unit = newUnit;
      Application.Storage.setValue("glunits", unit);
      var factor = unit == 1 ? 1.0 / MGDL_PER_MMOL : MGDL_PER_MMOL;
      for (var i = 0; i < historyValues.size(); i++) {
        historyValues[i] = historyValues[i] * factor;
      }
    }
  }

  // Readings older than the newest one are ignored.
  function addToHistory(readingTime as Number, value as Float) as Void {
    var count = historyTimes.size();
    if (count > 0 && readingTime <= historyTimes[count - 1]) {
      return;
    }
    historyTimes.add(readingTime);
    historyValues.add(value);
    if (count >= HISTORY_SIZE) {
      historyTimes = historyTimes.slice(1, null);
      historyValues = historyValues.slice(1, null);
    }
  }

  function saveHistory() as Void {
    Application.Storage.setValue("gluhistory", [historyTimes, historyValues] as Array<Application.PropertyValueType>);
  }

  function loadHistory() as Void {
    historyTimes = [] as Array<Number>;
    historyValues = [] as Array<Float>;
    var stored = Application.Storage.getValue("gluhistory");
    if (!(stored instanceof Array) || stored.size() != 2) {
      return;
    }
    var times = stored[0];
    var values = stored[1];
    if (!(times instanceof Array) || !(values instanceof Array) || times.size() != values.size()) {
      return;
    }
    for (var i = 0; i < times.size(); i++) {
      var t = times[i];
      var v = values[i];
      if (t instanceof Number && isNumeric(v)) {
        addToHistory(t, (v as Numeric).toFloat());
      }
    }
  }

  function age(now as Number) as Number {
    return now - time;
  }

  function isRecent(now as Number) as Boolean {
    return age(now) < MAX_AGE;
  }

  function isArriving(now as Number) as Boolean {
    return age(now) < STREAM_GAP;
  }

  // Short form for small displays, with the alarm marker.
  function label() as String {
    return text + (alarmLevel < 0 ? ">" : alarmLevel > 0 ? "<" : "");
  }

  // Handles [sensor, unixTime, value, rate, alarmState, unit?]. The alarm
  // state holds the alarm type in bits 0-2, bit 3 when the watch should
  // vibrate, and bit 4 when it should keep vibrating until acknowledged.
  function update(data as Array<Object?>) as Void {
    if (
      data.size() < 5 ||
      !isNumeric(data[1]) ||
      !isNumeric(data[2]) ||
      !isNumeric(data[3]) ||
      !(data[4] instanceof Number)
    ) {
      return;
    }
    var name = data[0];
    sensor = name instanceof String ? name : "";
    time = (data[1] as Numeric).toNumber();
    rate = (data[3] as Numeric).toFloat();
    if (data.size() >= 6 && isNumeric(data[5])) {
      setUnit(data[5]);
    }
    var value = (data[2] as Numeric).toFloat();
    text = value.format(unit == 1 ? "%.1f" : "%.0f");
    addToHistory(time, value);

    var alarmState = data[4] as Number;
    if (alarmState == 0) {
      Alarm.clear();
    } else if ((alarmState & 0x08) != 0) {
      if ((alarmState & 0x10) != 0) {
        Alarm.start();
      } else {
        Haptics.alarm();
      }
    }
    var type = alarmState & 0x07;
    alarmLevel = type == 4 ? 1 : type == 5 ? -1 : 0;

    SportSession.recordGlucose(value, time);
    WatchUi.requestUpdate();
  }
}
