import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class MainMenuView extends WatchUi.View {
  static const ROWS = 4;

  function initialize() {
    View.initialize();
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    Ui.drawClock(dc);
    var rows = ["Input", hasRecords() ? "View" : "", "Watch face", "Sport"];
    for (var i = 0; i < ROWS; i++) {
      dc.drawText(Ui.cx, ((i + 1) * Ui.height) / (ROWS + 1), Graphics.FONT_MEDIUM, rows[i], Ui.CENTER);
    }
  }

  static function hasRecords() as Boolean {
    return Records.ends[0] > 0 || Records.ends[1] > 0;
  }
}

class MainMenuDelegate extends BaseDelegate {
  function initialize() {
    BaseDelegate.initialize();
  }

  function onButton(key as WatchUi.Key) as Boolean {
    if (!askStopSport() && key == WatchUi.KEY_ENTER) {
      openInput();
    }
    return true;
  }

  function onTap(event as WatchUi.ClickEvent) as Boolean {
    switch (Ui.rowAt(event.getCoordinates()[1], MainMenuView.ROWS)) {
      case 0:
        openInput();
        break;
      case 1:
        if (MainMenuView.hasRecords()) {
          openHistory();
        }
        break;
      case 2:
        Ui.pop();
        break;
      case 3:
        openSport();
        break;
    }
    return true;
  }

  // All labels.
  function onSwipeLeft() as Boolean {
    openLabelPicker(LabelDelegate.NEW_RECORD);
    return true;
  }

  // Straight to the insulin dial; the first time the user may have to pick
  // the insulin label.
  private function openInput() as Void {
    var insulin = Labels.insulin;
    if (insulin != null) {
      openNewRecordDial(insulin);
    } else {
      openLabelPicker(LabelDelegate.PICK_INSULIN);
    }
  }

  private function openSport() as Void {
    if (!SportSession.isSupported()) {
      return;
    }
    if (SportSession.isRecording()) {
      Ui.push(new SportView(), new SportDelegate());
    } else {
      Ui.push(new SportStartView(), new SportStartDelegate());
    }
  }
}
