import Toybox.Application;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// The latest glucose reading streamed by Juggluco.
module Glucose {
  // Seconds a reading stays on screen.
  const MAX_AGE = 330;

  var text as String = " ";
  var time as Number = 0;
  var rate as Float = 0.0;
  var sensor as String = "";
  // 0: mg/dL, 1: mmol/L.
  var unit as Number = 0;
  // High (1) or low (-1) glucose alarm, shown instead of the trend arrow.
  var alarmLevel as Number = 0;

  function load() as Void {
    var stored = Application.Storage.getValue("glunits");
    unit = stored instanceof Number && stored == 1 ? 1 : 0;
  }

  function setUnit(value as Object?) as Void {
    var newUnit = value == 1 ? 1 : 0;
    if (newUnit != unit) {
      unit = newUnit;
      Application.Storage.setValue("glunits", unit);
    }
  }

  function age(now as Number) as Number {
    return now - time;
  }

  function isRecent(now as Number) as Boolean {
    return age(now) < MAX_AGE;
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
