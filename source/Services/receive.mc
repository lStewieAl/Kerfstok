using Toybox.Communications;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application.Properties as Prop;
using Toybox.WatchUi;
using Toybox.Time;
using Toybox.FitContributor as Fit;
var formattedGlucoseString = " ";

/**
 * Processes a new glucose reading received from the phone.
 * It updates the global glucose string, handles alarms, and submits
 * the value to the FIT contributor data field if available.
 *
 * @param glucoseDataArray An array containing glucose information:
 * [0] sensorIdentifier (String)
 * [1] timestamp (Number) - Unix timestamp of the reading
 * [2] glucoseValue (Float)
 * [3] rateOfChange (Float)
 * [4] alarmState (Number) - Bitfield for alarm status
 * [5] glucoseUnit (Number, optional) - 0 for mg/dL, 1 for mmol/L
 */
function updateGlucoseData(glucoseDataArray) {
  if (!(glucoseDataArray has :size) || glucoseDataArray.size() < 5) {
    return;
  }
  sensorIdentifier = glucoseDataArray[0];
  glucoseTimestamp = glucoseDataArray[1];
  var glucoseValue = glucoseDataArray[2];
  rateOfChange = glucoseDataArray[3];
  var alarmState = glucoseDataArray[4];
  if (glucoseDataArray.size() == 6) {
    // Unit is optionally sent with the glucose value
    glucoseUnit = glucoseDataArray[5] == 1 ? 1 : 0;
  }
  
  // Format the glucose string based on the current unit
  if (glucoseUnit == 1) { // mmol/L
    formattedGlucoseString = glucoseValue.format("%.1f");
  } else { // mg/dL
    formattedGlucoseString = glucoseValue.format("%.0f");
  }

  if (alarmState == 0) {
    AppSettings.isAlarmActive = false;
  } else {
    var alarmType = alarmState & 0x07;
    if ((alarmState & 0x08) != 0x0) {
      if ((alarmState & 0x10) != 0x0) {
        startGeneratedAlarm();
      } else {
        clearBeepPattern();
        clearBeepPattern();
        clearBeepPattern();
        clearBeepPattern();
      }
    }

    // Override rate of change for specific alarm types
    switch (alarmType) {
      case 4: // High glucose alarm
        rateOfChange = 20.0;
        break;
      case 5: // Low glucose alarm
        rateOfChange = -20.0;
        break;
      default:
        break;
    }
  }

  // TODO: don't add when too old
  if (glucoseDataField != null) {
    var currentTime = Time.now().value();
    if (currentTime - glucoseTimestamp < 30) {
      glucoseDataField.setData(glucoseValue);
    }
  }
  WatchUi.requestUpdate();
  return;
}

/**
 * Sets the glucose unit for formatting values.
 * @param unitValue 0 for mg/dL, 1 for mmol/L.
 */
function setGlucoseUnit(unitValue) {
  glucoseUnit = (unitValue == 1) ? 1 : 0;
}


/**
 * Sends the last known data index for a specific data source to the phone.
 * This is used during data synchronization.
 * @param dataSourceIndex The index of the data source (0 or 1).
 */
function sendLastKnownIndexToPhone(dataSourceIndex) {
  if (dataSourceIndex >= 0 && dataSourceIndex < 2) {
    Communications.transmit(
      [SETENDNUM, dataSourceIndex, storageid[dataSourceIndex]],
      null,
      new CommListener()
    );
  }
}

/**
 * Updates the watch's record of the last data index after being informed by the phone.
 * This happens when the phone has more recent data than the watch.
 * @param dataSourceIndex The index of the data source (0 or 1).
 * @param serverLastIndex The last index as reported by the phone.
 */
function updateLastKnownIndexFromServer(dataSourceIndex, serverLastIndex) {
  if (dataSourceIndex >= 0 && dataSourceIndex < 2) {
    if (serverLastIndex < storageid[dataSourceIndex]) {
      setstorageid(dataSourceIndex, serverLastIndex);
    }
  }

  // Acknowledge that the index was set.
  Communications.transmit([DIDSETENDNUM], null, new CommListener());
}

/**
 * The main router for all incoming messages from the phone.
 * It parses the message and dispatches it to the appropriate handler function.
 *
 * The protocol uses a numeric 'messageType' as the first element of the array.
 * The size of the array determines the message format.
 *
 * @param data The message received from the phone, typically an Array.
 */
function processIncomingMessage(data) {
  // First, handle non-array data which represents simple, one-word commands.
  if (!(data instanceof Toybox.Lang.Array)) {
    switch (data) {
      case LABELS:
        trans(LABELS, Time.now().value(), vars.slice(0, varnr));
        break;
      case CLEAR:
        clearnums();
        break;
      default:
        System.println("Received unexpected non-array data: " + data);
        break;
    }
    return; // Processing is complete for non-array data
  }

  // If data is an array but is empty, we cannot process it.
  if (data.size() <= 0) {
    System.println("Received an empty array message. Ignoring.");
    return;
  }

  // The first element of the array is always the message type.
  var messageType = data[0] as Lang.Number;

  // Switch on the message type. This approach assumes the sending client
  // provides the correct number of elements for each message type.
  switch (messageType) {
    // --- Messages with one element (command only) ---
    case START:
      startGlucoseStreaming();
      break;
    case STOPALARM:
      AppSettings.isAlarmActive = false;
      Communications.transmit([GOTSTOPALARM], null, new CommListener());
      break;

    // --- Messages with two elements (command + payload) ---
    case COLORBLACK:
      updateBackgroundColor(data[1]);
      break;
    case GLUCOSE:
      updateGlucoseData(data[1]);
      ackGlucose();
      break;
    case HEART:
      heartrate(data[1]);
      break;
    case PUTLABELS:
      storeLabels(data[1]);
      break;
    case PUTPRECISION:
      storePrecisionValues(data[1]);
      break;
    case SHORTCUTS:
      storeShortcuts(data[1]);
      break;
    case GETENDNUM:
      var payload = data[1];
      // The phone is asking for our last known index.
      if (payload == 0 && lowestchange[0] == null) {
        // If we have no data for source 0, just acknowledge.
        ackReceived();
      } else {
        sendLastKnownIndexToPhone(payload);
      }
      break;

    // --- Messages with three elements ---
    case NUMS:
      requestDataFromIndex(data[1], data[2]);
      break;
    case SETENDNUM:
      updateLastKnownIndexFromServer(data[1], data[2]);
      break;
    case MORENUMS:
      handleMoreDataNotification(data[1], data[2]);
      requestNextDataChunk(data[1], data[2]);
      break;
    case DELETED:
      onDataRecordsDeleted(data[1], data[2]);
      break;

    // --- Messages with four elements ---
    case DELETE:
      performDeletion(data[1], data[2], data[3]);
      break;

    // --- Messages with five elements ---
    case PUTNUMS:
      storeReceivedDataChunk(data[1], data[2], data[3], data[4]);
      break;

    default:
      System.println("Unknown message type received: " + messageType);
      break;
  }
}