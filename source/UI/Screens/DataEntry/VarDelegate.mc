using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Math;
using Toybox.Time;
class todial {
  function vardone(id) {
    getnum(new numStore(id), vars[id]);
  }

  function onleft() {
    WatchUi.pushView(
      new HistView(),
      new HistDelegate(),
      WatchUi.SLIDE_IMMEDIATE
    );
  }
}

class VarDelegate extends WatchUi.BehaviorDelegate {
  var doer;
  function initialize(don) {
    doer = don;
    BehaviorDelegate.initialize();
  }

  function onBack() {
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    return true;
  }

  function onTap(clickEvent) {
    var co = clickEvent.getCoordinates();
    var id = (co[1] * onscr) / height + from;
    if (id < varnr) {
      doer.vardone(id);
    }
    return true;
  }

  function onKey(keyEvent) {
    if (AppSettings.isAlarmActive) {
      stopalarm();
    } else {
      doer.onleft();
    }
    return true;
  }

  function onSwipe(swipe) {
    if (swipe.getDirection() == WatchUi.SWIPE_LEFT) {
      doer.onleft();
      return true;
    }
    return false;
  }

  function onPreviousPage() {
    from = from > 0 ? from - onscr : 0;
    WatchUi.requestUpdate();
    return true;
  }

  function onNextPage() {
    var grens = varnr - onscr;
    from = from < grens ? from + onscr : from;
    WatchUi.requestUpdate();
    return true;
  }
  
  (:debug)
  function onMenu() {
    var menu = new WatchUi.Menu();
    menu.addItem("Send Labels", 0 as Lang.Symbol);
    menu.addItem("Send Nums", 1 as Lang.Symbol);
    menu.addItem("Set lastnum", 2 as Lang.Symbol);
    menu.addItem("Make data", 3 as Lang.Symbol);
    menu.addItem("Test Labels", 4 as Lang.Symbol);
    menu.addItem("Test Show", 5 as Lang.Symbol);
    WatchUi.pushView(menu, new SendMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
    return true;
  }
}
