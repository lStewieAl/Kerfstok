import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

// Messages exchanged with Juggluco on the phone. A message is a bare type or
// an array [type, arguments...]; the types are defined in consts.mc.
module Comm {
  // Records per message; larger batches run out of memory.
  const MAX_BATCH = 50;

  class Listener extends Communications.ConnectionListener {
    function initialize() {
      Communications.ConnectionListener.initialize();
    }

    function onComplete() as Void {}

    function onError() as Void {
      System.println("Transmit failed");
    }
  }

  // Whether Juggluco is streaming glucose readings to us.
  var streaming as Boolean = false;
  // Set when the connection may have been lost while the app was inactive.
  var streamStale as Boolean = false;

  var _listener as Listener? = null;
  var _sendTimer as Timer.Timer? = null;

  function send(message as Array) as Void {
    if (_listener == null) {
      _listener = new Listener();
    }
    Communications.transmit(message as Application.PropertyValueType, null, _listener as Listener);
  }

  // Asks Juggluco to stream glucose; when the record sync state is unknown it
  // also asks for the records.
  function startStream() as Void {
    send([START, !Records.isSynced(0)]);
    streaming = true;
    streamStale = false;
  }

  function stopStream() as Void {
    if (streaming) {
      send([STOP]);
      streaming = false;
    }
  }

  function requestSync() as Void {
    if (!streaming) {
      startStream();
    }
  }

  // Sends the records changed on the watch.
  function sendChanges(base as Number) as Void {
    var low = Records.lowest[base];
    if (low == null) {
      requestSync();
    } else {
      sendRecords(HAVENUMS, base, low);
    }
  }

  // Sends the changes for base 0 shortly, so the screen can update first.
  function sendChangesSoon() as Void {
    if (_sendTimer == null) {
      _sendTimer = new Timer.Timer();
    }
    (_sendTimer as Timer.Timer).start(new Lang.Method(Comm, :onSendTimer), 50, false);
  }

  function onSendTimer() as Void {
    sendChanges(0);
  }

  // Sends a batch of records starting at `from` (or at the lowest unconfirmed
  // change when that is earlier).
  function sendRecords(type as Number, base as Number, from as Number) as Void {
    var low = Records.lowest[base];
    if (low == null) {
      requestSync();
      return;
    }
    if (from > low) {
      from = low;
    }
    var end = Records.ends[base];
    if (from >= end) {
      send([NOMORENUMS, base, end]);
      return;
    }
    var count = end - from;
    if (count > maxstorage) {
      count = maxstorage;
      from = end - count;
    }
    if (count > MAX_BATCH) {
      count = MAX_BATCH;
    }
    var records = new [count];
    for (var i = 0; i < count; i++) {
      records[i] = Records.raw(base, from + i);
    }
    send([type, base, count, from + count, records]);
  }

  function handle(message as Object?) as Void {
    if (!(message instanceof Array)) {
      if (message == LABELS) {
        send([LABELS, Labels.count(), Time.now().value(), Labels.names]);
      } else if (message == CLEAR) {
        Records.clear();
      }
      return;
    }
    var data = message as Array<Object?>;
    if (data.size() == 0 || !(data[0] instanceof Number)) {
      return;
    }
    // Every case validates its arguments: a malformed message must be
    // ignored, not crash the app.
    switch (data[0] as Number) {
      case START:
        startStream();
        break;
      case STOPALARM:
        Alarm.clear();
        send([GOTSTOPALARM]);
        break;
      case COLORBLACK:
        if (hasNumbers(data, 1)) {
          Application.Storage.setValue("reversecolor", data[1] as Number);
          Ui.setTheme(data[1] as Number);
          send([COLORBLACK]);
        }
        break;
      case GLUCOSE:
        if (hasArray(data, 1)) {
          Glucose.update(data[1] as Array<Object?>);
          if (streaming) {
            send([GOTGLUCOSE]);
          } else {
            startStream();
          }
        }
        break;
      case HEART:
        if (hasNumbers(data, 1)) {
          sendHeartRate(data[1] as Number);
        }
        break;
      case PUTLABELS:
        if (hasArray(data, 1)) {
          Labels.setNames(data[1] as Array<Object?>);
          send([RECEIVEDLABELS]);
        }
        break;
      case PUTPRECISION:
        if (hasArray(data, 1)) {
          Labels.setPrecisions(data[1] as Array<Object?>);
          send([RECEIVEDPRECISION]);
        }
        break;
      case SHORTCUTS:
        if (hasArray(data, 1)) {
          Memory.setShortcuts(data[1] as Array<Object?>);
          send([RECEIVEDCUTS]);
        }
        break;
      case GETENDNUM:
        if (hasNumbers(data, 1)) {
          var base = data[1];
          if (base == 0 && !Records.isSynced(0)) {
            send([COLORBLACK]);
          } else if (Records.isBase(base)) {
            send([SETENDNUM, base, Records.ends[base as Number]]);
          }
        }
        break;
      case NUMS:
        if (hasRecordArgs(data, 2)) {
          var base = data[1] as Number;
          if (base == 0 && !Records.isSynced(0)) {
            Records.lowest[0] = data[2] as Number;
          }
          sendRecords(NUMS, base, data[2] as Number);
        }
        break;
      case SETENDNUM:
        if (hasNumbers(data, 2)) {
          var base = data[1];
          if (Records.isBase(base) && (data[2] as Number) < Records.ends[base as Number]) {
            Records.setEnd(base as Number, data[2] as Number);
          }
          send([DIDSETENDNUM]);
        }
        break;
      case MORENUMS:
        if (hasRecordArgs(data, 2)) {
          Records.onMoreAvailable(data[1] as Number, data[2] as Number);
          sendRecords(NUMS, data[1] as Number, data[2] as Number);
        }
        break;
      case DELETED:
        if (hasRecordArgs(data, 2)) {
          Records.onDeleteConfirmed(data[1] as Number, data[2] as Number);
        }
        break;
      case DELETE:
        if (hasRecordArgs(data, 3)) {
          Records.removeRange(data[1] as Number, data[2] as Number, data[3] as Number);
          send([DELETED, data[1], data[2], data[3]]);
        }
        break;
      case PUTNUMS:
        if (hasRecordArgs(data, 3) && hasArray(data, 4)) {
          var base = data[1] as Number;
          var begin = data[2] as Number;
          var end = data[3] as Number;
          if (Records.storeBatch(base, begin, end, data[4] as Array<Object?>)) {
            send([GOTNUMS, base, begin, end]);
          } else {
            send([SENDERROR, PUTNUMS]);
          }
        }
        break;
      default:
        break;
    }
  }

  // Sends the heart rate history since `start`, one sample per minute.
  function sendHeartRate(start as Number) as Void {
    if (!(Toybox has :SensorHistory && SensorHistory has :getHeartRateHistory)) {
      return;
    }
    var count = (Time.now().value() - start + 59) / 60;
    if (count > 360 || count < 1) {
      count = 360;
    }
    var history = SensorHistory.getHeartRateHistory({ :period => count });
    // Oldest sample first.
    var samples = new [count];
    for (var i = count - 1; i >= 0; i--) {
      var sample = history.next();
      if (sample == null) {
        samples = samples.slice(i + 1, null);
        break;
      }
      samples[i] = [sample.when.value(), sample.data];
    }
    var newest = history.getNewestSampleTime();
    var newestTime = newest != null ? newest.value() : Time.now().value();
    send([HEART, samples.size(), newestTime, samples]);
  }

  // [type, n1, ..., nCount] with integer arguments.
  function hasNumbers(data as Array<Object?>, count as Number) as Boolean {
    if (data.size() <= count) {
      return false;
    }
    for (var i = 1; i <= count; i++) {
      if (!(data[i] instanceof Number)) {
        return false;
      }
    }
    return true;
  }

  // Like hasNumbers(), with a valid base as the first argument.
  function hasRecordArgs(data as Array<Object?>, count as Number) as Boolean {
    return hasNumbers(data, count) && Records.isBase(data[1]);
  }

  function hasArray(data as Array<Object?>, index as Number) as Boolean {
    return data.size() > index && data[index] instanceof Array;
  }
}
