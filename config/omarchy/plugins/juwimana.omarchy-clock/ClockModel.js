.pragma library
.import "CityDatabase.js" as CityDatabase

function pad2(num) {
  var s = String(Math.floor(num || 0));
  return s.length < 2 ? "0" + s : s;
}

function getCityTimeInfo(cityObj, timeTravelOffsetHours, timestamp) {
  var now = timestamp ? new Date(timestamp) : new Date();
  var offsetHours = 0;

  if (typeof cityObj === "object" && cityObj !== null) {
    if (cityObj.baseOffset !== undefined) {
      offsetHours = CityDatabase.getCityOffsetHours(cityObj, now);
    } else if (cityObj.utcOffset !== undefined) {
      offsetHours = Number(cityObj.utcOffset);
    } else {
      var found = CityDatabase.getByTimezone(cityObj.timezone) || CityDatabase.getById(cityObj.id);
      if (found) offsetHours = CityDatabase.getCityOffsetHours(found, now);
      else offsetHours = 0;
    }
  } else if (typeof cityObj === "string") {
    var foundStr = CityDatabase.getByTimezone(cityObj) || CityDatabase.getById(cityObj);
    if (foundStr) offsetHours = CityDatabase.getCityOffsetHours(foundStr, now);
    else offsetHours = 0;
  }

  var travelHours = Number(timeTravelOffsetHours || 0);
  var totalOffsetMinutes = (offsetHours + travelHours) * 60;

  var cityEpochMs = now.getTime() + (totalOffsetMinutes * 60 * 1000);
  var cityDate = new Date(cityEpochMs);

  var h24 = cityDate.getUTCHours();
  var m = cityDate.getUTCMinutes();
  var s = cityDate.getUTCSeconds();
  var ampm = h24 >= 12 ? "PM" : "AM";
  var h12 = h24 % 12 || 12;

  var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  var weekday = days[cityDate.getUTCDay()];

  // Local comparison
  var localOffsetMinutes = -now.getTimezoneOffset();
  var diffMinutes = Math.round(totalOffsetMinutes - localOffsetMinutes);
  var diffHours = Math.floor(Math.abs(diffMinutes) / 60);
  var diffMinsRem = Math.abs(diffMinutes) % 60;

  var localDay = now.getDate();
  var cityDay = cityDate.getUTCDate();
  var dayLabel = "Today";
  if (cityDay !== localDay) {
    if (cityDate.getTime() > now.getTime()) dayLabel = "Tomorrow";
    else dayLabel = "Yesterday";
  }

  var offsetShort = "";
  var offsetFull = "";

  if (diffMinutes === 0) {
    offsetShort = "Same time";
    offsetFull = dayLabel + " • Same time";
  } else if (diffMinutes > 0) {
    var aheadText = (diffMinsRem === 0 ? diffHours + "h ahead" : diffHours + "h " + diffMinsRem + "m ahead");
    offsetShort = "+" + diffHours + "h";
    offsetFull = dayLabel + " • " + aheadText;
  } else {
    var behindText = (diffMinsRem === 0 ? diffHours + "h behind" : diffHours + "h " + diffMinsRem + "m behind");
    offsetShort = "-" + diffHours + "h";
    offsetFull = dayLabel + " • " + behindText;
  }

  return {
    hour24: h24,
    hour12: h12,
    minute: m,
    second: s,
    ampm: ampm,
    weekday: weekday,
    digital12: pad2(h12) + ":" + pad2(m),
    digital24: pad2(h24) + ":" + pad2(m),
    secondsStr: pad2(s),
    dayLabel: dayLabel,
    offsetShort: offsetShort,
    offsetFull: offsetFull,
    diff: offsetFull
  };
}

function formatStopwatch(ms) {
  var totalHundredths = Math.floor(ms / 10);
  var hundredths = totalHundredths % 100;
  var totalSecs = Math.floor(ms / 1000);
  var secs = totalSecs % 60;
  var totalMins = Math.floor(totalSecs / 60);
  var mins = totalMins % 60;
  var hours = Math.floor(totalMins / 60);

  if (hours > 0) {
    return {
      hours: pad2(hours),
      mins: pad2(mins),
      secs: pad2(secs),
      hundredths: pad2(hundredths),
      formatted: pad2(hours) + ":" + pad2(mins) + ":" + pad2(secs) + "." + pad2(hundredths)
    };
  }

  return {
    hours: "00",
    mins: pad2(mins),
    secs: pad2(secs),
    hundredths: pad2(hundredths),
    formatted: pad2(mins) + ":" + pad2(secs) + "." + pad2(hundredths)
  };
}

function formatTimer(totalSecs) {
  var s = Math.max(0, Math.floor(totalSecs));
  var hours = Math.floor(s / 3600);
  var remainder = s % 3600;
  var mins = Math.floor(remainder / 60);
  var secs = remainder % 60;

  return {
    hours: pad2(hours),
    mins: pad2(mins),
    secs: pad2(secs),
    formatted: (hours > 0 ? pad2(hours) + ":" : "") + pad2(mins) + ":" + pad2(secs)
  };
}

function getNextAlarmSummary(alarms) {
  if (!alarms || alarms.length === 0) return "No active alarms";

  var now = new Date();
  var currentDay = now.getDay();
  var currentH = now.getHours();
  var currentM = now.getMinutes();
  var currentTotalMin = currentH * 60 + currentM;

  var minWaitMinutes = 999999;
  var nextAlarm = null;

  for (var i = 0; i < alarms.length; i++) {
    var a = alarms[i];
    if (!a.enabled) continue;

    var alarmTotalMin = a.hour * 60 + a.minute;
    var days = (a.days && a.days.length > 0) ? a.days : [0, 1, 2, 3, 4, 5, 6];

    for (var d = 0; d < 7; d++) {
      var targetDay = (currentDay + d) % 7;
      if (days.indexOf(targetDay) !== -1) {
        var diff = (d * 24 * 60) + (alarmTotalMin - currentTotalMin);
        if (diff > 0 && diff < minWaitMinutes) {
          minWaitMinutes = diff;
          nextAlarm = a;
          break;
        }
      }
    }
  }

  if (!nextAlarm) return "No upcoming alarms";

  var waitHours = Math.floor(minWaitMinutes / 60);
  var waitMins = minWaitMinutes % 60;

  if (waitHours === 0 && waitMins <= 1) return "Next in less than a minute";
  if (waitHours === 0) return "Next in " + waitMins + "m";
  if (waitMins === 0) return "Next in " + waitHours + "h";
  return "Next in " + waitHours + "h " + waitMins + "m";
}
