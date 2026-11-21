import Toybox.Lang;
import Toybox.Math;

// Evaluates the expressions typed on the dial: numbers, + - * x / ^ and
// parentheses. '^' binds tightest and, like unary minus, is applied left to
// right, so -2^2 is 4.
module Calc {
  var _chars as Array<Char> = [];
  var _pos as Number = 0;

  // Returns null when the expression is invalid or the result is not finite.
  function evaluate(text as String) as Double? {
    _chars = text.toCharArray();
    _pos = 0;
    var value = sum();
    skipSpaces();
    _chars = [];
    // x - x is 0 for finite numbers and NaN for infinity and NaN.
    if (value == null || _pos < text.length() || value - value != 0.0d) {
      return null;
    }
    return value;
  }

  // Text for a result that evaluate() accepts again: at most six decimals,
  // without trailing zeros or exponent.
  function format(value as Double) as String {
    if (value == Math.round(value)) {
      return value.format("%.0f");
    }
    var text = value.format("%.6f");
    var chars = text.toCharArray();
    var end = chars.size();
    while (end > 0 && chars[end - 1] == '0') {
      end--;
    }
    if (end > 0 && chars[end - 1] == '.') {
      end--;
    }
    return text.substring(0, end) as String;
  }

  function sum() as Double? {
    var value = product();
    while (value != null) {
      var op = peek();
      if (op != '+' && op != '-') {
        break;
      }
      _pos++;
      var rhs = product();
      if (rhs == null) {
        return null;
      }
      value = op == '+' ? value + rhs : value - rhs;
    }
    return value;
  }

  function product() as Double? {
    var value = power();
    while (value != null) {
      var op = peek();
      if (op != '*' && op != 'x' && op != '/') {
        break;
      }
      _pos++;
      var rhs = power();
      if (rhs == null || (op == '/' && rhs == 0.0d)) {
        return null;
      }
      value = op == '/' ? value / rhs : value * rhs;
    }
    return value;
  }

  function power() as Double? {
    var value = unary();
    while (value != null && peek() == '^') {
      _pos++;
      var rhs = unary();
      if (rhs == null) {
        return null;
      }
      value = Math.pow(value, rhs).toDouble();
    }
    return value;
  }

  function unary() as Double? {
    if (peek() == '-') {
      _pos++;
      var value = unary();
      return value == null ? null : -value;
    }
    return primary();
  }

  function primary() as Double? {
    if (peek() == '(') {
      _pos++;
      var value = sum();
      if (value == null || peek() != ')') {
        return null;
      }
      _pos++;
      return value;
    }
    return number();
  }

  function number() as Double? {
    skipSpaces();
    var value = 0.0d;
    var scale = 0.0d;
    var digits = 0;
    while (_pos < _chars.size()) {
      var c = _chars[_pos];
      if (c >= '0' && c <= '9') {
        var digit = (c.toNumber() - '0'.toNumber()).toDouble();
        if (scale == 0.0d) {
          value = value * 10 + digit;
        } else {
          value += digit * scale;
          scale /= 10;
        }
        digits++;
      } else if (c == '.' && scale == 0.0d) {
        scale = 0.1d;
      } else {
        break;
      }
      _pos++;
    }
    return digits > 0 ? value : null;
  }

  // Next significant character, or a space at the end of the input.
  function peek() as Char {
    skipSpaces();
    return _pos < _chars.size() ? _chars[_pos] : ' ';
  }

  function skipSpaces() as Void {
    while (_pos < _chars.size() && (_chars[_pos] == ' ' || _chars[_pos] == '\t' || _chars[_pos] == '\n')) {
      _pos++;
    }
  }
}
