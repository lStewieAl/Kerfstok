import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// The Activity.Info fields listed on the measurements screen.
module Measures {
  function labels() as Array<String> {
    return [
      "maxSpeed",
      "averageSpeed",
      "startTime",
      "elapsedTime",
      "OxygenSaturation",
      "averageHeartRate",
      "maxHeartRate",
      "energyExpenditure (kcals/min)",
      "calories (kcal)",
      "frontDerailleurIndex",
      "frontDerailleurMax",
      "frontDerailleurSize",
      "rearDerailleurIndex",
      "rearDerailleurMax",
      "rearDerailleurSize",
      "Power",
      "averagePower",
      "maxPower",
      "Cadence (steps/min)",
      "averageCadence",
      "maxCadence",
      "bearing",
      "bearingFromStart",
      "totalAscent",
      "totalDescent",
      "meanSeaLevelPressure",
      "ambientPressure",
      "rawAmbientPressure",
      "Heading",
    ];
  }

  // Formatted value of measure `index`, or null when it is not available.
  function value(info as Activity.Info, index as Number) as String? {
    switch (index) {
      case 0:
        return info has :maxSpeed ? scaled(info.maxSpeed, Units.speedFactor, "%.0f") : null;
      case 1:
        return info has :averageSpeed ? scaled(info.averageSpeed, Units.speedFactor, "%.0f") : null;
      case 2:
        if (info has :startTime && info.startTime != null) {
          var start = Gregorian.info(info.startTime as Time.Moment, Time.FORMAT_SHORT);
          return Ui.hhmm(start.hour, start.min) + ":" + start.sec.format("%02d");
        }
        return null;
      case 3:
        return info has :elapsedTime ? scaled(info.elapsedTime, 0.001, "%.0f") : null;
      case 4:
        return info has :currentOxygenSaturation ? text(info.currentOxygenSaturation) : null;
      case 5:
        return info has :averageHeartRate ? text(info.averageHeartRate) : null;
      case 6:
        return info has :maxHeartRate ? text(info.maxHeartRate) : null;
      case 7:
        return info has :energyExpenditure ? scaled(info.energyExpenditure, 1.0, "%.0f") : null;
      case 8:
        return info has :calories ? text(info.calories) : null;
      case 9:
        return info has :frontDerailleurIndex ? text(info.frontDerailleurIndex) : null;
      case 10:
        return info has :frontDerailleurMax ? text(info.frontDerailleurMax) : null;
      case 11:
        return info has :frontDerailleurSize ? text(info.frontDerailleurSize) : null;
      case 12:
        return info has :rearDerailleurIndex ? text(info.rearDerailleurIndex) : null;
      case 13:
        return info has :rearDerailleurMax ? text(info.rearDerailleurMax) : null;
      case 14:
        return info has :rearDerailleurSize ? text(info.rearDerailleurSize) : null;
      case 15:
        return info has :currentPower ? text(info.currentPower) : null;
      case 16:
        return info has :averagePower ? text(info.averagePower) : null;
      case 17:
        return info has :maxPower ? text(info.maxPower) : null;
      case 18:
        return info has :currentCadence ? text(info.currentCadence) : null;
      case 19:
        // Reported per foot; shown as steps per minute.
        return info has :averageCadence ? scaled(info.averageCadence, 2, "%d") : null;
      case 20:
        return info has :maxCadence ? scaled(info.maxCadence, 2, "%d") : null;
      case 21:
        return info has :bearing ? text(info.bearing) : null;
      case 22:
        return info has :bearingFromStart ? text(info.bearingFromStart) : null;
      case 23:
        return info has :totalAscent ? scaled(info.totalAscent, 1.0, "%.1f") : null;
      case 24:
        return info has :totalDescent ? scaled(info.totalDescent, 1.0, "%.1f") : null;
      case 25:
        return info has :meanSeaLevelPressure ? scaled(info.meanSeaLevelPressure, 1.0, "%.0f") : null;
      case 26:
        return info has :ambientPressure ? scaled(info.ambientPressure, 1.0, "%.0f") : null;
      case 27:
        return info has :rawAmbientPressure ? scaled(info.rawAmbientPressure, 1.0, "%.0f") : null;
      case 28:
        return info has :currentHeading ? text(info.currentHeading) : null;
    }
    return null;
  }

  function text(value as Object?) as String? {
    if (value instanceof Float || value instanceof Double) {
      return value.format("%.2f");
    }
    return value == null ? null : value.toString();
  }

  function scaled(value as Object?, factor as Numeric, format as String) as String? {
    return isNumeric(value) ? ((value as Numeric) * factor).format(format) : null;
  }
}
