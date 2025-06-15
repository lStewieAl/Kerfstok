using Toybox.WatchUi;
using Toybox.System;
using Toybox.Graphics as Gfx;
using Toybox.Math;
import Toybox.Lang;

class CutDelegate extends WatchUi.BehaviorDelegate {
  hidden var from = 0;
  hidden var onscr = 4;
  hidden var nums as Array<Char>;
  function initialize(n as Array<Char>) {
    nums = n;
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
      if (id < shortcuts.size()) {
        fromback = false;
        nums.addAll(shortcuts[id][1].toCharArray());
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
      }
    }
    return true;
  }

  function onKey(keyEvent) {
    if (AppSettings.isAlarmActive) {
      stopalarm();
    }
    return true;
  }

  function onPreviousPage() {
    from = from > 0 ? from - onscr : 0;
    WatchUi.requestUpdate();
    return true;
  }

  function onNextPage() {
    var grens = shortcuts.size() - onscr;
    from = from < grens ? from + onscr : from;
    WatchUi.requestUpdate();
    return true;
  }
  
  function onMenu() {
    WatchUi.pushView(
      new HistView(),
      new HistDelegate(),
      WatchUi.SLIDE_IMMEDIATE
    );
    return true;
  }
}
