import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// Label picker. Without a record it starts a new value for the picked label;
// with a record (being edited) it changes the record's label.
class LabelDelegate extends ListDelegate {
  static const NEW_RECORD = 0;
  // Also remember the picked label as the insulin label.
  static const PICK_INSULIN = 1;

  private var _mode as Number;
  private var _record as Array?;

  function initialize(view as ListView, mode as Number, record as Array?) {
    ListDelegate.initialize(view);
    _mode = mode;
    _record = record;
  }

  function onItem(index as Number) as Void {
    var record = _record;
    if (record != null) {
      record[2] = index;
      Ui.pop();
      return;
    }
    if (_mode == PICK_INSULIN) {
      Labels.rememberInsulin(index);
      Insulin.repairLegacyEntries();
    }
    openNewRecordDial(index);
  }

  function onButton(key as WatchUi.Key) as Boolean {
    return onSwipeLeft();
  }

  function onSwipeLeft() as Boolean {
    if (_record != null) {
      Ui.pop();
    } else {
      openHistory();
    }
    return true;
  }
}

function openLabelPicker(mode as Number) as Void {
  var view = new ListView(Labels.names, Graphics.FONT_MEDIUM, 0);
  Ui.push(view, new LabelDelegate(view, mode, null));
}

// Adds a shortcut defined in Juggluco to the text.
class ShortcutDelegate extends ListDelegate {
  private var _entry as Entry;

  function initialize(view as ListView, entry as Entry) {
    ListDelegate.initialize(view);
    _entry = entry;
  }

  function onItem(index as Number) as Void {
    appendAndClose(_entry, Memory.shortcutValue(index));
  }

  function onMenu() as Boolean {
    openHistory();
    return true;
  }
}

// Adds the text of a memory slot.
class RecallDelegate extends ListDelegate {
  private var _entry as Entry;
  private var _slots as Array<Number>;

  function initialize(view as ListView, entry as Entry, slots as Array<Number>) {
    ListDelegate.initialize(view);
    _entry = entry;
    _slots = slots;
  }

  function onItem(index as Number) as Void {
    var text = Memory.slot(_slots[index]);
    appendAndClose(_entry, text == null ? "" : text);
  }
}

// Stores the text in a memory slot; an empty text clears the slot.
class StoreDelegate extends ListDelegate {
  private var _entry as Entry;

  function initialize(view as ListView, entry as Entry) {
    ListDelegate.initialize(view);
    _entry = entry;
  }

  function onItem(index as Number) as Void {
    Memory.store(index, _entry.text);
    Ui.pop();
  }
}

function appendAndClose(entry as Entry, text as String) as Void {
  if (entry.append(text)) {
    Ui.pop();
  } else {
    Haptics.ramp();
  }
}

// Earlier texts in rows of 2, 3, 3 and 2 that follow the round screen,
// starting at the page with the most recent ones.
class EntryHistoryView extends WatchUi.View {
  static const ROW_SIZES = [2, 3, 3, 2];
  static const PAGE_SIZE = 10;

  private var _items as Array<String>;
  private var _first as Number;

  function initialize(items as Array<String>) {
    View.initialize();
    _items = items;
    _first = items.size() > PAGE_SIZE ? ((items.size() - 1) / PAGE_SIZE) * PAGE_SIZE : 0;
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    Ui.drawClock(dc);
    var rows = ROW_SIZES.size();
    var radius = Ui.height / 2;
    var index = _first;
    for (var row = 0; row < rows && index < _items.size(); row++) {
      var count = ROW_SIZES[row];
      var y = ((row + 1) * Ui.height) / (rows + 1);
      var halfWidth = Ui.isRect ? Ui.width * 0.45 : Math.sqrt(radius * radius - (y - radius) * (y - radius));
      for (var col = 0; col < count && index < _items.size(); col++, index++) {
        if (col == 0) {
          dc.drawText(Ui.cx - halfWidth, y, Graphics.FONT_MEDIUM, _items[index], Ui.LEFT);
        } else if (col == count - 1) {
          dc.drawText(Ui.cx + halfWidth, y, Graphics.FONT_MEDIUM, _items[index], Ui.RIGHT);
        } else {
          dc.drawText(((col + 1) * Ui.width) / (count + 1), y, Graphics.FONT_MEDIUM, _items[index], Ui.CENTER);
        }
      }
    }
  }

  function itemAt(x as Number, y as Number) as String? {
    var row = Ui.rowAt(y, ROW_SIZES.size());
    var index = _first + (x * ROW_SIZES[row]) / Ui.width;
    for (var i = 0; i < row; i++) {
      index += ROW_SIZES[i];
    }
    return index < _items.size() ? _items[index] : null;
  }

  function turnPage(direction as Number) as Boolean {
    var first = _first + direction * PAGE_SIZE;
    if (first < 0 || first >= _items.size()) {
      return false;
    }
    _first = first;
    WatchUi.requestUpdate();
    return true;
  }
}

class EntryHistoryDelegate extends BaseDelegate {
  private var _view as EntryHistoryView;
  private var _entry as Entry;

  function initialize(view as EntryHistoryView, entry as Entry) {
    BaseDelegate.initialize();
    _view = view;
    _entry = entry;
  }

  function onTap(event as WatchUi.ClickEvent) as Boolean {
    var point = event.getCoordinates();
    var text = _view.itemAt(point[0], point[1]);
    if (text == null) {
      Haptics.bump();
    } else {
      appendAndClose(_entry, text);
    }
    return true;
  }

  function onNextPage() as Boolean {
    if (!_view.turnPage(1)) {
      Haptics.bump();
    }
    return true;
  }

  function onPreviousPage() as Boolean {
    if (!_view.turnPage(-1)) {
      Haptics.bump();
    }
    return true;
  }
}
