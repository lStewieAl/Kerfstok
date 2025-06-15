using Toybox.WatchUi;
using Toybox.Lang;
using Toybox.Math;
using Toybox.StringUtil;
import Toybox.Lang;

class OperatorDelegate extends WatchUi.BehaviorDelegate {
  var nums as EntryData;
  var straal2;
  function initialize(n as EntryData) {
    nums = n;
    straal2 = Math.pow(height / 4.0, 2);
    BehaviorDelegate.initialize();
  }
  function onBack() {
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    return true;
  }

  function onTap(clickEvent) {
    if (clickEvent.getType() == CLICK_TYPE_TAP) {
      fromback = false;
      var co = clickEvent.getCoordinates();
      var x = co[0] - width / 2;
      var y = co[1] - height / 2;
      var rsq = x * x + y * y;
      var len = operators.size();
      var mo;
      if (rsq < straal2) {
        if (y < 0) {
          var getstr = nums.toString();
          var floval = getstr.toFloat();
          if (floval != null) {
            var num = Math.round(floval);
            var str = num.format("%d");
            nums.nums = str.toCharArray();
          } else {
            beep4();
          }
        } else {
          var str = calcer(nums.nums);
          if (str != null) {
            nums.nums = str.toCharArray();
          }
        }
      } else {
        var part = 360 / len;
        var hpart = part / 2;
        var arc = 180.0d * (1.0d - Math.atan2(x, y) / Math.PI);

        if (arc < hpart || arc > 360 - hpart) {
          nums.nums = [];
        } else {
          mo = Math.floor((arc + hpart) / part).toNumber();

          var chr = operators[mo].toCharArray();
          if (nums.size() + chr.size() <= nummax) {
            nums.addAll(chr);
            if (!(chr.size() == 1 && chr[0] == '.')) {
              operated = true;
            }
          } else {
            beep2();
          }
        }
      }
      WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
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
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    return true;
  }
  
  function onNextPage() {
    return true;
  }

  function onMenu() {
    return true;
  }
}
