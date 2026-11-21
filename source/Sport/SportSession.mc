import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;
import Toybox.WatchUi;

// The activity being recorded, with GPS, laps and the glucose and energy
// expenditure FIT fields (see resources/glufield.xml).
module SportSession {
  const LAP_DISPLAY_SECONDS = 10;
  const GLUCOSE_FIELD_MAX_AGE = 30;

  var position as Position.Info? = null;
  // Last lap, shown until lapShownUntil.
  var lapName as String = "";
  var lapTime as String = "";
  var lapShownUntil as Number = 0;

  var _session as ActivityRecording.Session? = null;
  var _gpsOn as Boolean = false;
  var _glucoseField as FitContributor.Field? = null;
  var _energyField as FitContributor.Field? = null;
  var _lapLength as Float = 0.0;
  var _nextAutoLap as Float = 0.0;
  var _autoLaps as Number = 0;
  var _autoLapStart as Number = 0;
  var _manualLaps as Number = 0;
  var _manualLapStart as Number = 0;

  function isSupported() as Boolean {
    return Toybox has :ActivityRecording;
  }

  // A session exists, recording or paused.
  function isActive() as Boolean {
    return _session != null;
  }

  function isRecording() as Boolean {
    var session = _session;
    return session != null && session.isRecording();
  }

  function enableGps() as Void {
    if (!_gpsOn) {
      _gpsOn = true;
      Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, new Lang.Method(SportSession, :onPosition));
    }
  }

  function disableGps() as Void {
    if (_gpsOn) {
      _gpsOn = false;
      Position.enableLocationEvents(Position.LOCATION_DISABLE, new Lang.Method(SportSession, :onPosition));
    }
    position = null;
  }

  function start() as Void {
    var session = _session;
    if (session != null) {
      if (!session.isRecording()) {
        session.start();
      }
      return;
    }
    var sport = Sports.current();
    session = ActivityRecording.createSession({
      :name => Sports.name(sport),
      :sport => sport as ActivityRecording.Sport,
      :subSport => Sports.subSportId() as ActivityRecording.SubSport,
    });
    // The field ids match the fitField ids in glufield.xml.
    _glucoseField = session.createField("Glucose", Glucose.unit, FitContributor.DATA_TYPE_FLOAT, {
      :mesgType => FitContributor.MESG_TYPE_RECORD,
      :units => Glucose.unit == 1 ? "mmol/L" : "mg/dL",
    });
    _energyField = session.createField("Energy", 2, FitContributor.DATA_TYPE_FLOAT, {
      :mesgType => FitContributor.MESG_TYPE_RECORD,
      :units => "kcal/min",
    });

    var now = Time.now().value();
    _lapLength = Sports.lapLength;
    _nextAutoLap = _lapLength;
    _autoLaps = 0;
    _autoLapStart = now;
    _manualLaps = 0;
    _manualLapStart = now;
    lapName = "";
    lapTime = "";
    lapShownUntil = 0;

    _session = session;
    enableGps();
    session.start();
  }

  function pause() as Void {
    var session = _session;
    if (session != null && session.isRecording()) {
      session.stop();
    }
  }

  function resume() as Void {
    var session = _session;
    if (session != null && !session.isRecording()) {
      session.start();
    }
  }

  // Stops and saves the recording.
  function stop() as Void {
    var session = _session;
    if (session == null) {
      return;
    }
    disableGps();
    _glucoseField = null;
    _energyField = null;
    if (session.isRecording()) {
      session.stop();
    }
    session.save();
    _session = null;
    WatchUi.requestUpdate();
  }

  function manualLap() as Void {
    var session = _session;
    if (session != null && session.isRecording() && session.addLap()) {
      Haptics.triple();
      var now = Time.now().value();
      _manualLaps++;
      showLap("M " + _manualLaps, now - _manualLapStart, now);
      _manualLapStart = now;
    }
  }

  function recordGlucose(value as Float, time as Number) as Void {
    var field = _glucoseField;
    if (field != null && Time.now().value() - time < GLUCOSE_FIELD_MAX_AGE) {
      field.setData(value);
    }
  }

  function onPosition(info as Position.Info) as Void {
    position = info;
    var session = _session;
    var activity = Activity.getActivityInfo();
    if (session != null && session.isRecording() && activity != null) {
      var distance = activity.elapsedDistance;
      if (_lapLength > 0 && distance != null && distance > _nextAutoLap && session.addLap()) {
        Haptics.alarm();
        var now = Time.now().value();
        _autoLaps++;
        showLap("A " + _autoLaps, now - _autoLapStart, now);
        _autoLapStart = now;
        _nextAutoLap += _lapLength;
      }
      var field = _energyField;
      if (field != null && activity has :energyExpenditure && activity.energyExpenditure != null) {
        field.setData(activity.energyExpenditure as Float);
      }
    }
    WatchUi.requestUpdate();
  }

  function showLap(name as String, seconds as Number, now as Number) as Void {
    var min = seconds / 60;
    var sec = (seconds % 60).format("%02d");
    lapName = name;
    lapTime = min < 60 ? min.format("%02d") + ":" + sec : (min / 60).toString() + ":" + (min % 60).format("%02d") + ":" + sec;
    lapShownUntil = now + LAP_DISPLAY_SECONDS;
    WatchUi.requestUpdate();
  }
}
