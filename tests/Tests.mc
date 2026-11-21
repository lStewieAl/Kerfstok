import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

// Unit tests, run in the simulator:
//   monkeyc --unit-test ... -o kerfstok-test.prg
//   monkeydo kerfstok-test.prg <device> /t

(:test)
function calcEvaluatesExpressions(logger as Logger) as Boolean {
  var cases = [
    ["1+2*3", "7"],
    ["(1+2)*3", "9"],
    ["2x3", "6"],
    ["-2^2", "4"],
    ["2^3^2", "64"],
    ["10/4", "2.5"],
    ["3--2", "5"],
    ["-(2+3)", "-5"],
    [".5", "0.5"],
    ["5.", "5"],
    ["((7))", "7"],
    ["1/3", "0.333333"],
    ["100/3", "33.333333"],
    ["1234567.5", "1234567.5"],
    ["0.1+0.2", "0.3"],
    ["99999999999", "99999999999"],
  ];
  for (var i = 0; i < cases.size(); i++) {
    var value = Calc.evaluate(cases[i][0]);
    var text = value == null ? "null" : Calc.format(value);
    if (!text.equals(cases[i][1])) {
      logger.error(cases[i][0] + " gave " + text);
      return false;
    }
  }
  return true;
}

(:test)
function calcRejectsInvalidExpressions(logger as Logger) as Boolean {
  var cases = ["", ".", "1+", "1/0", "2(3)", "1.5.3", "(1", "1)", "+1", "*2", "^", "C"];
  for (var i = 0; i < cases.size(); i++) {
    if (Calc.evaluate(cases[i]) != null) {
      logger.error(cases[i] + " was accepted");
      return false;
    }
  }
  return true;
}

(:test)
function entryAddsOneDecimalPointPerNumber(logger as Logger) as Boolean {
  var entry = new Entry();
  entry.addPoint();
  entry.append("5");
  entry.addPoint();
  entry.append("+2");
  entry.addPoint();
  entry.addPoint();
  return entry.text.equals(".5+2.");
}

(:test)
function entryRemembersTextOncePerBackspaceRun(logger as Logger) as Boolean {
  var entry = new Entry();
  entry.append("123");
  entry.backspace();
  entry.backspace();
  entry.append("4");
  entry.backspace();
  Test.assertEqual(entry.text, "1");
  Test.assertEqual(entry.history.size(), 2);
  return entry.history[0].equals("123") && entry.history[1].equals("14");
}

(:test)
function entryLimitsLength(logger as Logger) as Boolean {
  var entry = new Entry();
  for (var i = 0; i < Entry.MAX_LENGTH; i++) {
    entry.append("1");
  }
  return !entry.append("1") && entry.length() == Entry.MAX_LENGTH;
}

(:test)
function datesReplaceLocalFields(logger as Logger) as Boolean {
  // 2026-01-31 10:15 local.
  var time = Dates.calendarMoment(2026, 1, 31, 10, 15);
  time = time + (time - localCalendarMoment(time));
  var info = Dates.localInfo(time);
  Test.assertEqual(info.hour, 10);
  Test.assertEqual(info.min, 15);

  info = Dates.localInfo(Dates.withField(time, :hour, 23) as Number);
  Test.assertEqual(info.hour, 23);
  Test.assertEqual(info.min, 15);
  info = Dates.localInfo(Dates.withField(time, :minute, 0) as Number);
  Test.assertEqual(info.hour, 10);
  Test.assertEqual(info.min, 0);
  // Jan 31 to February: the day moves to the last day of the month.
  info = Dates.localInfo(Dates.withField(time, :month, 2) as Number);
  Test.assertEqual(info.month, 2);
  Test.assertEqual(info.day, 28);
  info = Dates.localInfo(Dates.withField(time, :year, 28) as Number);
  Test.assertEqual(info.year, 2028);
  Test.assertEqual(info.day, 31);

  return (
    Dates.withField(time, :hour, 24) == null &&
    Dates.withField(time, :minute, 60) == null &&
    Dates.withField(time, :day, 32) == null &&
    Dates.withField(time, :month, 13) == null &&
    Dates.withField(time, :year, 1969) == null
  );
}

(:test)
function localCalendarMoment(time as Number) as Number {
  var info = Dates.localInfo(time);
  return Dates.calendarMoment(info.year as Number, info.month as Number, info.day as Number, info.hour, info.min);
}

(:test)
function datesKnowMonthLengths(logger as Logger) as Boolean {
  return (
    Dates.daysInMonth(2, 2024) == 29 &&
    Dates.daysInMonth(2, 2026) == 28 &&
    Dates.daysInMonth(2, 2000) == 29 &&
    Dates.daysInMonth(2, 2100) == 28 &&
    Dates.daysInMonth(4, 2026) == 30 &&
    Dates.daysInMonth(12, 2026) == 31
  );
}

(:test)
function resetRecords() as Void {
  Application.Storage.clearValues();
  Records.ends = [0, 0];
  Records.lowest = [0, 0];
}

(:test)
function recordsAddAndMoveKeepTimeOrder(logger as Logger) as Boolean {
  resetRecords();
  Records.add([100, 1.0, 0]);
  Records.add([200, 2.0, 0]);
  Records.add([300, 3.0, 0]);
  Test.assertEqual(Records.ends[0], 3);

  // Move the newest record before the oldest.
  var record = Records.get(0, 2) as Array;
  record[0] = 50;
  Records.moveToTime(0, 2, record);
  var times = [];
  for (var i = 0; i < 3; i++) {
    times.add((Records.get(0, i) as Array)[0] as Number);
  }
  Test.assertEqual(times.toString(), "[50, 100, 200]");
  Test.assert(Records.lowest[0] == 0);
  return true;
}

(:test)
function recordsDeleteNewestShrinksRing(logger as Logger) as Boolean {
  resetRecords();
  Records.add([100, 1.0, 0]);
  Records.add([200, 2.0, 0]);
  Records.add([300, 3.0, 0]);
  Records.deleteRecord(0, 1);
  Test.assertEqual(Records.ends[0], 3);
  Records.deleteRecord(0, 2);
  // Index 1 was already empty, so the ring ends after index 0.
  Test.assertEqual(Records.ends[0], 1);
  Records.removeRange(0, 0, 1);
  Test.assertEqual(Records.ends[0], 0);
  // An empty range from Juggluco deletes nothing.
  Records.add([400, 4.0, 0]);
  Records.removeRange(0, 1, 1);
  return Records.get(0, 0) != null;
}

(:test)
function recordsRefuseWritesWhileUnsynced(logger as Logger) as Boolean {
  resetRecords();
  Records.lowest = [null, null];
  var added = Records.add([100, 1.0, 0]);
  Records.lowest = [0, 0];
  return !added && Records.ends[0] == 0;
}

(:test)
function recordsStoreBatchFromPhone(logger as Logger) as Boolean {
  resetRecords();
  Test.assertEqual(Records.storeBatch(1, 0, 2, [[100, 1, 0], null]), true);
  Test.assertEqual(Records.storeBatch(1, 2, 5, [[100, 1, 0]]), false);
  Test.assertEqual(Records.ends[1], 2);
  Test.assert(Records.lowest[1] == 2);
  return Records.get(1, 0) != null && Records.get(1, 1) == null;
}

(:test)
function recordsWrapAround(logger as Logger) as Boolean {
  resetRecords();
  Records.setEnd(0, maxstorage + 10);
  Records.write(0, maxstorage + 5, [100, 1, 0]);
  Test.assertEqual(Records.first(0), 10);
  return Records.get(0, 5) != null && Records.slot(1, 3) == maxstorage + 3;
}

(:test)
function commIgnoresMalformedMessages(logger as Logger) as Boolean {
  resetRecords();
  var messages = [
    null,
    "text",
    [],
    [null],
    ["x", 1],
    [GLUCOSE],
    [GLUCOSE, 5],
    [GLUCOSE, ["s", 1]],
    [GLUCOSE, ["s", "t", 1, 1, 0]],
    [PUTNUMS, 0, 0, 1],
    [PUTNUMS, 7, 0, 1, [[1, 1, 0]]],
    [PUTNUMS, 0, 0, 2, [[1, 1, 0]]],
    [DELETE, 0, 5, 3],
    [DELETE, 3, 0, 1],
    [NUMS, 0.5, 1],
    [NUMS, 9, 1],
    [MORENUMS, 1],
    [SETENDNUM, 2, 0],
    [GETENDNUM, 4],
    [COLORBLACK, "white"],
    [PUTLABELS, "a"],
    [SHORTCUTS, [["only name"], 5]],
    [HEART],
  ];
  for (var i = 0; i < messages.size(); i++) {
    Comm.handle(messages[i]);
  }
  return Records.ends[0] == 0 && Records.ends[1] == 0;
}

(:test)
function commStoresRecordsAndLabels(logger as Logger) as Boolean {
  resetRecords();
  var labels = Labels.names;
  Comm.handle([PUTNUMS, 1, 0, 2, [[100, 2.5, 1], [200, 3, 0]]]);
  Comm.handle([PUTLABELS, ["Food", "Fiasp", 3]]);
  Test.assertEqual(Records.ends[1], 2);
  Test.assertEqual(Labels.names[2], "3");
  Test.assert(Labels.insulin == 1);
  Labels.setNames(labels as Array<Object?>);
  return true;
}

(:test)
function glucoseUpdateFormatsAndRaisesAlarms(logger as Logger) as Boolean {
  Glucose.unit = 0;
  Glucose.update(["Sensor", Time.now().value(), 123.4, 1.5, 0, 1]);
  Test.assertEqual(Glucose.unit, 1);
  Test.assertEqual(Glucose.text, "123.4");
  Test.assertEqual(Glucose.sensor, "Sensor");
  Test.assertEqual(Glucose.alarmLevel, 0);
  Glucose.update(["Sensor", Time.now().value(), 3.1, 0.0, 0x05, 1]);
  Test.assertEqual(Glucose.label(), "3.1>");
  Glucose.update(["Sensor", Time.now().value(), 250, 0.0, 0x04 | 0x08 | 0x10, 0]);
  Test.assertEqual(Glucose.text, "250");
  Test.assertEqual(Glucose.label(), "250<");
  var alarmed = Alarm.active;
  Glucose.update(["Sensor", Time.now().value(), 100, 0.0, 0, 0]);
  return alarmed && !Alarm.active;
}

(:test)
function labelsFindTheInsulinLabel(logger as Logger) as Boolean {
  var saved = Labels.names;
  Labels.setNames(["Carbs", "Lantus", "NovoRapid"]);
  Test.assert(Labels.insulin == 2);
  Labels.setNames(["Carbs", "Insulin basal", "Insulin"]);
  Test.assert(Labels.insulin == 2);
  Application.Storage.deleteValue("insulinvar");
  Labels.setNames(["Carbs", "Walk"]);
  Test.assert(Labels.insulin == null);
  Labels.rememberInsulin(1);
  Test.assert(Labels.insulin == 1);
  Application.Storage.deleteValue("insulinvar");
  Labels.setNames(saved as Array<Object?>);
  return true;
}

(:test)
function labelsRoundToPrecision(logger as Logger) as Boolean {
  Labels.precisions = [0.5, 1, 0.0];
  return (
    Labels.round(1.3, 0) == 1.5 &&
    Labels.round(2.6, 1) == 3.0 &&
    Labels.round(2.61, 2) == 2.61 &&
    Labels.round(2.61, 7) == 2.61
  );
}

(:test)
function sportsMigrateTheLegacyOrder(logger as Logger) as Boolean {
  Application.Storage.deleteValue("sportorder");
  Application.Storage.deleteValue("sportsort");
  var count = 4;
  var order = Sports.loadOrder(count);
  Test.assertEqual(order.toString(), "[2, 0, 1, 3]");

  // Linked list 3 -> 1 -> 0 -> 2 with head and tail at index `count`.
  var next = [2, 0, 4, 1, 3];
  var previous = [1, 3, 0, 4, 2];
  Application.Storage.setValue("sportsort", [next, previous]);
  order = Sports.loadOrder(count);
  Application.Storage.deleteValue("sportsort");
  return order.toString().equals("[3, 1, 0, 2]");
}

(:test)
function insulinDecays(logger as Logger) as Boolean {
  var now = Insulin.fiasp(4.0, 0.0);
  var later = Insulin.fiasp(4.0, 120.0);
  var gone = Insulin.fiasp(4.0, 600.0);
  return now > 3.99 && now < 4.01 && later > 0.0 && later < now && gone < 0.1;
}

(:test)
function listRowsMatchDrawnRows(logger as Logger) as Boolean {
  Ui.height = 400;
  // Rows drawn at 80, 160, 240 and 320.
  return (
    Ui.rowAt(0, 4) == 0 &&
    Ui.rowAt(119, 4) == 0 &&
    Ui.rowAt(121, 4) == 1 &&
    Ui.rowAt(320, 4) == 3 &&
    Ui.rowAt(399, 4) == 3
  );
}

(:test)
function ringSectorsStartAtTwelve(logger as Logger) as Boolean {
  Ui.width = 400;
  Ui.height = 400;
  return (
    Ui.sectorAt(200, 0, 10) == 0 &&
    Ui.sectorAt(215, 0, 10) == 0 &&
    Ui.sectorAt(185, 0, 10) == 0 &&
    Ui.sectorAt(399, 150, 10) == 2 &&
    Ui.sectorAt(200, 399, 10) == 5 &&
    Ui.sectorAt(0, 150, 10) == 8
  );
}
