import Toybox.Lang;
import Toybox.Time;

// The text being typed on the dial, with the texts typed before it.
class Entry {
  static const MAX_LENGTH = 33;

  var text as String = "";
  // Earlier texts, oldest first, offered on the history screen.
  var history as Array<String> = [];
  // An operator was added since the last evaluation.
  var operated as Boolean = false;
  // Inside a run of backspaces; the text was saved to the history at the
  // start of the run.
  private var _deleting as Boolean = false;

  function initialize() {}

  function length() as Number {
    return text.length();
  }

  function setText(value as String) as Void {
    text = value;
    _deleting = false;
  }

  // Returns false (and leaves the text alone) when the result is too long.
  function append(value as String) as Boolean {
    if (text.length() + value.length() > MAX_LENGTH) {
      return false;
    }
    setText(text + value);
    return true;
  }

  function backspace() as Void {
    if (!_deleting) {
      remember();
      _deleting = true;
    }
    text = text.substring(0, text.length() - 1) as String;
  }

  // Adds a decimal point unless the number being typed already has one.
  function addPoint() as Void {
    var chars = text.toCharArray();
    for (var i = chars.size() - 1; i >= 0; i--) {
      var c = chars[i];
      if (c == '.') {
        return;
      }
      if (c == '+' || c == '-' || c == '*' || c == 'x' || c == '/' || c == '(' || c == ')' || c == '^') {
        break;
      }
    }
    append(".");
  }

  function remember() as Void {
    var count = history.size();
    if (text.length() > 0 && (count == 0 || !history[count - 1].equals(text))) {
      history.add(text);
    }
  }
}

// What a number typed on the dial is used for.
class EntryTarget {
  function initialize() {}

  function initialText() as String {
    return "";
  }

  // Uses the typed number; returns false when it is not acceptable.
  function commit(text as String) as Boolean {
    return false;
  }
}

// Logs a new value under a label.
class NewRecordTarget extends EntryTarget {
  private var _label as Number;

  function initialize(label as Number) {
    EntryTarget.initialize();
    _label = label;
  }

  function commit(text as String) as Boolean {
    var value = text.toFloat();
    if (value == null || !Records.add([Time.now().value(), Labels.round(value, _label), _label])) {
      return false;
    }
    Comm.sendChangesSoon();
    return true;
  }
}

// Changes the value of a record being edited.
class RecordValueTarget extends EntryTarget {
  private var _record as Array;

  function initialize(record as Array) {
    EntryTarget.initialize();
    _record = record;
  }

  function initialText() as String {
    return (_record[1] as Numeric).format("%g");
  }

  function commit(text as String) as Boolean {
    var value = text.toFloat();
    if (value == null) {
      return false;
    }
    _record[1] = Labels.round(value, _record[2] as Number);
    return true;
  }
}

// Changes one field (:year, :day, :hour or :minute) of the time of a record
// being edited.
class RecordTimeTarget extends EntryTarget {
  private var _record as Array;
  private var _field as Symbol;

  function initialize(record as Array, field as Symbol) {
    EntryTarget.initialize();
    _record = record;
    _field = field;
  }

  function initialText() as String {
    var info = Dates.localInfo(_record[0] as Number);
    switch (_field) {
      case :year:
        return info.year.format("%d");
      case :day:
        return info.day.format("%d");
      case :hour:
        return info.hour.format("%02d");
      default:
        return info.min.format("%02d");
    }
  }

  function commit(text as String) as Boolean {
    var value = text.toNumber();
    var time = value == null ? null : Dates.withField(_record[0] as Number, _field, value);
    if (time == null) {
      return false;
    }
    _record[0] = time;
    return true;
  }
}

// Sets the autolap distance of the selected sport.
class LapLengthTarget extends EntryTarget {
  function initialize() {
    EntryTarget.initialize();
  }

  function initialText() as String {
    return (Sports.lapLength * Units.distanceFactor).format("%.2f");
  }

  function commit(text as String) as Boolean {
    var value = text.toFloat();
    if (value == null || value < 0) {
      return false;
    }
    Sports.setLapLength(value / Units.distanceFactor);
    return true;
  }
}

function openDial(target as EntryTarget, title as String) as Void {
  var entry = new Entry();
  var initial = target.initialText();
  if (initial.length() > 0) {
    entry.history.add(initial);
  }
  Ui.push(new DialView(entry, title), new DialDelegate(entry, target));
}

function openNewRecordDial(label as Number) as Void {
  openDial(new NewRecordTarget(label), Labels.name(label));
}
