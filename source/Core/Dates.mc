import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

module Dates {
  var _months as Array<String>? = null;

  // Localized abbreviated month name, month0 from 0 to 11.
  function monthName(month0 as Number) as String {
    if (_months == null) {
      var names = new [12] as Array<String>;
      var options = { :year => 2020, :month => 1, :day => 4, :hour => 0 };
      for (var i = 0; i < 12; i++) {
        options[:month] = i + 1;
        names[i] = Gregorian.info(Gregorian.moment(options), Time.FORMAT_MEDIUM).month as String;
      }
      _months = names;
    }
    return (_months as Array<String>)[month0];
  }

  function daysInMonth(month as Number, year as Number) as Number {
    if (month == 2) {
      var leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
      return leap ? 29 : 28;
    }
    return month == 4 || month == 6 || month == 9 || month == 11 ? 30 : 31;
  }

  function localInfo(time as Number) as Gregorian.Info {
    return Gregorian.info(new Time.Moment(time), Time.FORMAT_SHORT);
  }

  // Returns `time` with one local calendar field (:year, :month, :day, :hour
  // or :minute) replaced, or null when the value is out of range. Two-digit
  // years are taken as 20xx. A day that does not exist in the new month is
  // moved to the last day of that month.
  function withField(time as Number, field as Symbol, value as Number) as Number? {
    var info = localInfo(time);
    var year = info.year as Number;
    var month = info.month as Number;
    var day = info.day as Number;
    var hour = info.hour;
    var minute = info.min;
    switch (field) {
      case :year:
        year = value >= 0 && value < 39 ? value + 2000 : value;
        if (year < 1970 || year > 2038) {
          return null;
        }
        break;
      case :month:
        if (value < 1 || value > 12) {
          return null;
        }
        month = value;
        break;
      case :day:
        if (value < 1 || value > daysInMonth(month, year)) {
          return null;
        }
        day = value;
        break;
      case :hour:
        if (value < 0 || value > 23) {
          return null;
        }
        hour = value;
        break;
      case :minute:
        if (value < 0 || value > 59) {
          return null;
        }
        minute = value;
        break;
      default:
        return null;
    }
    var maxDay = daysInMonth(month, year);
    if (day > maxDay) {
      day = maxDay;
    }
    // Both moments are built the same way, so their difference is the
    // change in local time regardless of the time zone.
    var before = calendarMoment(info.year as Number, info.month as Number, info.day as Number, info.hour, info.min);
    var after = calendarMoment(year, month, day, hour, minute);
    return time + after - before;
  }

  function calendarMoment(year as Number, month as Number, day as Number, hour as Number, minute as Number) as Number {
    return Gregorian.moment({
      :year => year,
      :month => month,
      :day => day,
      :hour => hour,
      :minute => minute,
      :second => 0,
    }).value();
  }
}
