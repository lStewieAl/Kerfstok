import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// Insulin on board, calculated from the logged insulin doses.
module Insulin {
  const WINDOW_SECONDS = 8 * 3600;
  const CACHE_SECONDS = 60;
  const PROJECTION_MINUTES = 10;

  // Units on board, and how much that changes over PROJECTION_MINUTES.
  var onBoard as Float = 0.0;
  var change as Float = 0.0;

  var _computedAt as Number = -1;
  var _revision as Number = -1;
  var _label as Number? = null;

  // Recalculating reads up to both full rings from flash, so the result is
  // cached until it is a minute old or the records or labels change.
  function refresh(now as Number) as Void {
    var label = Labels.insulin;
    if (
      _computedAt >= 0 &&
      now >= _computedAt &&
      now - _computedAt < CACHE_SECONDS &&
      _revision == Records.revision &&
      _label == label
    ) {
      return;
    }
    _computedAt = now;
    _revision = Records.revision;
    _label = label;
    onBoard = 0.0;
    change = 0.0;
    if (label == null) {
      return;
    }
    // Doses are entered on the watch (base 0) or in Juggluco (base 1).
    for (var base = 0; base < 2; base++) {
      for (var id = Records.ends[base] - 1; id >= Records.first(base); id--) {
        var record = Records.get(base, id);
        if (record == null) {
          continue;
        }
        var age = now - (record[0] as Numeric).toNumber();
        // Records are sorted by time, so everything before this is older.
        if (age > WINDOW_SECONDS) {
          break;
        }
        if (age >= 0 && record[2] == label) {
          var units = (record[1] as Numeric).toFloat();
          var minutes = age / 60.0;
          var current = fiasp(units, minutes);
          onBoard += current;
          change += fiasp(units, minutes + PROJECTION_MINUTES) - current;
        }
      }
    }
  }

  // Remaining fraction of a Fiasp dose `minutes` after injection.
  function fiasp(units as Float, minutes as Float) as Float {
    if (minutes < 0) {
      return 0.0;
    }
    var fraction = -4.79525 * Math.pow(Math.E, -0.0193717 * minutes) + 5.79525 * Math.pow(Math.E, -0.016029 * minutes);
    return fraction > 0 ? (fraction * units).toFloat() : 0.0;
  }

  // Older versions logged insulin from the Input shortcut under label 2 even
  // when that was not the insulin label. Move those values once.
  function repairLegacyEntries() as Void {
    if (Application.Storage.getValue("insulinrepaired") != null) {
      return;
    }
    var label = Labels.insulin;
    if (!Records.isSynced(0) || Records.ends[0] <= 0 || label == null) {
      return;
    }
    // Only possible when the shorter of the label and precision lists had at
    // most two entries.
    var oldCount = Labels.names.size() < Labels.precisions.size() ? Labels.names.size() : Labels.precisions.size();
    if (label != 2 && oldCount <= 2) {
      var repaired = false;
      for (var id = Records.first(0); id < Records.ends[0]; id++) {
        var record = Records.get(0, id);
        if (record != null && record[2] == 2) {
          record[2] = label;
          Records.update(0, id, record);
          repaired = true;
        }
      }
      if (repaired) {
        Comm.sendChanges(0);
        WatchUi.requestUpdate();
      }
    }
    Application.Storage.setValue("insulinrepaired", 1);
  }
}
