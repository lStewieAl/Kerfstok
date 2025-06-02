using Toybox.Activity;
using Toybox.Time;
using Toybox.Time.Gregorian;

function infofunc(info, num) {
  switch (num) {
    case 0:
      if (info has :maxSpeed && info.maxSpeed != null) {
        return (info.maxSpeed * toshowspeed).format("%.0f");
      }
      break;
    case 1:
      if (info has :averageSpeed && info.averageSpeed != null) {
        return (info.averageSpeed * toshowspeed).format("%.0f");
      }
      break;
    case 2:
      if (info has :startTime && info.startTime != null) {
        var tim = Gregorian.info(info.startTime, Time.FORMAT_SHORT);
        return (
          tim.hour.format("%02d") +
          ":" +
          tim.min.format("%02d") +
          ":" +
          tim.sec.format("%02d")
        );
      }
      break;
    case 3:
      if (info has :elapsedTime && info.elapsedTime != null) {
        return (info.elapsedTime / 1000.0).format("%.0f");
      }
      break;
    case 4:
      if (info has :currentOxygenSaturation) {
        return info.currentOxygenSaturation;
      }
      break;
    case 5:
      if (info has :averageHeartRate) {
        return info.averageHeartRate;
      }
      break;
    case 6:
      if (info has :maxHeartRate) {
        return info.maxHeartRate;
      }
      break;
    case 7:
      if (info has :energyExpenditure && info.energyExpenditure != null) {
        return info.energyExpenditure.format("%.0f");
      }
      break;
    case 8:
      if (info has :calories) {
        return info.calories;
      }
      break;
    case 9:
      if (info has :frontDerailleurIndex) {
        return info.frontDerailleurIndex;
      }
      break;
    case 10:
      if (info has :frontDerailleurMax) {
        return info.frontDerailleurMax;
      }
      break;
    case 11:
      if (info has :frontDerailleurSize) {
        return info.frontDerailleurSize;
      }
      break;
    case 12:
      if (info has :rearDerailleurIndex) {
        return info.rearDerailleurIndex;
      }
      break;
    case 13:
      if (info has :rearDerailleurMax) {
        return info.rearDerailleurMax;
      }
      break;
    case 14:
      if (info has :rearDerailleurSize) {
        return info.rearDerailleurSize;
      }
      break;
    case 15:
      if (info has :currentPower) {
        return info.currentPower;
      }
      break;
    case 16:
      if (info has :averagePower) {
        return info.averagePower;
      }
      break;
    case 17:
      if (info has :maxPower) {
        return info.maxPower;
      }
      break;
    case 18:
      if (info has :currentCadence) {
        return info.currentCadence;
      }
      break;
    case 19:
      if (info has :averageCadence && info.averageCadence != null) {
        return info.averageCadence * 2;
      }
      break;
    case 20:
      if (info has :maxCadence && info.maxCadence != null) {
        return info.maxCadence * 2;
      }
      break;
    case 21:
      if (info has :bearing) {
        return info.bearing;
      }
      break;
    case 22:
      if (info has :bearingFromStart) {
        return info.bearingFromStart;
      }
      break;
    case 23:
      if (info has :totalAscent && info.totalAscent != null) {
        return info.totalAscent.format("%.1f");
      }
      break;
    case 24:
      if (info has :totalDescent && info.totalDescent != null) {
        return info.totalDescent.format("%.1f");
      }
      break;
    case 25:
      if (info has :meanSeaLevelPressure && info.meanSeaLevelPressure != null) {
        return info.meanSeaLevelPressure.format("%.0f");
      }
      break;
    case 26:
      if (info has :ambientPressure && info.ambientPressure != null) {
        return info.ambientPressure.format("%.0f");
      }
      break;
    case 27:
      if (info has :rawAmbientPressure && info.rawAmbientPressure != null) {
        return info.rawAmbientPressure.format("%.0f");
      }
      break;
    case 28:
      if (info has :currentHeading) {
        return info.currentHeading;
      }
      break;
  }
  return null;
}

var infostr = [
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
