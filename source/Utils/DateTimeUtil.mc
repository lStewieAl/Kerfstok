import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Lang;
import Toybox.StringUtil;

module DateTimeUtil {
  public var monthNames as Lang.Array<Lang.String> =
    new [12] as Lang.Array<Lang.String>;
  public function initializeMonths() as Void {
    if (monthNames != null) {
      return;
    }
    var options = { :year => 2020, :month => 1, :day => 4, :hour => 0 };
    for (var i = 0; i < 12; i++) {
      options[:month] = i + 1;
      var date = Gregorian.moment(options);
      var da = Gregorian.info(date, Time.FORMAT_MEDIUM);
      monthNames[i] = da.month;
    }
  }

  public function init() as Void {
    initializeMonths();
  }
}
