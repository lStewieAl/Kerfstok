import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Texts the user keeps for the dial: memory slots M0-M3 stored on the watch,
// and named shortcuts defined in Juggluco.
module Memory {
  const SLOT_COUNT = 4;

  var _slots as Array<String?> = [null, null, null, null];
  var _shortcutNames as Array<String> = [];
  var _shortcutValues as Array<String> = [];

  function load() as Void {
    for (var i = 0; i < SLOT_COUNT; i++) {
      var text = Application.Storage.getValue(slotKey(i));
      _slots[i] = text instanceof String && text.length() > 0 ? text : null;
    }
    var shortcuts = Application.Storage.getValue("shortcuts");
    if (shortcuts instanceof Array) {
      setShortcutList(shortcuts as Array<Object?>);
    }
  }

  function slotName(slot as Number) as String {
    return "M" + slot;
  }

  function slot(slot as Number) as String? {
    return _slots[slot];
  }

  // Stores `text` in a slot; an empty text clears it.
  function store(slot as Number, text as String) as Void {
    if (text.length() > 0) {
      _slots[slot] = text;
      Application.Storage.setValue(slotKey(slot), text);
    } else {
      _slots[slot] = null;
      Application.Storage.deleteValue(slotKey(slot));
    }
  }

  // Indexes of the slots that hold a text.
  function filledSlots() as Array<Number> {
    var filled = [] as Array<Number>;
    for (var i = 0; i < SLOT_COUNT; i++) {
      if (_slots[i] != null) {
        filled.add(i);
      }
    }
    return filled;
  }

  // Juggluco sends shortcuts as [[name, value], ...].
  function setShortcuts(list as Array<Object?>) as Void {
    Application.Storage.setValue("shortcuts", list as Array<Application.PropertyValueType>);
    setShortcutList(list);
    WatchUi.requestUpdate();
  }

  function shortcutNames() as Array<String> {
    return _shortcutNames;
  }

  function shortcutValue(index as Number) as String {
    return _shortcutValues[index];
  }

  function setShortcutList(list as Array<Object?>) as Void {
    _shortcutNames = [];
    _shortcutValues = [];
    for (var i = 0; i < list.size(); i++) {
      var item = list[i];
      if (item instanceof Array && item.size() >= 2) {
        var name = item[0] as Object?;
        var value = item[1] as Object?;
        if (name != null && value != null) {
          _shortcutNames.add(name.toString());
          _shortcutValues.add(value.toString());
        }
      }
    }
  }

  function slotKey(slot as Number) as String {
    return "memnum" + slot;
  }
}
