using Toybox.WatchUi;
using Toybox.Lang;

class CancelConfirmationDelegate extends WatchUi.ConfirmationDelegate {
  function initialize() {
    ConfirmationDelegate.initialize();
  }

  function onResponse(response) as Lang.Boolean {
    if (response == WatchUi.CONFIRM_YES) {
      WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
    return true;
  }
}
