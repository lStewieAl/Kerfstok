using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics as Gfx;
using Toybox.Math;
using Toybox.Lang;

class AskDelegate extends WatchUi.BehaviorDelegate {
  function initialize() {
    BehaviorDelegate.initialize();
  }

  function onResponse(response) as Lang.Boolean {
    return false;
  }

  function onBack() {
   	onResponse(1);
   	WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    return true;
  }

  function onNextPage() {
    onResponse(0);
   	WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); 
    return true;
  }

  function onTap(clickEvent) {
    if (clickEvent.getType() == CLICK_TYPE_TAP) {
      var co = clickEvent.getCoordinates();
      var y = co[1];
   		var x=co[0];
      if (y * 2 > height) {
        // user clicked on lower half of the screen
        onResponse(x*2>width);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
      }
    }
    return true;
  }

  function onKey(keyEvent as Toybox.WatchUi.KeyEvent) as Lang.Boolean {
    if (AppSettings.isAlarmActive) {
      stopalarm();
    }
    return true;
  }

  function onPreviousPage() {
    return true;
  }
  
  function onMenu() {
    return true;
  }
}
