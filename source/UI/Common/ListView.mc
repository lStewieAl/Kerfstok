import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// A paged list of texts below the clock. Fewer items than fit on a page are
// spread over the screen.
class ListView extends WatchUi.View {
  var items as Array<String>;
  private var _font as Graphics.FontType;
  private var _first as Number = 0;

  // Starts at the page that contains item `start`.
  function initialize(items as Array<String>, font as Graphics.FontType, start as Number) {
    View.initialize();
    self.items = items;
    _font = font;
    var rows = rowCount();
    _first = start > 0 ? (start / rows) * rows : 0;
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    Ui.begin(dc);
    Ui.drawClock(dc);
    var rows = rowCount();
    for (var i = 0; i < rows && _first + i < items.size(); i++) {
      dc.drawText(Ui.cx, ((i + 1) * Ui.height) / (rows + 1), _font, items[_first + i], Ui.CENTER);
    }
  }

  // Index of the item at screen height y, or null.
  function itemAt(y as Number) as Number? {
    var index = _first + Ui.rowAt(y, rowCount());
    return index < items.size() ? index : null;
  }

  // Moves a page forward (+1) or back (-1). Returns false at either end.
  function turnPage(direction as Number) as Boolean {
    var first = _first + direction * rowCount();
    if (first < 0 || first >= items.size()) {
      return false;
    }
    _first = first;
    WatchUi.requestUpdate();
    return true;
  }

  private function rowCount() as Number {
    var count = items.size();
    return count < 1 ? 1 : count < Ui.listRows ? count : Ui.listRows;
  }
}

// Subclasses implement onItem().
class ListDelegate extends BaseDelegate {
  protected var _view as ListView;

  function initialize(view as ListView) {
    BaseDelegate.initialize();
    _view = view;
  }

  function onItem(index as Number) as Void {}

  function onTap(event as WatchUi.ClickEvent) as Boolean {
    var index = _view.itemAt(event.getCoordinates()[1]);
    if (index == null) {
      Haptics.bump();
    } else {
      onItem(index);
    }
    return true;
  }

  function onNextPage() as Boolean {
    if (!_view.turnPage(1)) {
      Haptics.bump();
    }
    return true;
  }

  function onPreviousPage() as Boolean {
    if (!_view.turnPage(-1)) {
      Haptics.bump();
    }
    return true;
  }
}
