import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// The logged values, kept in two rings of `maxstorage` records in Storage:
// base 0 holds the values entered on the watch, base 1 the values received
// from Juggluco. A record is [unixTime, value, labelIndex].
//
// Record indexes only grow; index i is stored in slot i % maxstorage. Juggluco
// keeps its own copy and both sides exchange changes from `lowest[base]`,
// the lowest index changed since Juggluco last confirmed it. While that is
// null the sync state is unknown and nothing may be written to the ring.
module Records {
  var ends as Array<Number> = [0, 0]; // One past the newest index per base.
  var lowest as Array<Number?> = [null, null];
  // Changes on every write so cached results (IOB) know when to refresh.
  var revision as Number = 0;
  var _previousLowest as Array<Number?> = [-1, -1];

  function load() as Void {
    for (var base = 0; base < 2; base++) {
      var end = Application.Storage.getValue(endKey(base));
      ends[base] = end instanceof Number ? end : 0;
      var low = Application.Storage.getValue(lowestKey(base));
      lowest[base] = low instanceof Number ? low : null;
    }
  }

  function isBase(base as Object?) as Boolean {
    return base instanceof Number && (base == 0 || base == 1);
  }

  function isSynced(base as Number) as Boolean {
    return lowest[base] != null;
  }

  // Oldest index that is still stored.
  function first(base as Number) as Number {
    return ends[base] > maxstorage ? ends[base] - maxstorage : 0;
  }

  // The record at `id`, or null when it is missing or malformed.
  function get(base as Number, id as Number) as Array? {
    var record = raw(base, id);
    if (
      record instanceof Array &&
      record.size() >= 3 &&
      isNumeric(record[0]) &&
      isNumeric(record[1]) &&
      record[2] instanceof Number
    ) {
      return record as Array;
    }
    return null;
  }

  function raw(base as Number, id as Number) as Application.PropertyValueType {
    return Application.Storage.getValue(slot(base, id));
  }

  // Appends a value entered on the watch. Fails while the sync state with
  // Juggluco is unknown; a sync is requested in that case.
  function add(record as Array) as Boolean {
    if (!isSynced(0)) {
      Comm.requestSync();
      return false;
    }
    var id = ends[0];
    update(0, id, record);
    setEnd(0, id + 1);
    return true;
  }

  // Stores a changed record and marks it for sending to Juggluco.
  function update(base as Number, id as Number, record as Array) as Void {
    var low = lowest[base];
    if (low != null && id < low) {
      setLowest(base, id);
    }
    write(base, id, record);
  }

  function write(base as Number, id as Number, record as Object?) as Void {
    if (record == null) {
      Application.Storage.deleteValue(slot(base, id));
    } else {
      Application.Storage.setValue(slot(base, id), record as Application.PropertyValueType);
    }
    revision++;
  }

  function setEnd(base as Number, end as Number) as Void {
    ends[base] = end;
    Application.Storage.setValue(endKey(base), end);
    revision++;
  }

  function setLowest(base as Number, id as Number) as Void {
    _previousLowest[base] = lowest[base];
    lowest[base] = id;
    Application.Storage.setValue(lowestKey(base), id);
  }

  // Moves a record whose time changed so the ring stays sorted by time.
  function moveToTime(base as Number, id as Number, record as Array) as Void {
    var time = record[0];
    var target = id;
    for (var i = id - 1; i >= first(base); i--) {
      var other = get(base, i);
      if (other != null) {
        if (other[0] <= time) {
          break;
        }
        update(base, target, other);
        target = i;
      }
    }
    if (target == id) {
      for (var i = id + 1; i < ends[base]; i++) {
        var other = get(base, i);
        if (other != null) {
          if (other[0] >= time) {
            break;
          }
          update(base, target, other);
          target = i;
        }
      }
    }
    update(base, target, record);
  }

  // Deletes a record on the watch and tells Juggluco.
  function deleteRecord(base as Number, id as Number) as Void {
    var changed = removeThrough(base, id);
    var low = lowest[base];
    if (low == null || changed < low) {
      setLowest(base, changed);
    }
    Comm.send([DELETE, base, id]);
  }

  // Deletes [from, end) as requested by Juggluco.
  function removeRange(base as Number, from as Number, end as Number) as Void {
    if (end <= from) {
      return;
    }
    if (end - from > maxstorage) {
      from = end - maxstorage;
    }
    for (var id = from; id < end - 1; id++) {
      write(base, id, null);
    }
    removeThrough(base, end - 1);
    WatchUi.requestUpdate();
  }

  // Stores a batch of records sent by Juggluco. Returns false when the batch
  // is inconsistent.
  function storeBatch(base as Number, begin as Number, end as Number, records as Array<Object?>) as Boolean {
    if (end - begin != records.size()) {
      return false;
    }
    for (var i = 0; i < records.size(); i++) {
      write(base, begin + i, records[i]);
    }
    var oldEnd = ends[base];
    if (end > oldEnd) {
      setEnd(base, end);
    }
    var low = lowest[base];
    if (low == null || oldEnd < begin || end - low > maxstorage || (low >= begin && low < end)) {
      setLowest(base, end);
    }
    WatchUi.requestUpdate();
    return true;
  }

  // Juggluco has records up to `id` that it will send.
  function onMoreAvailable(base as Number, id as Number) as Void {
    var low = lowest[base];
    if (low == null || id > low) {
      setLowest(base, id);
    }
  }

  // Juggluco confirmed a deletion; undo the lowest change it caused.
  function onDeleteConfirmed(base as Number, id as Number) as Void {
    var low = lowest[base];
    var previous = _previousLowest[base];
    if (low != null && id == low && previous != null && previous > low) {
      setLowest(base, previous);
    }
  }

  // Juggluco cleared all data.
  function clear() as Void {
    Application.Storage.clearValues();
    for (var base = 0; base < 2; base++) {
      setEnd(base, 0);
    }
  }

  // Deletes `id`; when it was the newest record, also drops the empty slots
  // before it. Returns the lowest index that changed.
  function removeThrough(base as Number, id as Number) as Number {
    write(base, id, null);
    if (id != ends[base] - 1) {
      return id;
    }
    var i = id - 1;
    while (i >= first(base) && raw(base, i) == null) {
      i--;
    }
    setEnd(base, i + 1);
    return ends[base];
  }

  function slot(base as Number, id as Number) as Number {
    return (id % maxstorage) + base * maxstorage;
  }

  function endKey(base as Number) as Number {
    return -base - 1;
  }

  function lowestKey(base as Number) as String {
    return base == 0 ? "lowest" : "lowest1";
  }
}

function isNumeric(value as Object?) as Boolean {
  return value instanceof Number || value instanceof Float || value instanceof Double || value instanceof Long;
}
