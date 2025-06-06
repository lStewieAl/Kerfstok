using Toybox.WatchUi;
using Toybox.Lang;

class FarWayConfirmationDelegate extends WatchUi.ConfirmationDelegate {
  var base;
  var datanum;
  var val;
  function initialize(basein, datanumin, valin) {
    base = basein;
    datanum = datanumin;
    val = valin;
    ConfirmationDelegate.initialize();
  }

  function onResponse(response) as Lang.Boolean {
    if (response == WatchUi.CONFIRM_YES) {
      moveondate(base, datanum, val);
      havenums(base);
      WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
    return true;
  }
}
