using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Lang;

class ExitConfirmationDelegateMainMenu extends AskDelegate {
  function initialize() {
    AskDelegate.initialize();
  }

  function onResponse(response) as Lang.Boolean {
    if (response == WatchUi.CONFIRM_YES) {
      if (sportdel != null) {
        sportdel.stopsport();
      }
      WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
    return true;
  }
}