import Toybox.Lang;
import Toybox.System;

// Distance and speed units from the device settings.
module Units {
  const METERS_PER_MILE = 1609.34;

  // Multiply meters by distanceFactor, and m/s by speedFactor, to get the
  // values to display.
  var distanceFactor as Float = 0.001;
  var speedFactor as Float = 3.6;
  var distanceUnit as String = "km";
  var speedUnit as String = "km/h";
  var showDistanceUnit as Boolean = false;
  // Default autolap length in meters.
  var defaultLap as Float = 5000.0;

  function init() as Void {
    var settings = System.getDeviceSettings();
    if (settings.distanceUnits == System.UNIT_STATUTE) {
      distanceFactor = 1.0 / METERS_PER_MILE;
      distanceUnit = "mi";
      defaultLap = 5.0 * METERS_PER_MILE;
    }
    if (settings.paceUnits == System.UNIT_STATUTE) {
      speedFactor = 3600.0 / METERS_PER_MILE;
      speedUnit = "mph";
    }
    showDistanceUnit = settings.distanceUnits == settings.paceUnits;
  }
}
