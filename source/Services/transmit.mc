using Toybox.WatchUi;
using Toybox.Communications;
using Toybox.System;
using Toybox.Application.Storage;
const maxtransmit = 50; //100 gives Error: Out Of Memory Error
function sendnums(type, base, num) {
  if (lowestchange[base] == null) {
    asklowest();
    return;
  }
  if (num > lowestchange[base]) {
    num = lowestchange[base];
  }
  var iter = storageid[base];
  if (num >= iter) {
    Communications.transmit([NOMORENUMS, base, iter], null, new CommListener());
    return;
  }
  var len = iter - num;
  if (len > maxstorage) {
    len = maxstorage;
    num = iter - len;
  }
  if (len > maxtransmit) {
    len = maxtransmit;
  }
  var data = new [len];
  var it = num;
  for (var i = 0; i < len; it++, i++) {
    data[i] = getval(base, it);
  }
  transbase(type, base, it, data);
}

function requestNextDataChunk(base, num) {
  sendnums(NUMS, base, num);
}

function requestDataFromIndex(base, num) {
  if (base == 0 && lowestchange[0] == null) {
    lowestchange[0] = num;
  }
  sendnums(NUMS, base, num);
}

function havenums(base) {
  sendnums(HAVENUMS, base, lowestchange[base]);
}

function asklowest() {
  if (!AppSettings.isGlucoCommsActive) {
    startGlucoseStreaming();
  }
}

function startGlucoseStreaming() {
  Communications.transmit(
    [START, lowestchange[0] == null],
    null,
    new CommListener()
  );
  AppSettings.isGlucoCommsActive = true;
}

function ackGlucose() {
  if (!AppSettings.isGlucoCommsActive) {
    startGlucoseStreaming();
  } else {
    Communications.transmit([GOTGLUCOSE], null, new CommListener());
  }
}

function stopglucose() {
  if (AppSettings.isGlucoCommsActive) {
    Communications.transmit([STOP], null, new CommListener());
    AppSettings.isGlucoCommsActive = false;
  }
}

function senddelete(base, pos) {
  Communications.transmit([DELETE, base, pos], null, new CommListener());
}

function performDeletion(base, num, end) {
  var last = end - 1;
  for (var it = num; it < last; it++) {
    delval(base, it);
  }
  deletethrough(base, last);
  Communications.transmit([DELETED, base, num, end], null, new CommListener());
  WatchUi.requestUpdate();
}

function stopalarm() {
  stopGeneratedAlarm();
  Communications.transmit([STOPALARM], null, new CommListener());
}
