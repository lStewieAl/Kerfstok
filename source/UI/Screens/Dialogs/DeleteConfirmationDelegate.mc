using Toybox.WatchUi;
using Toybox.Lang;

class DeleteConfirmationDelegate extends WatchUi.ConfirmationDelegate {
  var base;
  var datanum;

  function initialize(basein, dat) {
    ConfirmationDelegate.initialize();
    base = basein;
    datanum = dat;
  }

  function onResponse(response) as Lang.Boolean {
    if (response == WatchUi.CONFIRM_YES) {
      delete(base, datanum);
    }
    return true;
  }
}
