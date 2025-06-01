using Toybox.WatchUi;
using Toybox.System;
using Toybox.Lang;
using Toybox.Activity;
using Toybox.ActivityRecording;

class MainMenuDelegate extends WatchUi.BehaviorDelegate {
  function initialize() {
    BehaviorDelegate.initialize();
  }

  function onBack() as Lang.Boolean {
    WatchUi.pushView(
      new AskView("", "Quit?"),
      new ExitConfirmationDelegateMainMenu(),
      WatchUi.SLIDE_IMMEDIATE
    );
    return true;
  }

  function onKey(keyEvent as WatchUi.KeyEvent) as Lang.Boolean {
    if (alarmactive) {
      stopalarm();
    } else {
      askstopsport();
    }
    return true;
  }

  function onTap(clickEvent as WatchUi.ClickEvent) as Lang.Boolean {
    var co = clickEvent.getCoordinates();
    var id = (co[1] * firstrows) / height;
    switch (id) {
      case 0:
        WatchUi.pushView(
          new VarView(),
          new VarDelegate(new todial()),
          WatchUi.SLIDE_IMMEDIATE
        );
        break;
      case 1:
        if (storageid[0] > 0 || storageid[1] > 0) {
          WatchUi.pushView(
            new HistView(),
            new HistDelegate(),
            WatchUi.SLIDE_IMMEDIATE
          );
        }
        break;
      case 2:
        WatchUi.pushView(
          new GlucoseView(),
          new GlucoseDelegate(),
          WatchUi.SLIDE_IMMEDIATE
        );
        break;
      case 3:
        if (Toybox has :ActivityRecording) {
          if (activityrecord == null || activityrecord.isRecording() == false) {
            sportdel = new SportStartDelegate();
            var view = new SportStartView();
            WatchUi.pushView(view, sportdel, WatchUi.SLIDE_IMMEDIATE);
          } else {
            var spoview = new SportView();
            WatchUi.pushView(
              spoview,
              new SportDelegate(spoview),
              WatchUi.SLIDE_IMMEDIATE
            );
          }
        }
        break;
    }
    return true;
  }

  function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Lang.Boolean { 
    if (swipeEvent.getDirection() == WatchUi.SWIPE_LEFT) {
      WatchUi.pushView(
        new VarView(),
        new VarDelegate(new todial()),
        WatchUi.SLIDE_IMMEDIATE
      );
      return true;
    }
    return false;
  }
}
