import Toybox.Application;
import Toybox.Lang;

// The sports that can be recorded, most recently used first, and the
// settings for the selected sport.
module Sports {
  // FIT sport ids, most recently used first. The first is the current sport.
  var order as Array<Number> = [];
  // Index in subSports(current()) of the selected sub sport, -1 when the
  // sport has none.
  var subIndex as Number = -1;
  // Autolap distance in meters, 0 for no autolap.
  var lapLength as Float = 5000.0;

  var _orderChanged as Boolean = false;

  // Sport names indexed by FIT sport id, with the FIT sub sport ids offered
  // for that sport.
  function table() as Array<Array> {
    return [
      ["GENERIC"],
      ["RUNNING", [0, 1, 2, 3, 4, 45]],
      ["CYCLING", [0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 29, 46, 47, 48, 49]],
      ["TRANSITION", [0, 32, 33, 34]],
      ["FITNESS_EQUIPMENT", [0, 1, 6, 14, 15, 16, 25, 27, 44]],
      ["SWIMMING", [0, 17, 18]],
      ["BASKETBALL"],
      ["SOCCER"],
      ["TENNIS", [0, 21, 22, 23]],
      ["AMERICAN_FOOTBALL"],
      ["TRAINING", [0, 19, 20, 26, 43]],
      ["WALKING", [0, 27, 30, 31]],
      ["CROSS_COUNTRY_SKIING", [0, 42]],
      ["ALPINE_SKIING", [0, 37, 38]],
      ["SNOWBOARDING", [0, 37, 38]],
      ["ROWING"],
      ["MOUNTAINEERING"],
      ["HIKING"],
      ["MULTISPORT"],
      ["PADDLING"],
      ["FLYING", [0, 39, 40]],
      ["E_BIKING", [0, 28]],
      ["MOTORCYCLING", [0, 35, 36]],
      ["BOATING"],
      ["DRIVING"],
      ["GOLF"],
      ["HANG_GLIDING"],
      ["HORSEBACK_RIDING"],
      ["HUNTING"],
      ["FISHING"],
      ["INLINE_SKATING"],
      ["ROCK_CLIMBING"],
      ["SAILING"],
      ["ICE_SKATING"],
      ["SKY_DIVING"],
      ["SNOWSHOEING"],
      ["SNOWMOBILING"],
      ["STAND_UP_PADDLEBOARDING"],
      ["SURFING"],
      ["WAKEBOARDING"],
      ["WATER_SKIING"],
      ["KAYAKING", [0, 41]],
      ["RAFTING", [0, 41]],
      ["WINDSURFING"],
      ["KITESURFING"],
      ["TACTICAL"],
      ["JUMPMASTER"],
      ["BOXING"],
      ["FLOOR_CLIMBING"],
      ["BASEBALL"],
      ["SOFTBALL_FAST_PITCH"],
      ["SOFTBALL_SLOW_PITCH"],
    ];
  }

  // Sub sport names indexed by FIT sub sport id.
  function subSportName(id as Number) as String {
    var names = [
      "generic",
      "treadmill",
      "street",
      "trail",
      "track",
      "spin",
      "indoor_cycling",
      "road",
      "mountain",
      "downhill",
      "recumbent",
      "cyclocross",
      "hand",
      "track",
      "indoor_rowing",
      "elliptical",
      "stair_climbing",
      "lap",
      "open_water",
      "flexibility",
      "strength",
      "warm_up",
      "match",
      "exercise",
      "challenge",
      "indoor_skiing",
      "cardio",
      "indoor_walking",
      "e_bike_fitness",
      "bmx",
      "casual",
      "speed",
      "bike_to_run",
      "run_to_bike",
      "swim_to_bike",
      "atv",
      "motocross",
      "backcountry",
      "resort",
      "rc_drone",
      "wingsuit",
      "whitewater",
      "skate_skiing",
      "yoga",
      "pilates",
      "indoor",
      "gravel",
      "e_bike_mountain",
      "commuting",
      "mixed_surface",
    ];
    return id >= 0 && id < names.size() ? names[id] : "";
  }

  function load() as Void {
    order = loadOrder(table().size());
    loadSettings();
  }

  function current() as Number {
    return order[0];
  }

  function name(sport as Number) as String {
    return table()[sport][0] as String;
  }

  function names() as Array<String> {
    var all = table();
    var result = new [order.size()] as Array<String>;
    for (var i = 0; i < order.size(); i++) {
      result[i] = all[order[i]][0] as String;
    }
    return result;
  }

  function subSports(sport as Number) as Array<Number>? {
    var entry = table()[sport];
    return entry.size() > 1 ? entry[1] as Array<Number> : null;
  }

  function subSportNames() as Array<String> {
    var subs = subSports(current());
    var result = [] as Array<String>;
    if (subs != null) {
      for (var i = 0; i < subs.size(); i++) {
        result.add(subSportName(subs[i]));
      }
    }
    return result;
  }

  // FIT sub sport id of the selection; 0 (generic) when the sport has none.
  function subSportId() as Number {
    var subs = subSports(current());
    return subs == null || subIndex < 0 ? 0 : subs[subIndex];
  }

  // Makes `sport` the current sport by moving it to the front.
  function select(sport as Number) as Void {
    if (order[0] != sport) {
      order.remove(sport);
      order = [sport].addAll(order);
      _orderChanged = true;
    }
    loadSettings();
  }

  function selectSubSport(index as Number) as Void {
    subIndex = index;
    Application.Storage.setValue("ss" + current(), index);
    loadLapLength();
  }

  function setLapLength(meters as Float) as Void {
    lapLength = meters;
    Application.Storage.setValue(lapKey(), meters);
  }

  function save() as Void {
    if (_orderChanged) {
      Application.Storage.setValue("sportorder", order as Array<Application.PropertyValueType>);
      _orderChanged = false;
    }
  }

  function loadSettings() as Void {
    var subs = subSports(current());
    if (subs == null) {
      subIndex = -1;
    } else {
      var stored = Application.Storage.getValue("ss" + current());
      subIndex = stored instanceof Number && stored >= 0 && stored < subs.size() ? stored : 0;
    }
    loadLapLength();
  }

  function loadLapLength() as Void {
    var stored = Application.Storage.getValue(lapKey());
    lapLength = isNumeric(stored) ? (stored as Numeric).toFloat() : Units.defaultLap;
  }

  function lapKey() as String {
    return current().toString() + "lap" + subSportId();
  }

  function loadOrder(count as Number) as Array<Number> {
    var stored = Application.Storage.getValue("sportorder");
    if (stored instanceof Array && stored.size() == count) {
      return stored as Array<Number>;
    }
    // Older versions stored a doubly linked list [next, previous] with
    // `count` as the head.
    stored = Application.Storage.getValue("sportsort");
    var next = stored instanceof Array && stored.size() == 2 ? stored[0] as Object? : null;
    if (next instanceof Array && next.size() == count + 1) {
      var result = [] as Array<Number>;
      var sport = next[count];
      while (sport instanceof Number && sport >= 0 && sport < count && result.size() < count) {
        result.add(sport);
        sport = next[sport];
      }
      if (result.size() == count) {
        return result;
      }
    }
    // Default: FIT order with cycling first.
    var result = [2] as Array<Number>;
    for (var i = 0; i < count; i++) {
      if (i != 2) {
        result.add(i);
      }
    }
    return result;
  }
}
