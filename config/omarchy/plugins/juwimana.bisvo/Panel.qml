import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "juwimana.bisvo"
  ipcTarget: "juwimana.bisvo"

  Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  // Data state
  property var matches: []
  property var sourceStatus: []
  property var stats: ({
    total_scanned: 0,
    residential_stands: 0,
    full_matches: 0,
    by_suburb: ({
      "mainway-meadows": 0,
      "msasa-park": 0,
      "southerton": 0,
      "braeside": 0
    })
  })
  property var configData: ({
    max_sqm: 500,
    min_sqm: 100,
    max_price_usd: 0,
    residential_only: true,
    auto_scan_enabled: true,
    scrape_interval_minutes: 60
  })

  property bool isScanning: false
  property bool showSettings: false
  property string lastError: ""
  property string lastUpdated: "Just now"

  // Filtering, sorting & navigation
  property string selectedSuburb: "all" // "all", "mainway-meadows", "msasa-park", "southerton", "braeside"
  property string sortBy: "newest"      // "newest", "price", "size", "suburb"
  property int selectedIndex: 0
  property string searchQuery: ""
  property bool searching: false

  readonly property int matchCount: matches ? matches.length : 0
  readonly property string runnerPath: "/home/juwimana/bisvo/run.sh"

  readonly property var suburbTabs: [
    { slug: "all", label: strings.t("filter.all") },
    { slug: "mainway-meadows", label: "Mainway Meadows" },
    { slug: "msasa-park", label: "Msasa Park" },
    { slug: "southerton", label: "Southerton" },
    { slug: "braeside", label: "Braeside" }
  ]

  // Neutralize markup-shaped text before passing dynamic strings into shared Omarchy components
  function sanitizePlainText(val) {
    if (val === undefined || val === null) return ""
    return String(val)
      .replace(/<[^>]*>/g, " ")
      .replace(/[<>]/g, "")
      .replace(/[\x00-\x1f\x7f]+/g, " ")
      .replace(/\s+/g, " ")
      .trim()
  }

  function formatUsd(val) {
    var num = Number(val || 0)
    if (!isFinite(num) || num <= 0) return strings.t("card.poa")
    return "$" + I18n.formatNumber(Math.round(num), 0)
  }

  function formatSize(val) {
    if (val === undefined || val === null || isNaN(Number(val))) return "?"
    var num = Number(val)
    var dec = (Math.abs(num - Math.round(num)) > 0.05) ? 1 : 0
    return I18n.formatNumber(num, dec) + " m²"
  }

  function formatRelativeTime(dateStr) {
    if (!dateStr || dateStr === "") return ""
    try {
      var d = new Date(dateStr)
      if (isNaN(d.getTime())) return ""
      var now = new Date()
      var diffMs = now.getTime() - d.getTime()
      if (diffMs < 0) diffMs = 0
      var diffSec = Math.floor(diffMs / 1000)
      if (diffSec < 60) return "Just now"
      var diffMin = Math.floor(diffSec / 60)
      if (diffMin < 60) return diffMin + "m ago"
      var diffHr = Math.floor(diffMin / 60)
      if (diffHr < 24) return diffHr + "h ago"
      var diffDays = Math.floor(diffHr / 24)
      if (diffDays === 1) return "Yesterday"
      if (diffDays < 7) return diffDays + "d ago"
      var loc = Qt.locale(I18n.formatLocale)
      return d.toLocaleDateString(loc, "MMM d")
    } catch (e) {
      return ""
    }
  }

  function suburbCount(slug) {
    if (slug === "all") return root.matchCount
    if (root.stats && root.stats.by_suburb && root.stats.by_suburb[slug] !== undefined) {
      return root.stats.by_suburb[slug]
    }
    return 0
  }

  readonly property var sortedMatches: {
    if (!root.matches || root.matches.length === 0) return []
    var list = root.matches.slice(0)

    // Suburb filter
    if (root.selectedSuburb && root.selectedSuburb !== "all") {
      list = list.filter(function(item) {
        return (item.suburb_slug || "") === root.selectedSuburb
      })
    }

    // Free-text filter
    if (root.searchQuery && root.searchQuery.trim() !== "") {
      var q = root.searchQuery.trim().toLowerCase()
      list = list.filter(function(item) {
        var t = (item.title || "").toLowerCase()
        var sub = (item.suburb || "").toLowerCase()
        var src = (item.source_name || "").toLowerCase()
        var seller = (item.seller_name || "").toLowerCase()
        var ten = (item.tenure || "").toLowerCase()
        var srv = (item.servicing || "").toLowerCase()
        return t.indexOf(q) !== -1 || sub.indexOf(q) !== -1 || src.indexOf(q) !== -1 ||
               seller.indexOf(q) !== -1 || ten.indexOf(q) !== -1 || srv.indexOf(q) !== -1
      })
    }

    // Sort
    if (root.sortBy === "newest") {
      list.sort(function(a, b) {
        var da = a.posted_at || a.first_seen_at || ""
        var db = b.posted_at || b.first_seen_at || ""
        var ta = da ? (new Date(da).getTime() || 0) : 0
        var tb = db ? (new Date(db).getTime() || 0) : 0
        if (ta !== tb) return tb - ta
        return String(db).localeCompare(String(da))
      })
    } else if (root.sortBy === "price") {
      list.sort(function(a, b) {
        var pa = (a.price_usd && a.price_usd > 0) ? a.price_usd : 999999999
        var pb = (b.price_usd && b.price_usd > 0) ? b.price_usd : 999999999
        if (pa !== pb) return pa - pb
        return (a.size_sqm || 999999) - (b.size_sqm || 999999)
      })
    } else if (root.sortBy === "size") {
      list.sort(function(a, b) {
        var sa = (a.size_sqm !== undefined && a.size_sqm !== null) ? a.size_sqm : 999999
        var sb = (b.size_sqm !== undefined && b.size_sqm !== null) ? b.size_sqm : 999999
        if (sa !== sb) return sa - sb
        return (a.price_usd || 999999999) - (b.price_usd || 999999999)
      })
    } else if (root.sortBy === "suburb") {
      list.sort(function(a, b) {
        var cmp = String(a.suburb || "").localeCompare(String(b.suburb || ""))
        if (cmp !== 0) return cmp
        return (a.size_sqm || 999999) - (b.size_sqm || 999999)
      })
    }
    return list
  }

  // Theme colors
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color accentColor: Color.accent
  readonly property color mutedColor: Color.muted
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property int panelWidth: Style.space(480)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function fetchMatches() {
    if (matchesProcess.running) return
    matchesProcess.running = true
  }

  function triggerScan() {
    if (scanProcess.running || root.isScanning) return
    root.isScanning = true
    root.lastError = ""
    scanProcess.running = true
  }

  function setConfigValue(key, val) {
    configSetProcess.command = [root.runnerPath, "config", "set", String(key), String(val)]
    configSetProcess.running = true
  }

  function adjustMaxSqm(delta) {
    var cur = Number(root.configData.max_sqm || 500)
    var nextVal = Math.max(150, Math.min(2000, Math.round(cur + delta)))
    root.configData.max_sqm = nextVal
    setConfigValue("max_sqm", String(nextVal))
  }

  function adjustMaxPrice(delta) {
    var cur = Number(root.configData.max_price_usd || 0)
    var nextVal = Math.max(0, Math.min(500000, Math.round(cur + delta)))
    root.configData.max_price_usd = nextVal
    setConfigValue("max_price_usd", String(nextVal))
  }

  function toggleAutoScan() {
    var nextVal = !Boolean(root.configData.auto_scan_enabled)
    root.configData.auto_scan_enabled = nextVal
    setConfigValue("auto_scan_enabled", nextVal ? "true" : "false")
  }

  function openUrl(url) {
    if (!url || typeof url !== "string") return
    var trimmed = url.trim()
    if (trimmed.indexOf("https://") !== 0) return
    var opened = false
    try {
      opened = Qt.openUrlExternally(trimmed)
    } catch (e) {
      opened = false
    }
    if (!opened) {
      Quickshell.execDetached(["xdg-open", trimmed])
    }
  }

  function openTerminal() {
    Quickshell.execDetached(["omarchy-launch-tui", "--app-id=org.omarchy.bisvo", root.runnerPath, "scan", "--show-all"])
  }

  function parseMatches(raw) {
    try {
      var data = JSON.parse((raw || "").trim())
      if (data && data.matches !== undefined) {
        root.matches = data.matches || []
      }
      if (data && data.stats) {
        root.stats = data.stats
      }
      if (data && data.config) {
        root.configData = data.config
      }
      if (data && data.source_status) {
        root.sourceStatus = data.source_status
      }
      var now = new Date()
      var loc = Qt.locale(I18n.formatLocale)
      root.lastUpdated = now.toLocaleTimeString(loc, "HH:mm")
      root.lastError = ""
    } catch (e) {
      root.lastError = "Failed to parse Bisvo response"
    }
  }

  onSortedMatchesChanged: {
    if (root.selectedIndex >= root.sortedMatches.length) {
      root.selectedIndex = Math.max(0, root.sortedMatches.length - 1)
    }
  }

  onOpenedChanged: {
    if (root.opened) {
      root.selectedIndex = 0
      root.fetchMatches()
    }
  }

  Component.onCompleted: {
    root.fetchMatches()
  }

  // Refresh local SQLite snapshot in UI (actual web scrapes run hourly via bisvo.service)
  Timer {
    interval: root.opened ? 15000 : 60000
    running: true
    repeat: true
    onTriggered: root.fetchMatches()
  }

  Process {
    id: matchesProcess
    command: [root.runnerPath, "json-matches"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parseMatches(text)
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (text && text.trim() !== "") {
          console.warn("[bisvo] matchesProcess stderr:", text.trim())
          root.lastError = root.sanitizePlainText(text.trim())
        }
      }
    }
  }

  Process {
    id: scanProcess
    command: [root.runnerPath, "json-scan"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.isScanning = false
        root.parseMatches(text)
      }
    }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (text && text.trim() !== "") {
          root.lastError = root.sanitizePlainText(text.trim())
        }
      }
    }
    onExited: {
      root.isScanning = false
      root.fetchMatches()
    }
  }

  Process {
    id: configSetProcess
    onExited: {
      root.fetchMatches()
    }
  }

  // -------------------------------------------------------------
  // BAR WIDGET BUTTON
  // -------------------------------------------------------------
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: {
      if (root.matchCount > 0) {
        return "\uf279 " + strings.tn("bar.standCount", root.matchCount).arg(I18n.formatNumber(root.matchCount, 0))
      }
      return "\uf279 " + strings.t("bar.empty")
    }
    fontSize: Style.bar.iconFont
    foreground: root.matchCount > 0 ? Color.accent : (bar ? bar.barForeground : Color.foreground)
    tooltipText: root.sanitizePlainText(
      strings.t("bar.tooltip")
        .arg(strings.tn("bar.standCount", root.matchCount).arg(I18n.formatNumber(root.matchCount, 0)))
        .arg(I18n.formatNumber(root.stats.total_scanned || 0, 0))
    )
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) {
        root.toggle()
      } else if (buttonCode === Qt.MiddleButton) {
        root.triggerScan()
      }
    }
  }

  // -------------------------------------------------------------
  // POPUP KEYBOARD PANEL
  // -------------------------------------------------------------
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(root.panelWidth)
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight, Style.space(660))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.searching

      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) {
        if (!root.sortedMatches || root.sortedMatches.length === 0) return
        if (dy > 0) {
          root.selectedIndex = Math.min(root.sortedMatches.length - 1, Math.max(0, root.selectedIndex + 1))
          listingsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        } else if (dy < 0) {
          root.selectedIndex = Math.max(0, root.selectedIndex - 1)
          listingsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        }
      }
      onTextKey: function(t) {
        var k = t.toLowerCase()
        if (k === "s") root.triggerScan()
        else if (k === "r") root.fetchMatches()
        else if (k === "t") root.openTerminal()
        else if (k === "/") {
          root.searching = true
          Qt.callLater(function() { if (root.searching) searchField.forceActiveFocus() })
        }
        else if (k === "j") {
          if (root.sortedMatches && root.sortedMatches.length > 0) {
            root.selectedIndex = Math.min(root.sortedMatches.length - 1, Math.max(0, root.selectedIndex + 1))
            listingsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
          }
        }
        else if (k === "k") {
          if (root.sortedMatches && root.sortedMatches.length > 0) {
            root.selectedIndex = Math.max(0, root.selectedIndex - 1)
            listingsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
          }
        }
        else if (k === "o" || k === "\r" || k === "\n") {
          if (root.selectedIndex >= 0 && root.selectedIndex < root.sortedMatches.length) {
            root.openUrl(root.sortedMatches[root.selectedIndex].url)
          }
        }
        else if (k === "1" || k === "l") root.sortBy = "newest"
        else if (k === "2" || k === "p") root.sortBy = "price"
        else if (k === "3" || k === "m") root.sortBy = "size"
        else if (k === "4" || k === "a") root.sortBy = "suburb"
      }

      Column {
        id: mainColumn
        width: parent.width
        spacing: Style.space(10)

        // --------------------------------------------------------
        // HEADER HERO
        // --------------------------------------------------------
        PanelHero {
          width: parent.width
          title: strings.t("plugin.title")
          meta: root.sanitizePlainText(
            root.isScanning
              ? strings.t("hero.scanning")
              : strings.t("hero.meta")
                  .arg(I18n.formatNumber(Math.round(root.configData.max_sqm || 500), 0))
                  .arg("5 Agency Portals")
          )
          foreground: root.fg
          fontFamily: root.fontFamily

          iconComponent: Component {
            Text {
              textFormat: Text.PlainText
              text: "\uf279"
              color: root.matchCount > 0 ? Color.accent : root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }

          trailingControl: Component {
            Row {
              spacing: Style.space(6)

              // Settings Gear Button
              Rectangle {
                width: Style.space(28)
                height: Style.space(28)
                radius: Style.space(4)
                color: root.showSettings
                  ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.18)
                  : (gearMouse.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.05))

                Text {
                  textFormat: Text.PlainText
                  anchors.centerIn: parent
                  text: "\uf013"
                  color: root.showSettings ? Color.accent : root.fg
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                }

                MouseArea {
                  id: gearMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.showSettings = !root.showSettings
                }
              }

              // Scan Now Button
              Rectangle {
                width: Style.space(82)
                height: Style.space(28)
                radius: Style.space(4)
                color: Color.accent

                Text {
                  textFormat: Text.PlainText
                  anchors.centerIn: parent
                  text: root.isScanning ? strings.t("hero.scanningBtn") : strings.t("hero.scanNow")
                  color: Color.background
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.triggerScan()
                }
              }
            }
          }
        }

        // --------------------------------------------------------
        // SUBURB FILTER STRIP
        // --------------------------------------------------------
        Flow {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.suburbTabs

            Rectangle {
              id: subPill
              readonly property bool active: root.selectedSuburb === modelData.slug
              readonly property int cnt: root.suburbCount(modelData.slug)
              height: Style.space(24)
              width: pillText.implicitWidth + Style.space(14)
              radius: Style.space(4)
              color: active
                ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.18)
                : (pillMouse.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.09) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.04))
              border.color: active ? Color.accent : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.10)
              border.width: 1

              Text {
                id: pillText
                textFormat: Text.PlainText
                anchors.centerIn: parent
                text: modelData.label + (subPill.cnt > 0 ? (" (" + I18n.formatNumber(subPill.cnt, 0) + ")") : "")
                color: subPill.active ? Color.accent : (subPill.cnt > 0 ? root.fg : root.mutedColor)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: subPill.active
              }

              MouseArea {
                id: pillMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.selectedSuburb = modelData.slug
                  root.selectedIndex = 0
                }
              }
            }
          }
        }

        // --------------------------------------------------------
        // CRITERIA SUMMARY ROW
        // --------------------------------------------------------
        Row {
          width: parent.width
          spacing: Style.space(8)

          Text {
            textFormat: Text.PlainText
            text: strings.t("filter.residentialOnly")
            color: Color.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            textFormat: Text.PlainText
            text: "·"
            color: root.mutedColor
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            textFormat: Text.PlainText
            text: strings.t("filter.maxSize").arg(I18n.formatNumber(Math.round(root.configData.max_sqm || 500), 0))
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.showSettings = !root.showSettings
            }
          }

          Text {
            textFormat: Text.PlainText
            text: "·"
            color: root.mutedColor
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            textFormat: Text.PlainText
            text: (root.configData.max_price_usd && root.configData.max_price_usd > 0)
              ? strings.t("filter.priceMax").arg(I18n.formatNumber(Math.round(root.configData.max_price_usd), 0))
              : strings.t("filter.priceAny")
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.showSettings = !root.showSettings
            }
          }

          Text {
            textFormat: Text.PlainText
            text: "·"
            color: root.mutedColor
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Text {
            textFormat: Text.PlainText
            text: root.configData.auto_scan_enabled ? strings.t("filter.hourlyOn") : strings.t("filter.hourlyOff")
            color: root.configData.auto_scan_enabled ? Color.accent : root.mutedColor
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: Boolean(root.configData.auto_scan_enabled)

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleAutoScan()
            }
          }
        }

        // --------------------------------------------------------
        // EXPANDABLE SETTINGS DRAWER
        // --------------------------------------------------------
        Rectangle {
          visible: root.showSettings
          width: parent.width
          implicitHeight: settingsCol.implicitHeight + Style.space(20)
          radius: Style.space(6)
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.04)
          border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.12)
          border.width: 1

          Column {
            id: settingsCol
            anchors.fill: parent
            anchors.margins: Style.space(10)
            spacing: Style.space(8)

            Text {
              textFormat: Text.PlainText
              text: strings.t("settings.heading")
              color: Color.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            // Max Stand Size (m²) stepper
            Row {
              width: parent.width
              spacing: Style.space(10)

              Text {
                textFormat: Text.PlainText
                text: strings.t("settings.maxSqm")
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(160)
              }

              Rectangle {
                width: Style.space(26)
                height: Style.space(22)
                radius: Style.space(4)
                color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
                Text { textFormat: Text.PlainText; anchors.centerIn: parent; text: "-"; color: root.fg; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.adjustMaxSqm(-50) }
              }

              Text {
                textFormat: Text.PlainText
                text: I18n.formatNumber(Math.round(root.configData.max_sqm || 500), 0) + " m²"
                color: Color.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                width: Style.space(72)
              }

              Rectangle {
                width: Style.space(26)
                height: Style.space(22)
                radius: Style.space(4)
                color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
                Text { textFormat: Text.PlainText; anchors.centerIn: parent; text: "+"; color: root.fg; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.adjustMaxSqm(50) }
              }
            }

            // Max USD Price stepper
            Row {
              width: parent.width
              spacing: Style.space(10)

              Text {
                textFormat: Text.PlainText
                text: strings.t("settings.maxPrice")
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(160)
              }

              Rectangle {
                width: Style.space(26)
                height: Style.space(22)
                radius: Style.space(4)
                color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
                Text { textFormat: Text.PlainText; anchors.centerIn: parent; text: "-"; color: root.fg; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.adjustMaxPrice(-5000) }
              }

              Text {
                textFormat: Text.PlainText
                text: (root.configData.max_price_usd && root.configData.max_price_usd > 0)
                  ? ("$" + I18n.formatNumber(Math.round(root.configData.max_price_usd), 0))
                  : strings.t("settings.anyPrice")
                color: Color.accent
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                width: Style.space(72)
              }

              Rectangle {
                width: Style.space(26)
                height: Style.space(22)
                radius: Style.space(4)
                color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
                Text { textFormat: Text.PlainText; anchors.centerIn: parent; text: "+"; color: root.fg; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.adjustMaxPrice(5000) }
              }
            }

            // Hourly Background Scan Toggle
            Row {
              width: parent.width
              spacing: Style.space(10)

              Text {
                textFormat: Text.PlainText
                text: strings.t("settings.hourlyLabel")
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(160)
              }

              Rectangle {
                width: Style.space(90)
                height: Style.space(22)
                radius: Style.space(4)
                color: root.configData.auto_scan_enabled
                  ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.22)
                  : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
                border.color: root.configData.auto_scan_enabled ? Color.accent : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.15)
                border.width: 1

                Text {
                  textFormat: Text.PlainText
                  anchors.centerIn: parent
                  text: root.configData.auto_scan_enabled ? strings.t("settings.enabled") : strings.t("settings.paused")
                  color: root.configData.auto_scan_enabled ? Color.accent : root.mutedColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.toggleAutoScan()
                }
              }
            }

            // Per-portal health strip
            Flow {
              visible: root.sourceStatus && root.sourceStatus.length > 0
              width: parent.width
              spacing: Style.space(8)

              Repeater {
                model: root.sourceStatus
                Text {
                  textFormat: Text.PlainText
                  text: (modelData.source_name || modelData.source) + ": " +
                        (modelData.status === "ok"
                          ? (I18n.formatNumber(modelData.scanned_count || 0, 0) + " ✓")
                          : "err")
                  color: modelData.status === "ok" ? root.mutedColor : Color.accent
                  font.family: root.fontFamily
                  font.pixelSize: Math.max(9, Style.font.caption - 1)
                }
              }
            }
          }
        }

        // --------------------------------------------------------
        // SEARCH INPUT
        // --------------------------------------------------------
        Row {
          visible: root.searching
          width: parent.width
          spacing: Style.space(6)

          Rectangle {
            width: parent.width - Style.space(34)
            height: Style.space(28)
            radius: Style.space(4)
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.04)
            border.color: Color.accent
            border.width: 1

            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.space(8)
              anchors.rightMargin: Style.space(8)
              spacing: Style.space(6)

              Text {
                textFormat: Text.PlainText
                text: "\uf002"
                color: root.mutedColor
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }

              TextInput {
                id: searchField
                width: parent.width - Style.space(24)
                anchors.verticalCenter: parent.verticalCenter
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                selectByMouse: true
                text: root.searchQuery
                onTextChanged: {
                  root.searchQuery = text
                  root.selectedIndex = 0
                }
                Keys.onEscapePressed: {
                  root.searchQuery = ""
                  root.searching = false
                  keyCatcher.forceActiveFocus()
                }
                Keys.onDownPressed: {
                  if (root.sortedMatches && root.sortedMatches.length > 0) {
                    root.selectedIndex = Math.min(root.sortedMatches.length - 1, root.selectedIndex + 1)
                    listingsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                  }
                }
                Keys.onUpPressed: {
                  if (root.sortedMatches && root.sortedMatches.length > 0) {
                    root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                    listingsList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
                  }
                }
                Keys.onReturnPressed: {
                  if (root.selectedIndex >= 0 && root.selectedIndex < root.sortedMatches.length) {
                    root.openUrl(root.sortedMatches[root.selectedIndex].url)
                  }
                }

                Text {
                  textFormat: Text.PlainText
                  anchors.fill: parent
                  text: strings.t("search.placeholder")
                  color: root.mutedColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  verticalAlignment: Text.AlignVCenter
                  visible: !searchField.text && !searchField.activeFocus
                }
              }
            }
          }

          Rectangle {
            width: Style.space(28)
            height: Style.space(28)
            radius: Style.space(4)
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)

            Text {
              textFormat: Text.PlainText
              anchors.centerIn: parent
              text: "\uf00d"
              color: root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.searchQuery = ""
                root.searching = false
                keyCatcher.forceActiveFocus()
              }
            }
          }
        }

        // --------------------------------------------------------
        // STATS & SORTING ROW
        // --------------------------------------------------------
        Item {
          width: parent.width
          height: Style.space(24)

          Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(6)

            Text {
              textFormat: Text.PlainText
              text: (root.searchQuery || root.selectedSuburb !== "all")
                ? strings.t("stats.filteredOf")
                    .arg(I18n.formatNumber(root.sortedMatches.length, 0))
                    .arg(I18n.formatNumber(root.matchCount, 0))
                : strings.tn("stats.standCount", root.matchCount).arg(I18n.formatNumber(root.matchCount, 0))
              color: root.matchCount > 0 ? Color.accent : root.fg
              font.bold: true
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Text {
              textFormat: Text.PlainText
              text: strings.t("stats.scanned").arg(I18n.formatNumber(root.stats.total_scanned || 0, 0))
              color: root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(7)

            Text {
              textFormat: Text.PlainText
              text: strings.t("sort.label")
              color: root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              textFormat: Text.PlainText
              text: strings.t("sort.latest")
              color: root.sortBy === "newest" ? Color.accent : root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: root.sortBy === "newest"
              anchors.verticalCenter: parent.verticalCenter

              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.sortBy = "newest" }
            }

            Text { textFormat: Text.PlainText; text: "·"; color: root.mutedColor; font.family: root.fontFamily; font.pixelSize: Style.font.caption; anchors.verticalCenter: parent.verticalCenter }

            Text {
              textFormat: Text.PlainText
              text: strings.t("sort.price")
              color: root.sortBy === "price" ? Color.accent : root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: root.sortBy === "price"
              anchors.verticalCenter: parent.verticalCenter

              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.sortBy = "price" }
            }

            Text { textFormat: Text.PlainText; text: "·"; color: root.mutedColor; font.family: root.fontFamily; font.pixelSize: Style.font.caption; anchors.verticalCenter: parent.verticalCenter }

            Text {
              textFormat: Text.PlainText
              text: strings.t("sort.size")
              color: root.sortBy === "size" ? Color.accent : root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: root.sortBy === "size"
              anchors.verticalCenter: parent.verticalCenter

              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.sortBy = "size" }
            }

            Text { textFormat: Text.PlainText; text: "·"; color: root.mutedColor; font.family: root.fontFamily; font.pixelSize: Style.font.caption; anchors.verticalCenter: parent.verticalCenter }

            Text {
              textFormat: Text.PlainText
              text: strings.t("sort.suburb")
              color: root.sortBy === "suburb" ? Color.accent : root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: root.sortBy === "suburb"
              anchors.verticalCenter: parent.verticalCenter

              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.sortBy = "suburb" }
            }

            Text {
              textFormat: Text.PlainText
              text: "\uf002"
              color: root.searching ? Color.accent : root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              anchors.verticalCenter: parent.verticalCenter

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.searching = !root.searching
                  if (root.searching) {
                    Qt.callLater(function() { searchField.forceActiveFocus() })
                  }
                }
              }
            }
          }
        }

        // --------------------------------------------------------
        // SCROLLABLE LISTVIEW FOR STANDS
        // --------------------------------------------------------
        ListView {
          id: listingsList
          width: parent.width
          height: Math.min(contentHeight, root.showSettings ? Style.space(220) : (root.searching ? Style.space(310) : Style.space(360)))
          visible: root.sortedMatches.length > 0
          clip: true
          model: root.sortedMatches
          spacing: Style.space(6)
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          interactive: contentHeight > height
          currentIndex: root.selectedIndex

          ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
          }

          delegate: Rectangle {
            id: cardRect
            width: listingsList.width - (listingsList.interactive ? Style.space(8) : 0)
            implicitHeight: cardCol.implicitHeight + Style.space(16)
            radius: Style.space(6)
            color: (root.selectedIndex === index)
              ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
              : (cardMouse.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.04) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.02))
            border.color: (root.selectedIndex === index)
              ? Color.accent
              : (cardMouse.containsMouse ? Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.16) : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08))
            border.width: 1

            MouseArea {
              id: cardMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: root.selectedIndex = index
              onClicked: root.openUrl(modelData.url)
            }

            Column {
              id: cardCol
              anchors.fill: parent
              anchors.margins: Style.space(8)
              spacing: Style.space(4)

              // Line 1: Price · Size · Suburb · Tenure + Open CTA
              Item {
                width: parent.width
                implicitHeight: Math.max(line1Left.implicitHeight, openHintText.implicitHeight)

                Row {
                  id: line1Left
                  anchors.left: parent.left
                  anchors.right: openHintText.left
                  anchors.rightMargin: Style.space(6)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(6)

                  Text {
                    textFormat: Text.PlainText
                    text: root.formatUsd(modelData.price_usd)
                    color: Color.accent
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.title
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text { textFormat: Text.PlainText; text: "·"; color: root.mutedColor; font.family: root.fontFamily; font.pixelSize: Style.font.caption; anchors.verticalCenter: parent.verticalCenter }

                  Text {
                    textFormat: Text.PlainText
                    text: root.formatSize(modelData.size_sqm)
                    color: root.fg
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text { textFormat: Text.PlainText; text: "·"; color: root.mutedColor; font.family: root.fontFamily; font.pixelSize: Style.font.caption; anchors.verticalCenter: parent.verticalCenter }

                  Text {
                    textFormat: Text.PlainText
                    text: modelData.suburb || ""
                    color: root.fg
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    visible: Boolean(modelData.tenure && modelData.tenure !== "")
                    textFormat: Text.PlainText
                    text: "· " + (modelData.tenure || "")
                    color: Color.accent
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                Text {
                  id: openHintText
                  textFormat: Text.PlainText
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: (root.selectedIndex === index) ? strings.t("card.openSelected") : (strings.t("card.open") + " \uf08e")
                  color: Color.accent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }

              // Line 2: Listing Title
              Text {
                textFormat: Text.PlainText
                width: parent.width
                text: modelData.title || ""
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                elide: Text.ElideRight
                maximumLineCount: 1
              }

              // Line 3: Agency / Portal + Utilities + Relative Age
              Item {
                width: parent.width
                implicitHeight: Math.max(line3Left.implicitHeight, line3TimeText.implicitHeight)

                Row {
                  id: line3Left
                  anchors.left: parent.left
                  anchors.right: line3TimeText.visible ? line3TimeText.left : parent.right
                  anchors.rightMargin: line3TimeText.visible ? Style.space(8) : 0
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(5)

                  Text {
                    textFormat: Text.PlainText
                    text: "\uf1ad"
                    color: root.mutedColor
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    textFormat: Text.PlainText
                    width: parent.width - Style.space(16)
                    elide: Text.ElideRight
                    text: {
                      var src = modelData.source_name || modelData.source || ""
                      var seller = modelData.seller_name || ""
                      var base = (seller && seller !== src) ? (src + " · " + seller) : src
                      if (modelData.servicing && modelData.servicing !== "") {
                        base += " · " + modelData.servicing
                      }
                      if (modelData.also_seen_on && modelData.also_seen_on.length > 0) {
                        base += " (+" + modelData.also_seen_on.length + ")"
                      }
                      return base
                    }
                    color: root.mutedColor
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                Text {
                  id: line3TimeText
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  readonly property string timeStr: root.formatRelativeTime(modelData.posted_at || modelData.first_seen_at)
                  visible: timeStr !== ""
                  textFormat: Text.PlainText
                  text: "\uf017 " + timeStr
                  color: (timeStr.indexOf("m ago") !== -1 || timeStr === "Just now" || timeStr.indexOf("h ago") !== -1) ? Color.accent : root.mutedColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: (timeStr.indexOf("m ago") !== -1 || timeStr === "Just now")
                }
              }
            }
          }
        }

        // --------------------------------------------------------
        // EMPTY / NO-MATCH STATE
        // --------------------------------------------------------
        Rectangle {
          visible: root.sortedMatches.length === 0
          width: parent.width
          height: Style.space(120)
          radius: Style.space(6)
          color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.03)
          border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)
          border.width: 1

          Column {
            anchors.centerIn: parent
            spacing: Style.space(6)
            width: parent.width - Style.space(30)

            Text {
              textFormat: Text.PlainText
              anchors.horizontalCenter: parent.horizontalCenter
              text: (root.searchQuery || root.selectedSuburb !== "all") ? strings.t("empty.filterTitle") : strings.t("empty.noneTitle")
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }

            Text {
              textFormat: Text.PlainText
              anchors.horizontalCenter: parent.horizontalCenter
              text: (root.searchQuery || root.selectedSuburb !== "all")
                ? strings.t("empty.filterDesc").arg(root.searchQuery || root.selectedSuburb)
                : strings.t("empty.noneDesc")
                    .arg(I18n.formatNumber(root.stats.total_scanned || 0, 0))
                    .arg(I18n.formatNumber(Math.round(root.configData.max_sqm || 500), 0))
              color: root.mutedColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
              width: parent.width
            }

            Row {
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: Style.space(8)

              Rectangle {
                visible: !root.searchQuery && root.selectedSuburb === "all"
                height: Style.space(24)
                width: Style.space(96)
                radius: Style.space(4)
                color: Color.accent

                Text {
                  textFormat: Text.PlainText
                  anchors.centerIn: parent
                  text: root.isScanning ? strings.t("hero.scanningBtn") : strings.t("hero.scanNow")
                  color: Color.background
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.triggerScan()
                }
              }

              Rectangle {
                visible: !root.searchQuery && root.selectedSuburb === "all"
                height: Style.space(24)
                width: Style.space(96)
                radius: Style.space(4)
                color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.08)

                Text {
                  textFormat: Text.PlainText
                  anchors.centerIn: parent
                  text: "\uf120 " + strings.t("empty.openCli")
                  color: root.fg
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.openTerminal()
                }
              }

              Rectangle {
                visible: root.searchQuery !== "" || root.selectedSuburb !== "all"
                height: Style.space(24)
                width: Style.space(100)
                radius: Style.space(4)
                color: Color.accent

                Text {
                  textFormat: Text.PlainText
                  anchors.centerIn: parent
                  text: strings.t("empty.clearFilter")
                  color: Color.background
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.searchQuery = ""
                    root.selectedSuburb = "all"
                    root.searching = false
                    keyCatcher.forceActiveFocus()
                  }
                }
              }
            }
          }
        }

        // --------------------------------------------------------
        // FOOTER
        // --------------------------------------------------------
        Item {
          width: parent.width
          height: Style.space(24)

          Text {
            textFormat: Text.PlainText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: strings.t("footer.updated").arg(root.lastUpdated) + (root.sortedMatches.length > 1 ? strings.t("footer.navHint") : "")
            color: root.mutedColor
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }

          Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Style.space(24)
            width: Style.space(94)
            radius: Style.space(4)
            color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.06)

            Text {
              textFormat: Text.PlainText
              anchors.centerIn: parent
              text: "\uf120 " + strings.t("footer.terminal")
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openTerminal()
            }
          }
        }
      }
    }
  }
}
