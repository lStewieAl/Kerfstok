using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics as Gfx;
using Toybox.Math;
import Toybox.Lang;

var numset as Array<Number> = [];
class RetrieveDelegate extends WatchUi.BehaviorDelegate {
  var from;
  var nums as EntryData;
  var onscr = 4;
  function initialize(n as EntryData) {
    nums = n;
    if (numset.size() < 1) {
      from = 0;
    } else {
      from = ((numset.size() - 1) / onscr) * onscr;
    }
    BehaviorDelegate.initialize();
  }

  function onBack() {
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    return true;
  }

  function onTap(clickEvent) {
    if (clickEvent.getType() == CLICK_TYPE_TAP) {
      var co = clickEvent.getCoordinates();
      var id = (co[1] * onscr) / height + from;
      if (id < numset.size()) {
        fromback = false;
        nums.addAll(memnum[numset[id]]);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
      } else {
        beep4();
      }
      return true;
    }
    return false;
  }

  function onKey(keyEvent) {
    if (AppSettings.isAlarmActive) {
      stopalarm();
    }
    return true;
  }

  function onPreviousPage() {
    from = from < onscr ? 0 : from - onscr;
    WatchUi.requestUpdate();
    return true;
  }

  function onNextPage() {
    var grens = numset.size() - onscr;
    if (from >= grens) {
      WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
      return true;
    }
    from = from + onscr;
    WatchUi.requestUpdate();
    return true;
  }
  
  function onMenu() {
    return true;
  }
}
