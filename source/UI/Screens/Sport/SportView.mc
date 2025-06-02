using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Application.Storage;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Activity;
using Toybox.ActivityMonitor;

var endlap = 0;
class SportView extends WatchUi.View {
  function initialize() {
    View.initialize();
  }

  var gluheight;
  var hheight;

  const unitlower = venu ? 0 : height * 0.03;
  const fromh = venusq2 ? 10 : 0;
  const ydist =
    venusq || venusq2
      ? height * 0.65
      : fenix7
      ? height * 0.635
      : edge1040 || edgeexplore2 || edge830
      ? height * 0.7
      : height * 0.59;
  const ydistunits = fenix7
    ? height * 0.64
    : edgeexplore2
    ? height * 0.67
    : height * 0.65;
  const sporttime =
    venusq2 || fenix8 || fenixe || fr965
      ? Gfx.FONT_LARGE
      : Gfx.FONT_NUMBER_MILD;
  const heartfont = sporttime;
  const speedfont =
    venusq2 || fenix8 || fenixe || fenix7
      ? Gfx.FONT_NUMBER_MEDIUM
      : Gfx.FONT_NUMBER_HOT;
  const glucosefont =
    venusq2 || fenix8 || fenixe || fr965
      ? Gfx.FONT_SYSTEM_NUMBER_HOT
      : Gfx.FONT_SYSTEM_NUMBER_THAI_HOT;
  const gpsfont =
    venusq2 || fenixe || fenix8 ? Gfx.FONT_MEDIUM : Gfx.FONT_LARGE;

  const speedunitJust =
    fenix7 || venusq2 || venusq
      ? Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_RIGHT
      : Gfx.TEXT_JUSTIFY_RIGHT;
  const speedy = fenix8
    ? height * 0.56
    : fenix7
    ? height * 0.61
    : venusq2
    ? height * 0.65
    : edge1040 || edgeexplore2 || edge830
    ? height * 0.48
    : fr965
    ? height * 0.57
    : height * 0.59;
  const lapsfont = fenix7 ? Gfx.FONT_LARGE : Gfx.FONT_NUMBER_MEDIUM;
  var starty, y;
  var speedunity;
  const fh = fromh - height * 0.05;
  const lapvaluey = fenix8
    ? height * 0.54
    : venusq2
    ? fh + height * 0.6
    : fr965
    ? height * 0.52
    : edgeexplore2
    ? height * 0.57
    : fromh + height * 0.57;
  const x = width * 0.57;
  var verh;
  var lapnamey, timey;
  var hearty;

  function onLayout(dc) {
    hheight = dc.getFontHeight(sporttime);
    gluheight = dc.getFontHeight(glucosefont);
    starty =
      (edge1040 || edgeexplore2 || edge830
        ? height * 0.065
        : fr965
        ? height * 0.02
        : 0) +
      (hheight * 0.78 - gluheight * 0.2);
    y = starty + gluheight * 0.8;
    speedunity = marq2
      ? 0.42 * height
      : fenix7
      ? 0.5 * height
      : venusq2
      ? 0.51 * height
      : venusq
      ? 0.45 * height
      : edgeexplore2
      ? height * 0.37
      : mk3
      ? height * 0.41
      : y + unitlower;
    lapnamey = venusq2
      ? y + fh + 0.01 * height
      : edge1040 || edgeexplore2
      ? 0.47 * height
      : edge830
      ? 0.45 * height
      : y + fromh + 0.01 * height;
    verh = edge830 || edge1040 ? starty + gluheight * 0.95 : y - fromh;
    dc.setPenWidth(height * 0.02);

    if (edge1040 || edgeexplore2) {
      timey = 0;
    } else {
      if (edge830) {
        timey = -hheight * 0.06;
      } else {
        if (fr965) {
          timey = -hheight * 0.06;
        } else {
          timey = -hheight * 0.12;
        }
      }
    }

    hearty = height - hheight * 0.88;
  }

  function onUpdate(dc) {
    dc.clearClip();
    dc.setColor(foreground, background);
    dc.clear();
    var unixnu = Time.now().value();

    var myTime = Gregorian.info(new Time.Moment(unixnu), Time.FORMAT_MEDIUM);
    dc.drawText(
      wmid,
      timey,
      sporttime,
      myTime.hour.format("%02d") + ":" + myTime.min.format("%02d"),
      Gfx.TEXT_JUSTIFY_CENTER
    );
    var vers = unixnu - glucosetime;

    if (vers < maxver) {
      var dims = dc.getTextDimensions(sensorversion, Gfx.FONT_XTINY);
      dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_TRANSPARENT);
      var xid = x - dims[0] / 2;
      dc.fillRectangle(xid, verh + 1, (dims[0] * vers) / maxver, dims[1]);
      dc.setColor(foreground, Gfx.COLOR_TRANSPARENT);
      dc.drawText(
        x,
        verh,
        Gfx.FONT_XTINY,
        sensorversion,
        Gfx.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        width * 0.6,
        starty,
        glucosefont,
        glucosestr,
        Gfx.TEXT_JUSTIFY_CENTER
      );
      if (glucoserate == -20) {
        dc.drawText(
          width * 0.9,
          hheight,
          Gfx.FONT_LARGE,
          ">",
          Gfx.TEXT_JUSTIFY_RIGHT
        );
      } else {
        if (glucoserate == 20) {
          dc.drawText(
            width * 0.9,
            hheight,
            Gfx.FONT_LARGE,
            "<",
            Gfx.TEXT_JUSTIFY_RIGHT
          );
        }
      }

      dc.setColor(foreground, Gfx.COLOR_TRANSPARENT);
      if (dc has :setAntiAlias) {
        dc.setAntiAlias(true);
      }
      if (glucoserate != 20.0 && glucoserate != -20.0) {
        var yp = starty + gluheight * 0.54;
        drawarrow(dc, width, height, width * 0.3, yp, density * 0.7);
      }
      dc.setColor(foreground, Gfx.COLOR_TRANSPARENT);
    } else {
      dc.setColor(foreground, Gfx.COLOR_TRANSPARENT);
    }
    if (positionInfo != null) {
      var showspeed = positionInfo.speed * toshowspeed;
      dc.drawText(
        width * 0.99,
        speedunity,
        Gfx.FONT_XTINY,
        speedunits,
        speedunitJust
      );
      dc.drawText(
        width * 0.98,
        speedy,
        speedfont,
        showspeed.format("%.0f"),
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_RIGHT
      );
    } else {
      if (activityrecord == null) {
        dc.drawText(
          wmid,
          height * 0.54,
          gpsfont,
          "Finished",
          Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
        );
      } else {
        dc.drawText(
          wmid,
          height * 0.54,
          gpsfont,
          "Waiting for GPS",
          Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_CENTER
        );
      }
    }
    var hr = 0;
    if (activityInfo != null) {
      if (activityInfo.elapsedDistance != null) {
        var dist = activityInfo.elapsedDistance * toshowdistance;
        dc.drawText(
          width * 0.13,
          ydist,
          speedfont,
          dist.format("%.1f"),
          Gfx.TEXT_JUSTIFY_LEFT
        );
        if (showdistanceunit) {
          dc.drawText(
            width * 0.13,
            ydistunits,
            Gfx.FONT_XTINY,
            distanceunits,
            Gfx.TEXT_JUSTIFY_RIGHT
          );
        }
      }
      if (activityInfo.currentHeartRate != null) {
        hr = activityInfo.currentHeartRate;
      }
    }
    if (unixnu < endlap) {
      dc.drawText(
        width * 0.04,
        lapnamey,
        Gfx.FONT_XTINY,
        lapstr1,
        Gfx.TEXT_JUSTIFY_LEFT
      );
      dc.drawText(
        0,
        lapvaluey,
        lapsfont,
        lapstr2,
        Gfx.TEXT_JUSTIFY_VCENTER | Gfx.TEXT_JUSTIFY_LEFT
      );
    }

    if (hr == 0) {
      if (
        Toybox has :ActivityMonitor &&
        Toybox.ActivityMonitor has :getHeartRateHistory
      ) {
        var sensorIter = Toybox.ActivityMonitor.getHeartRateHistory(1, true);
        if (sensorIter == null) {
          return;
        }
        var HRS = sensorIter.next();
        if (
          HRS != null &&
          HRS.heartRate != Toybox.ActivityMonitor.INVALID_HR_SAMPLE
        ) {
          hr = HRS.heartRate;
        } else {
          return;
        }
      } else {
        return;
      }
    }
    dc.drawText(
      wmid,
      hearty,
      heartfont,
      hr.format("%d"),
      Gfx.TEXT_JUSTIFY_CENTER
    );
  }
}
