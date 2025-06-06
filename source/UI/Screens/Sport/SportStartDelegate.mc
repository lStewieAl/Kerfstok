using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Math;
using Toybox.Time;
using Toybox.ActivityRecording;
using Toybox.Position;
using Toybox.FitContributor as Fit;
using Toybox.Application.Storage;

var glucoseUnit = 0;
var lapstart = 0;

var positionInfo = null;
var activityInfo = null;
var lapsize = 5000.0;
var lapstr1 = "";
var lapstr2 = "";
function mklapstr(ver) {
  var min = ver / 60;
  var sec = ver % 60;
  if (min < 60) {
    lapstr2 = min.format("%02d") + ":" + sec.format("%02d");
  } else {
    var hour = min / 60;
    min %= 60;
    lapstr2 = hour + ":" + min.format("%02d") + ":" + sec.format("%02d");
  }
}

class SportStartDelegate extends WatchUi.BehaviorDelegate {
  var nextlap;
  var energyField = null;
  const glunitstr = ["mg/dL", "mmol/L"];
  var lapnr = 0;
  var subsport = -1;
  var laplen;
  function setlaplen(val, sub) {
    var lapkey = val + "lap" + sub;
    laplen = Storage.getValue(lapkey);
    if (laplen == null) {
      laplen = lapsize;
    }
  }

  function setsubsport(id) {
    subsport = id;
    var val = nextsport[splen];
    var key = "ss" + val;
    Storage.setValue(key, id);

    var spo = sports[val];
    var sub = spo[1][subsport];
    setlaplen(val, sub);
  }

  function getsubsport() {
    var val = nextsport[splen];
    var spo = sports[val];
    var sub = ActivityRecording.SUB_SPORT_GENERIC;
    if (spo.size() > 1) {
      var key = "ss" + val;
      var subsp = Storage.getValue(key);
      if (subsp != null) {
        subsport = subsp;
      } else {
        subsport = 0;
      }
      sub = spo[1][subsport];
    } else {
      subsport = -1;
    }
    setlaplen(val, sub);
  }

  function initialize() {
    BehaviorDelegate.initialize();
    Position.enableLocationEvents(
      Position.LOCATION_CONTINUOUS,
      method(:onPosition)
    );
    getsubsport();
  }

  function onBack() {
    if (activityrecord == null) {
      Position.enableLocationEvents(
        Position.LOCATION_DISABLE,
        method(:onPosition)
      );
      positionInfo = null;
    }
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);

    return true;
  }

  var prevautolap = 0;
  function onPosition(info as Position.Info) as Void {
    positionInfo = info;
    activityInfo = Activity.getActivityInfo();
    if (activityInfo != null) {
      if (activityInfo.elapsedDistance != null) {
        var dist = activityInfo.elapsedDistance;
        if (dist > nextlap && activityrecord.addLap()) {
          clearBeepPattern();
          var nu = Time.now().value();
          mklapstr(nu - prevautolap);
          prevautolap = nu;
          ++lapnr;
          lapstr1 = "A " + lapnr;
          endlap = nu + 10;
          nextlap += laplen;
        }
      }
      if (energyField != null) {
        if (
          activityInfo has :energyExpenditure &&
          activityInfo.energyExpenditure != null
        ) {
          energyField.setData(activityInfo.energyExpenditure);
        }
      }
    }
    WatchUi.requestUpdate();
  }

  function stopsport() {
    if (activityrecord != null) {
      Position.enableLocationEvents(
        Position.LOCATION_DISABLE,
        method(:onPosition)
      );
      glucoseDataField = null;
      energyField = null;
      activityrecord.save();
      activityrecord = null;
      positionInfo = null;
      if (initer != null) {
        initer.settimer();
      }
      WatchUi.requestUpdate();
    }
  }

  function startsport() {
    if (activityrecord == null || activityrecord.isRecording() == false) {
      initer.stoptimer();
      var sel = nextsport[splen];
      var spor = sports[sel];
      var subsp =
        subsport < 0 ? ActivityRecording.SUB_SPORT_GENERIC : spor[1][subsport];
      activityrecord = ActivityRecording.createSession({
        :name => spor[0],
        :sport => sel,
        :subSport => subsp,
      });
      glucoseDataField = activityrecord.createField(
        "Glucose",
        glucoseUnit,
        Fit.DATA_TYPE_FLOAT,
        { :mesgType => Fit.MESG_TYPE_RECORD, :units => glunitstr[glucoseUnit] }
      );

      energyField = activityrecord.createField(
        "Energy",
        2,
        Fit.DATA_TYPE_FLOAT,
        { :mesgType => Fit.MESG_TYPE_RECORD, :units => "kcal/min" }
      );
      if (laplen > 0.0) {
        nextlap = laplen;
      } else {
        nextlap = 9999999.0;
      }
      lapstart = Time.now().value();
      prevautolap = lapstart;
      lapstr1 = "";
      lapstr2 = "";
      activityrecord.start();

      var spoview = new SportView();
      WatchUi.switchToView(
        spoview,
        new SportDelegate(spoview),
        WatchUi.SLIDE_IMMEDIATE
      );
    }
  }

  function onTap(clickEvent) {
    var co = clickEvent.getCoordinates();

    var id = (co[1] * 4) / height;
    var x = co[0];
    switch (id) {
      case 0:
        getnum(
          new lapChange(laplen * toshowdistance),
          distanceunits + " (0=no)"
        );
        break;
      case 1:
        var view = new SportListView(nextsport[splen], splen);
        WatchUi.pushView(
          view,
          new SportListDelegate(view),
          WatchUi.SLIDE_IMMEDIATE
        );
        break;
      case 2:
        var val = nextsport[splen];
        var spo = sports[val];
        if (subsport >= 0) {
          var saind = (subsport / rows) * rows;
          var sview = new SubSportView(spo[1], saind);
          WatchUi.pushView(
            sview,
            new SubSportDelegate(sview),
            WatchUi.SLIDE_IMMEDIATE
          );
        }
        break;
      case 3:
        var el = (x * 2) / width;
        switch (el) {
          case 1:
            startsport();
            break;
        }
    }
    return true;
  }

  function onKey(keyEvent) {
    if (AppSettings.isAlarmActive) {
      stopalarm();
    } else {
      startsport();
    }
    return true;
  }

  function onSwipe(swipe) {
    if (swipe.getDirection() == WatchUi.SWIPE_LEFT) {
      return true;
    }
    return false;
  }

  function onPreviousPage() {
    return true;
  }

  function onNextPage() {
    return true;
  }

  (:debug)
  function onMenu() {
    return true;
  }
}

class lapChange {
  var laps;
  function initialize(lapin) {
    laps = lapin;
  }
  function orig() {
    return laps.format("%.2f");
  }

  function storedata(numstr) {
    var floval = numstr.toFloat();
    if (floval == null) {
      beep3();
      return false;
    }
    var laplen = floval / toshowdistance;

    sportdel.laplen = laplen;
    var sel = nextsport[splen];
    var spor = sports[sel];
    var subsport = sportdel.subsport;
    var subsp =
      subsport < 0 ? ActivityRecording.SUB_SPORT_GENERIC : spor[1][subsport];
    var lapkey = sel + "lap" + subsp;
    Storage.setValue(lapkey, laplen);
    return true;
  }
}
