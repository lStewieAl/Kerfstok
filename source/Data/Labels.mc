import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// The labels values are logged under, and the precision each is rounded to.
// Both lists are maintained in Juggluco.
module Labels {
  var names as Array<String> = [
    "Label1",
    "Carbohydrat",
    "Dextro",
    "Label4",
    "Cycle",
    "Walk",
    "Label7",
    "Label8",
  ];
  var precisions as Array<Object?> = [0.5, 1, 1, 0.5, 1, 1, 0.0, 0.0, 0.0];
  // Label used for (rapid acting) insulin, or null when unknown.
  var insulin as Number? = null;

  function load() as Void {
    var stored = Application.Storage.getValue("labels");
    if (stored instanceof Array && stored.size() > 0) {
      names = toStrings(stored as Array<Object?>);
    }
    stored = Application.Storage.getValue("preclabels");
    if (stored instanceof Array && stored.size() > 0) {
      precisions = stored as Array<Object?>;
    }
    resolveInsulin();
  }

  function setNames(list as Array<Object?>) as Void {
    if (list.size() > 0) {
      names = toStrings(list);
      Application.Storage.setValue("labels", names as Array<Application.PropertyValueType>);
      resolveInsulin();
      WatchUi.requestUpdate();
    }
  }

  function setPrecisions(list as Array<Object?>) as Void {
    if (list.size() > 0) {
      precisions = list;
      Application.Storage.setValue("preclabels", list as Array<Application.PropertyValueType>);
    }
  }

  function count() as Number {
    return names.size();
  }

  function isValid(label as Object?) as Boolean {
    return label instanceof Number && label >= 0 && label < names.size();
  }

  function name(label as Object?) as String {
    return isValid(label) ? names[label as Number] : "???";
  }

  // Rounds a value to the precision of its label; 0 means no rounding.
  function round(value as Float, label as Number) as Float {
    var precision = label >= 0 && label < precisions.size() ? precisions[label] : null;
    var step = isNumeric(precision) ? (precision as Numeric).toFloat() : 0.0;
    if (step < 0.00001) {
      return value;
    }
    return (Math.round(value / step) * step).toFloat();
  }

  // Used when the label names do not identify the insulin label.
  function rememberInsulin(label as Number) as Void {
    Application.Storage.setValue("insulinvar", label);
    resolveInsulin();
  }

  // Juggluco lets the user rename and reorder labels, so the insulin label is
  // found by name. Rapid acting names are checked first so that a list with
  // both a rapid and a basal insulin resolves to the one used for boluses.
  function resolveInsulin() as Void {
    insulin = findLabel(["aspart", "novorapid", "novolog", "humalog", "lispro", "fiasp", "rapid", "apidra", "insulin rap"], null);
    if (insulin == null) {
      insulin = findLabel(["insulin"], ["basal", "basinsulin", "slow", "lenta", "lantus", "levemir", "tresiba", "degludec", "glargine", "toujeo"]);
    }
    if (insulin == null) {
      var saved = Application.Storage.getValue("insulinvar");
      insulin = isValid(saved) ? saved as Number : null;
    }
  }

  function findLabel(include as Array<String>, exclude as Array<String>?) as Number? {
    for (var i = 0; i < names.size(); i++) {
      var lower = names[i].toLower();
      if (containsAny(lower, include) && (exclude == null || !containsAny(lower, exclude))) {
        return i;
      }
    }
    return null;
  }

  function containsAny(text as String, needles as Array<String>) as Boolean {
    for (var i = 0; i < needles.size(); i++) {
      if (text.find(needles[i]) != null) {
        return true;
      }
    }
    return false;
  }

  function toStrings(list as Array<Object?>) as Array<String> {
    var result = new [list.size()] as Array<String>;
    for (var i = 0; i < list.size(); i++) {
      var item = list[i];
      result[i] = item == null ? "" : item.toString();
    }
    return result;
  }
}
