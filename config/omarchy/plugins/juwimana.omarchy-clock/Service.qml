import QtQuick
import Quickshell
import Quickshell.Io
import "ClockModel.js" as ClockModel
import "CityDatabase.js" as CityDatabase

Item {
  id: root

  property var shell: null
  property var manifest: null
  readonly property bool initialized: true

  readonly property string stateDir: (Quickshell.env("XDG_CONFIG_HOME") || ((Quickshell.env("HOME") || "") + "/.config")) + "/omarchy/plugins/juwimana.omarchy-clock"
  readonly property string statePath: stateDir + "/state.json"

  // ----------------------------------------------------
  // Alarms State
  // ----------------------------------------------------
  property var alarms: [
    {
      id: "alarm_harare",
      label: "Harare Standup",
      hour: 6,
      minute: 0,
      enabled: false,
      days: [1, 2, 3, 4, 5],
      sound: "default",
      snoozeMins: 5
    },
    {
      id: "alarm_morning",
      label: "Morning Alarm",
      hour: 7,
      minute: 30,
      enabled: false,
      days: [1, 2, 3, 4, 5],
      sound: "default",
      snoozeMins: 5
    }
  ]

  property var activeAlarmFired: null
  property int lastCheckedMinute: -1

  // ----------------------------------------------------
  // World Clock State (Clean Minimalist Defaults)
  // ----------------------------------------------------
  property var worldCities: [
    { id: "harare", city: "Harare", country: "Zimbabwe", timezone: "Africa/Harare", baseOffset: 2, dst: "none" },
    { id: "london", city: "London", country: "United Kingdom", timezone: "Europe/London", baseOffset: 0, dst: "eu" },
    { id: "tokyo", city: "Tokyo", country: "Japan", timezone: "Asia/Tokyo", baseOffset: 9, dst: "none" },
    { id: "new_york", city: "New York", country: "United States", timezone: "America/New_York", baseOffset: -5, dst: "us" }
  ]

  // ----------------------------------------------------
  // Stopwatch State
  // ----------------------------------------------------
  property bool stopwatchRunning: false
  property double stopwatchStartTime: 0
  property double stopwatchAccumulatedMs: 0
  property double stopwatchElapsedMs: 0
  property var stopwatchLaps: []

  // ----------------------------------------------------
  // Timer State
  // ----------------------------------------------------
  property bool timerRunning: false
  property bool timerPaused: false
  property int timerTotalSeconds: 300 // default 5m
  property int timerRemainingSeconds: 300
  property double timerEndTime: 0
  property double timerPausedRemaining: 0
  property bool timerFired: false

  // ----------------------------------------------------
  // Navigation State
  // ----------------------------------------------------
  property int activeTab: 1 // default to World clock

  // ----------------------------------------------------
  // Methods: Alarms
  // ----------------------------------------------------
  function toggleAlarm(id) {
    var updated = []
    for (var i = 0; i < root.alarms.length; i++) {
      var a = Object.assign({}, root.alarms[i])
      if (a.id === id) a.enabled = !a.enabled
      updated.push(a)
    }
    root.alarms = updated
    root.saveState()
  }

  function saveAlarm(alarmObj) {
    var updated = []
    var found = false
    for (var i = 0; i < root.alarms.length; i++) {
      if (root.alarms[i].id === alarmObj.id) {
        updated.push(alarmObj)
        found = true
      } else {
        updated.push(root.alarms[i])
      }
    }
    if (!found) updated.push(alarmObj)
    root.alarms = updated
    root.saveState()
  }

  function deleteAlarm(id) {
    var updated = []
    for (var i = 0; i < root.alarms.length; i++) {
      if (root.alarms[i].id !== id) updated.push(root.alarms[i])
    }
    root.alarms = updated
    root.saveState()
  }

  function snoozeActiveAlarm() {
    root.activeAlarmFired = null
  }

  function dismissActiveAlarm() {
    root.activeAlarmFired = null
  }

  // ----------------------------------------------------
  // Methods: World Cities & Drag Reordering
  // ----------------------------------------------------
  function addCity(cityObj) {
    for (var i = 0; i < root.worldCities.length; i++) {
      if (root.worldCities[i].id === cityObj.id || (root.worldCities[i].city === cityObj.city && root.worldCities[i].timezone === cityObj.timezone)) {
        return // already added
      }
    }
    var updated = root.worldCities.slice(0)
    updated.push(cityObj)
    root.worldCities = updated
    root.saveState()
  }

  function removeCity(id) {
    var updated = []
    for (var i = 0; i < root.worldCities.length; i++) {
      if (root.worldCities[i].id !== id) updated.push(root.worldCities[i])
    }
    root.worldCities = updated
    root.saveState()
  }

  function moveCity(fromIndex, toIndex) {
    if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0 || fromIndex >= root.worldCities.length || toIndex >= root.worldCities.length) return
    var arr = root.worldCities.slice(0)
    var item = arr.splice(fromIndex, 1)[0]
    arr.splice(toIndex, 0, item)
    root.worldCities = arr
    root.saveState()
  }

  // ----------------------------------------------------
  // Methods: Stopwatch
  // ----------------------------------------------------
  function startStopwatch() {
    root.stopwatchStartTime = Date.now()
    root.stopwatchRunning = true
  }

  function pauseStopwatch() {
    if (!root.stopwatchRunning) return
    root.stopwatchAccumulatedMs += (Date.now() - root.stopwatchStartTime)
    root.stopwatchElapsedMs = root.stopwatchAccumulatedMs
    root.stopwatchRunning = false
  }

  function resumeStopwatch() {
    root.stopwatchStartTime = Date.now()
    root.stopwatchRunning = true
  }

  function resetStopwatch() {
    root.stopwatchRunning = false
    root.stopwatchStartTime = 0
    root.stopwatchAccumulatedMs = 0
    root.stopwatchElapsedMs = 0
    root.stopwatchLaps = []
  }

  function lapStopwatch() {
    var currentMs = root.stopwatchElapsedMs
    var prevLapTotal = 0
    if (root.stopwatchLaps.length > 0) {
      prevLapTotal = root.stopwatchLaps[root.stopwatchLaps.length - 1].totalMs
    }
    var lapDuration = currentMs - prevLapTotal
    var lapNumber = root.stopwatchLaps.length + 1

    var laps = root.stopwatchLaps.slice(0)
    laps.push({
      lapNumber: lapNumber,
      durationMs: lapDuration,
      totalMs: currentMs
    })
    root.stopwatchLaps = laps
  }

  // ----------------------------------------------------
  // Methods: Timer
  // ----------------------------------------------------
  function startTimer(seconds) {
    if (seconds <= 0) return
    root.timerTotalSeconds = seconds
    root.timerRemainingSeconds = seconds
    root.timerEndTime = Date.now() + (seconds * 1000)
    root.timerRunning = true
    root.timerPaused = false
    root.timerFired = false
  }

  function pauseTimer() {
    if (!root.timerRunning || root.timerPaused) return
    root.timerPausedRemaining = Math.max(0, (root.timerEndTime - Date.now()) / 1000)
    root.timerPaused = true
  }

  function resumeTimer() {
    if (!root.timerRunning || !root.timerPaused) return
    root.timerEndTime = Date.now() + (root.timerPausedRemaining * 1000)
    root.timerPaused = false
  }

  function cancelTimer() {
    root.timerRunning = false
    root.timerPaused = false
    root.timerFired = false
    root.timerRemainingSeconds = root.timerTotalSeconds
  }

  function addTimerSeconds(secs) {
    if (root.timerRunning) {
      root.timerEndTime += (secs * 1000)
      root.timerTotalSeconds += secs
      root.timerRemainingSeconds += secs
    } else {
      root.timerTotalSeconds = Math.max(10, root.timerTotalSeconds + secs)
      root.timerRemainingSeconds = root.timerTotalSeconds
    }
  }

  function dismissTimer() {
    root.timerFired = false
    root.timerRunning = false
  }

  // ----------------------------------------------------
  // Audio & Notification Alerts
  // ----------------------------------------------------
  function triggerAlarmAlert(alarm) {
    root.activeAlarmFired = alarm
    soundProcess.command = ["pw-play", "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"]
    soundProcess.running = true

    notifyProcess.command = ["notify-send", "Alarm: " + (alarm.label || "Alarm ringing"), "Omarchy Clock", "-u", "critical", "-a", "Omarchy Clock"]
    notifyProcess.running = true
  }

  function triggerTimerAlert() {
    root.timerFired = true
    soundProcess.command = ["pw-play", "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"]
    soundProcess.running = true

    notifyProcess.command = ["notify-send", "Timer Complete", "Your countdown timer is done!", "-u", "critical", "-a", "Omarchy Clock"]
    notifyProcess.running = true
  }

  // ----------------------------------------------------
  // Background Loops
  // ----------------------------------------------------
  Timer {
    id: secondTickTimer
    interval: 1000
    repeat: true
    running: true
    onTriggered: {
      var now = new Date()
      var curMin = now.getMinutes()
      var curHour = now.getHours()
      var curDay = now.getDay()
      var curSec = now.getSeconds()

      // Check alarms once per minute on second 0-2
      if (curMin !== root.lastCheckedMinute && curSec <= 2) {
        root.lastCheckedMinute = curMin
        for (var i = 0; i < root.alarms.length; i++) {
          var a = root.alarms[i]
          if (a.enabled && a.hour === curHour && a.minute === curMin) {
            var days = (a.days && a.days.length > 0) ? a.days : [0, 1, 2, 3, 4, 5, 6]
            if (days.indexOf(curDay) !== -1) {
              root.triggerAlarmAlert(a)
              break
            }
          }
        }
      }
    }
  }

  Timer {
    id: fastLoopTimer
    interval: 50
    repeat: true
    running: root.stopwatchRunning || (root.timerRunning && !root.timerPaused)
    onTriggered: {
      if (root.stopwatchRunning) {
        root.stopwatchElapsedMs = root.stopwatchAccumulatedMs + (Date.now() - root.stopwatchStartTime)
      }

      if (root.timerRunning && !root.timerPaused) {
        var remain = Math.max(0, Math.ceil((root.timerEndTime - Date.now()) / 1000))
        root.timerRemainingSeconds = remain
        if (remain <= 0) {
          root.timerRunning = false
          root.triggerTimerAlert()
        }
      }
    }
  }

  // ----------------------------------------------------
  // Processes for Audio & Notifications
  // ----------------------------------------------------
  Process {
    id: soundProcess
    command: []
  }

  Process {
    id: notifyProcess
    command: []
  }

  // ----------------------------------------------------
  // Persistence Handling
  // ----------------------------------------------------
  Process {
    id: stateReader
    command: ["cat", root.statePath]
    running: true
    stdout: StdioCollector {
      id: stateOut
      waitForEnd: true
      onStreamFinished: {
        try {
          if (text && text.trim().length > 0) {
            var data = JSON.parse(text)
            if (data.alarms && Array.isArray(data.alarms)) root.alarms = data.alarms
            if (data.worldCities && Array.isArray(data.worldCities)) root.worldCities = data.worldCities
            if (data.timerTotalSeconds) root.timerTotalSeconds = data.timerTotalSeconds
          }
        } catch (e) {
          // ignore corrupted format
        }
      }
    }
  }

  FileView {
    id: stateFileWriter
    path: root.statePath
    preload: false
    watchChanges: false
    atomicWrites: true
    printErrors: false
  }

  function saveState() {
    var data = {
      alarms: root.alarms,
      worldCities: root.worldCities,
      timerTotalSeconds: root.timerTotalSeconds
    }
    stateFileWriter.setText(JSON.stringify(data, null, 2) + "\n")
  }
}
