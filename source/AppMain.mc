import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;

using Toybox.StringUtil;
using Toybox.Application.Storage;
using Toybox.Position;

function receivecolor(num) as Void {
  Storage.setValue("reversecolor", num);
  updateThemeColors(num);
  Communications.transmit([COLORBLACK], null, new CommListener());
}

function ackReceived() as Void {
  Communications.transmit([COLORBLACK], null, new CommListener());
}

var initer = null;
var venusq = false;
var venu = false;
var venusq2 = false;
var fenix7 = false;
var fenix8 = false;
var fenixe = false;
var marq2 = false;
var edgeexplore2 = false;
var edge1040 = false;
var edge830 = false;
var edge840 = false;
var fr965 = false;
var fr165 = false;
var mk3 = false;
class AppMain extends Application.AppBase {
  public function onMailReceived(mailIter as MailboxIterator) as Void {
    var mail = mailIter.next();

    while (mail != null) {
      processIncomingMessage(mail);
      mail = mailIter.next();
    }

    Communications.emptyMailbox();
    WatchUi.requestUpdate();
  }

  public function onPhoneAppMessageReceived(msg as PhoneAppMessage) as Void {
    processIncomingMessage(msg.data);
    WatchUi.requestUpdate();
  }

  function initCommsListeners() as Void {
    if (Communications has :registerForPhoneAppMessages) {
      Communications.registerForPhoneAppMessages(method(:onPhoneAppMessageReceived));
    } else if (Communications has :setMailboxListener) {
      Communications.setMailboxListener(method(:onMailReceived));
    }
  }

  function determineWatchVersion() as Void {
    if (WatchUi.loadResource(Rez.Strings.venusq).equals("y")) { venusq = true; return; }
    if (WatchUi.loadResource(Rez.Strings.venusq2).equals("y")) { venusq2 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.venu).equals("y")) { venu = true; return; }
    if (WatchUi.loadResource(Rez.Strings.fenix7).equals("y")) { fenix7 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.marq2).equals("y")) { marq2 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.edgeexplore2).equals("y")) { edgeexplore2 = true; histrows = 7; return; }
    if (WatchUi.loadResource(Rez.Strings.edge830).equals("y")) { edge830 = true; histrows = 5; return; }
    if (WatchUi.loadResource(Rez.Strings.fr965).equals("y")) { fr965 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.mk3).equals("y")) { mk3 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.fenix8).equals("y")) { fenix8 = true; return; }
    if (WatchUi.loadResource(Rez.Strings.fenixe).equals("y")) { fenixe = true; return; }
    if (WatchUi.loadResource(Rez.Strings.edge1040).equals("y")) { edge1040 = true; histrows = 8; return; }
    if (WatchUi.loadResource(Rez.Strings.edge840).equals("y")) { edge840 = true; edge830 = true; histrows = 5; return; }
    if (WatchUi.loadResource(Rez.Strings.fr165).equals("y")) { fr965 = true; fr165 = true; }
  }

  function initialize() {
    AppBase.initialize();
    determineWatchVersion();
    initer = new init();
    initer.initall();
    initCommsListeners();
  }

  function onStop(state) as Void {
    stopglucose();
    Storage.setValue("glunits", glunits);
    for (var i = 0, n = numset.size(); i < n; i++) {
      var nr = numset[i];
      if (memnum[nr].size()) {
        Storage.setValue(
          "memnum" + nr,
          StringUtil.charArrayToString(memnum[nr])
        );
      } else {
        Storage.deleteValue("memnum" + nr);
      }
    }
  }

  // A GPS screen is often shown when starting or stopping the app. And the battery drains quickly.
  function getInitialView() {
    return [new MainMenuView(), new MainMenuDelegate()];
  }
}
