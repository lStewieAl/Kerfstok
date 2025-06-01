using Toybox.WatchUi;
using Toybox.Application.Storage;
using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Application.Properties as Prop;
using Toybox.Timer;
using Toybox.Time;
using Toybox.System;
using Toybox.Communications;
var height, width, wmid;
var wnumfont, hnumfont, xnumbers, hmidnum;
var screenShape;

var memlab = ["M0", "M1", "M2", "M3"];
var memnum = [];

var vars = [
  "Label1",
  "Carbohydrat",
  "Dextro",
  "Label4",
  "Cycle",
  "Walk",
  "Label7",
  "Label8",
];
var precvars = [0.5, 1, 1, 0.5, 1, 1, 0.0, 0.0, 0.0];
var varnr = 7;
var onscr;
var from = 0;

var speedunits = "km/h";
var distanceunits = "km";
var toshowspeed = (60.0 * 60.0) / 1000.0;
var toshowdistance = 1.0 / 1000.0;
var showdistanceunit = false;

var isAlarmActive = false;

class init {
  const mile = 1609.34;

  function timerCallback() as Void {
    toshow = 1;
    WatchUi.requestUpdate();
    if (isAlarmActive) {
      generatealarm();
    }
  }

  var inttimer = null,
    timerstarter = null;
  const secint = 10;
  function settimer() {
    timerstarter = new Timer.Timer();
    timerstarter.start(
      method(:timesetter),
      (secint - (System.getClockTime().sec % secint)) * 1000,
      false
    );
  }

  function timesetter() as Void {
    inttimer = new Timer.Timer();
    inttimer.start(method(:timerCallback), secint * 1000, true);
    WatchUi.requestUpdate();
  }

  function stoptimer() {
    if (timerstarter != null) {
      timerstarter.stop();
      timerstarter = null;
    }
    if (inttimer != null) {
      inttimer.stop();
      inttimer = null;
    }
  }

  function getvars() {
    var tmpvars = Storage.getValue("labels");
    if (tmpvars != null && tmpvars.size() > 0) {
      vars = tmpvars;
    }
    tmpvars = Storage.getValue("preclabels");
    if (tmpvars != null && tmpvars.size() > 0) {
      precvars = tmpvars;
    }
    setvarnr();
    var maxon = edge1040 || edgeexplore2 ? 6 : 4;
    onscr = varnr > maxon ? maxon : varnr;
    rows = maxon;
  }

  function getsettings() {
    from = 0;

    var tmpcuts = Storage.getValue("shortcuts");
    if (tmpcuts != null) {
      shortcuts = tmpcuts;
    }

    numset = [];
    for (var labnr = 0; labnr < memlab.size(); labnr++) {
      var num = Storage.getValue("memnum" + labnr);
      if (num != null && num has :length && num.length() != 0) {
        numset.add(labnr);
        memnum.add(num.toCharArray());
      } else {
        memnum.add([]);
      }
    }
    getvars();
  }

  function initdisplay() {
    var settings = System.getDeviceSettings();
    screenShape = settings.screenShape;
    if (settings.paceUnits == System.UNIT_STATUTE) {
      toshowspeed = 60.0 * 60.0 * toshowdistance;
      speedunits = "mph";
    }
    if (settings.distanceUnits == System.UNIT_STATUTE) {
      toshowdistance = 1.0 / mile;
      lapsize = 5.0 * mile;
      distanceunits = "mi";
    }
    if (settings.distanceUnits == settings.paceUnits) {
      showdistanceunit = true;
    }

    settimer();
    getmonths();
  }

  function initall() {
    storageinit();
    getsettings();
    for (var i = 0; i < 2; i++) {
      lowestchange[i] = getStoragelowestchange(i);
    }
    updateThemeColors(Storage.getValue("reversecolor"));
    initdisplay();
    readsports();
    setglunit(Storage.getValue("glunits"));
    if (!glucoactive || lowestchange[0] == null) {
      startglucose();
    }
  }
}
