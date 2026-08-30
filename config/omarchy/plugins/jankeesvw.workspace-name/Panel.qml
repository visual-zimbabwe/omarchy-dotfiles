import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

// Workspace name: shows the name and the icon given to the current workspace,
// and lets you set them.
//
// The widget takes up no room at all until a workspace has one or the other,
// so a bar with this in it looks untouched until you start using it.
//
// Names and icons live one per file in $XDG_STATE_HOME/workspace-hud/<id> and
// <id>.icon, plain text, no daemon and no database. Anything else you run can
// read the current name with a cat, and writing one from a script is a
// redirect. Both files are watched, so the bar picks that up without being
// told. The directory is yours alone, though: what you call your workspaces
// says what you are working on, so it is kept at 700 with 600 files.
//
// It can draw the workspace indicators as well, off by default. An icon is
// only half useful on the workspace you are already on; the row of numbers is
// where you look to find the one you want. Turned on, this widget replaces
// omarchy.workspaces rather than sitting next to it, which is what keeps the
// two from ever showing different icons for the same workspace.
Panel {
  id: root

  moduleName: "jankeesvw.workspace-name"
  ipcTarget: "jankeesvw.workspace-name"

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  // Panel is a bare Item, unlike BarWidget: these two do not come with it.
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property int barSize: bar ? bar.barSize : Style.bar.sizeHorizontal

  // Drawing the indicators means standing in for omarchy.workspaces, which is
  // too big a thing to switch on for someone who installed a name widget. On
  // by default; set "indicators": false in shell.json to hide them.
  readonly property bool showIndicators: setting("indicators", true) === true
  // An icon in place of the number keeps a button one character wide, the size
  // the stock indicators are built at. Keeping both reads as "icon 4" and has
  // to grow the button, which is a change to the shape of the bar.
  readonly property bool showNumbers: setting("numbers", false) === true
  // How many workspaces stand on the bar whether or not they exist yet. Five
  // is what the stock indicators hold open, which suits a machine where the
  // high ones come and go; someone who lives on ten wants all ten there, empty
  // or not, so the row does not reflow under the cursor. The ceiling is only
  // there to keep a typo from drawing a thousand buttons.
  readonly property int alwaysShown: Math.max(1, Math.min(99, setting("alwaysShown", 5)))

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/workspace-hud"

  property string workspaceName: ""
  property string workspaceIcon: ""

  // The icon the panel will save. Held here rather than in a field, because
  // the picker is the whole of the icon interface now.
  property string pickedIcon: ""
  readonly property int workspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
  readonly property bool hasName: workspaceName !== ""
  readonly property bool hasIcon: workspaceIcon !== ""

  // An icon alone is a perfectly good label — a workspace can be the one with
  // the terminals without also being called "terminals" — so either half is
  // enough to put the widget on the bar.
  //
  // Except when the indicators are drawn: the icon is already sitting on this
  // workspace's own button a few pixels to the left, and the same thing shown
  // twice in one bar reads as two things. There the label is the name alone.
  readonly property string labelText: {
    if (showIndicators) return workspaceName
    if (hasIcon && hasName) return workspaceIcon + "  " + workspaceName
    if (hasIcon) return workspaceIcon
    if (workspaceName) return workspaceName
    // Placeholder: show the workspace number so there is something to click
    // on to open the naming panel.  Only after the initial file read, so the
    // widget stays invisible during the brief load.
    if (seenFirstRead && workspaceId > 0) return String(workspaceId)
    return ""
  }
  readonly property bool hasLabel: labelText !== ""

  // Brief accent flash whenever the label changes, so a workspace switch is
  // noticeable out of the corner of your eye instead of something you have to
  // read. Held back until both files have reported once: they are read
  // independently, so whichever of the two lands second would otherwise
  // flash at login for a label that was already right.
  property bool flashing: false
  property bool seenNameRead: false
  property bool seenIconRead: false
  readonly property bool seenFirstRead: seenNameRead && seenIconRead

  // The panel names the workspace it was opened on. Move to another one and
  // it is aimed at a workspace you have left, its fields filling with someone
  // else's name under your hands, so it closes instead of following along.
  onWorkspaceIdChanged: if (opened) close()

  onLabelTextChanged: {
    if (!seenFirstRead) return
    flashing = true
    flashTimer.restart()
  }

  Timer {
    id: flashTimer
    interval: 450
    onTriggered: root.flashing = false
  }

  // Without a name, an icon or a row of indicators the widget shows only a
  // workspace-number placeholder — big enough to click, small enough to stay
  // out of the way.  The layout skips a hidden child, and WidgetButton hides
  // itself on empty text, so both cases fall out on their own.
  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  // A small, opinionated set of icons for the things people actually keep a
  // workspace for. Brand marks are left out: a workspace is a kind of work,
  // not a logo, and a picker full of them dates fast. The exceptions are the
  // handful this bar's workspace indicators already use, so the two agree.
  // Anything outside the set still goes in the file by hand, since that is
  // the vocabulary and this is only the shortcut.
  //
  // Stored as codepoints rather than glyphs: Private Use Area characters do
  // not survive every editor and every copy-paste, and a list of them reads
  // as a column of blanks in a diff. Every one of these was checked against
  // the font Omarchy ships.
  readonly property var presetIcons: [
    0xEAC4, 0xF120, 0xE73E, 0xF040, 0xF02D, 0xF07B, 0xE69C,
    0xE8A4, 0xF01EE, 0xE217, 0xF232, 0xE820, 0xEB72, 0xF086, 0xF292,
    0xEC1B, 0xF03D, 0xF030, 0xF03E, 0xF1FC, 0xF11B, 0xF108, 0xF073,
    0xF017, 0xF002, 0xF188, 0xF080, 0xF1C0, 0xF233, 0xF0C2, 0xE712,
    0xF015, 0xF013, 0xF023, 0xF0C3, 0xF135, 0xF0F4, 0xF005, 0xEA71,
    0xF2D0, 0xF0AC, 0xF0E7, 0xF249, 0xF0F6, 0xF02E, 0xF0AD, 0xF084,
    0xF0B1, 0xF1D3, 0xF1B2, 0xF132, 0xF19D, 0xF155, 0xF07A, 0xF279,
    // VS Code, GitHub, Docker, Firefox, and Discord
    0xF0A1E, 0xF02A4, 0xF0868, 0xF0239, 0xF066F
  ]
  // Foreground at a given alpha, for the picker's hover and selection fills.
  function tint(alpha) {
    return Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, alpha)
  }

  // What comes out of the state files is input, not our own text: anything on
  // the system can write one, and the README invites exactly that.
  //
  // A Text with no textFormat is Text.AutoText, and Qt then decides for itself
  // whether a string is markup. It renders one that looks like it as rich
  // text, and rich text really loads <img src="http://...">: a request out of
  // the shell process, to a host chosen by whoever wrote the file. The label
  // is painted by the bar's own WidgetButton, so that element's textFormat is
  // not ours to set; the markup has to be gone before the string reaches it.
  //
  // The length cap is the same thought from the other side. A name file holds
  // whatever was echoed into it, and a bar label is no place for a megabyte of
  // it. Collapsing whitespace goes with it: a name is one line.
  function plain(value) {
    return String(value || "").replace(/[<>]/g, "").replace(/\s+/g, " ").trim().slice(0, 64)
  }

  // Which workspaces the row shows: the first `alwaysShown` of them whether
  // they exist or not, so the bar does not reflow as they come and go, plus
  // whatever else happens to exist.
  //
  // That second half stops at ten, or at the number held open when that is
  // higher. Some tool somewhere will make workspace 4711 one day, and a
  // workspace nobody asked for should not be able to stretch the bar.
  function workspaceIds() {
    var ids = []
    for (var n = 1; n <= root.alwaysShown; n++) ids.push(n)

    var ceiling = Math.max(root.alwaysShown, 10)
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= ceiling && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  readonly property var indicatorIds: showIndicators ? workspaceIds() : []

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function focusWorkspace(id) {
    if (!root.bar) return

    // bar.run hands this to a shell, and a workspace id comes from Hyprland
    // rather than from here, so it is turned into a number before it is turned
    // into a command. A value that is not one is not repaired, it is dropped.
    var n = Math.trunc(Number(id))
    if (!(n > 0)) return

    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + n + "\" })"))
  }

  // Icons for the whole row. Kept apart from the focused workspace's own
  // reader below, which has to work for any id, including one past the ten
  // the row draws.
  property var indicatorIcons: ({})

  // Replaced wholesale rather than edited in place: QML only notices a var
  // property when it is assigned, so mutating the object would leave every
  // button bound to it stale.
  function setIndicatorIcon(id, glyph) {
    var next = {}
    for (var key in indicatorIcons) next[key] = indicatorIcons[key]

    if (glyph === "") delete next[id]
    else next[id] = glyph

    indicatorIcons = next
  }

  // A workspace with no icon falls back to its number, which is the whole of
  // what the stock indicators ever show. Ten reads as 0 there, so it does
  // here.
  function indicatorText(id) {
    var icon = indicatorIcons[id] || ""
    var number = id === 10 ? "0" : String(id)

    if (icon === "") return number
    return root.showNumbers ? icon + " " + number : icon
  }

  Instantiator {
    id: iconViews
    model: root.indicatorIds

    delegate: FileView {
      // Typed, so what goes into the path below is a number and nothing else.
      required property int modelData

      path: root.iconFilePath(modelData)
      watchChanges: true
      printErrors: false
      onFileChanged: reload()
      onLoaded: root.setIndicatorIcon(modelData, root.parseIcon(text().trim()))
      onLoadFailed: root.setIndicatorIcon(modelData, "")
    }
  }

  FileView {
    id: dirWatcher
    path: root.stateDir
    watchChanges: true
    printErrors: false
    onFileChanged: {
      if (iconViews) {
        for (var i = 0; i < iconViews.count; i++) {
          var item = iconViews.objectAt(i)
          if (item) item.reload()
        }
      }
      if (nameFileView) nameFileView.reload()
      if (iconFileView) iconFileView.reload()
    }
  }

  function nameFilePath(id) {
    return root.stateDir + "/" + id
  }

  function iconFilePath(id) {
    return root.stateDir + "/" + id + ".icon"
  }

  function toggleIcon(glyph) {
    if (!glyph) return
    var current = (iconField.text || "").trim()
    var list = current.length > 0 ? current.split(/\s+/) : []
    var idx = list.indexOf(glyph)
    if (idx !== -1) {
      list.splice(idx, 1)
    } else {
      list.push(glyph)
    }
    iconField.text = list.join(" ")
    root.pickedIcon = iconField.text
  }

  function clearAll() {
    iconField.text = ""
    nameField.text = ""
    root.pickedIcon = ""
    root.save()
  }

  function parseIcon(raw) {
    var value = String(raw || "").trim()
    if (value === "") return ""

    var hex = value.match(/^(?:u\+|0x|\\u)?([0-9a-f]{4,6})$/i)
    if (hex) {
      var cp = parseInt(hex[1], 16)
      if (cp > 0 && cp <= 0x10FFFF) return String.fromCodePoint(cp)
    }

    return value.replace(/[<>]/g, "")
  }

  function save() {
    var newName = root.plain(nameField.text)
    var newIcon = root.plain(iconField.text)

    // Optimistically update live state immediately
    root.workspaceName = newName
    root.workspaceIcon = newIcon
    root.setIndicatorIcon(root.workspaceId, newIcon)

    writeProc.command = ["sh", "-c",
      'name="$1"; icon="$2"; namePath="$3"; iconPath="$4"; ' +
      'umask 077; ' +
      'mkdir -p -m 700 -- "$(dirname -- "$namePath")" 2>/dev/null; ' +
      'if [ -n "$name" ]; then printf "%s\\n" "$name" > "$namePath" && chmod 600 -- "$namePath"; else rm -f -- "$namePath"; fi; ' +
      'if [ -n "$icon" ]; then printf "%s\\n" "$icon" > "$iconPath" && chmod 600 -- "$iconPath"; else rm -f -- "$iconPath"; fi',
      "sh",
      newName,
      newIcon,
      root.nameFilePath(root.workspaceId),
      root.iconFilePath(root.workspaceId)]
    writeProc.running = true
    close()
  }

  Process {
    id: writeProc
  }

  // The name file for the focused workspace. Changing `path` on a workspace
  // switch reloads it, which is why nothing here listens to Hyprland for a
  // redraw. Watched as well, so a name written by anything else on the system
  // lands in the bar without being told about it. An absent file is the normal
  // case, not an error: a workspace simply has no name yet.
  FileView {
    id: nameFileView
    path: root.workspaceId > 0 ? root.nameFilePath(root.workspaceId) : ""
    watchChanges: true
    printErrors: false
    // text() is stale inside the change signal, so go around through reload()
    // and read it in onLoaded.
    onFileChanged: reload()
    onLoaded: { root.workspaceName = root.plain(text()); root.seenNameRead = true }
    onLoadFailed: { root.workspaceName = ""; root.seenNameRead = true }
  }

  // The icon file, on exactly the same terms as the name file. Parsed on read
  // as well as on write, so a codepoint dropped in from a script shows up as
  // the glyph rather than as four literal characters.
  FileView {
    id: iconFileView
    path: root.workspaceId > 0 ? root.iconFilePath(root.workspaceId) : ""
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: { root.workspaceIcon = root.parseIcon(text().trim()); root.seenIconRead = true }
    onLoadFailed: { root.workspaceIcon = ""; root.seenIconRead = true }
  }

  // FileView only watches a file it can resolve, and it cannot create the
  // directory the first name will be written into. Do that once at startup.
  //
  // And make it private while we are here. What you call your workspaces is a
  // list of what you are working on — a client, a case number, an employer you
  // have not told anyone about yet — and until now this directory was made at
  // 755 with 644 files, so every account on the machine could read the lot.
  // The chmod pass is for those older installs: mkdir leaves the mode of a
  // directory that already exists alone, and so does a redirect into a file
  // that already exists.
  //
  // A directory somebody deliberately made a symlink is left exactly as it is,
  // modes included. Following it to chmod whatever is on the other end is the
  // one thing this should not do, and refusing to run at all would break a
  // setup that works.
  Process {
    id: ensureStateDir
    running: true
    command: ["sh", "-c",
      'dir=$1; ' +
      '[ -L "$dir" ] && exit 0; ' +
      'mkdir -p -m 700 -- "$dir" 2>/dev/null || exit 0; ' +
      'chmod 700 -- "$dir" 2>/dev/null; ' +
      'find "$dir" -maxdepth 1 -type f -exec chmod 600 -- {} + 2>/dev/null; ' +
      'exit 0',
      "sh", root.stateDir]
  }

  onOpenedChanged: {
    if (opened) {
      iconField.text = workspaceIcon
      nameField.text = workspaceName
      nameField.deselect()
      iconField.deselect()
      pickedIcon = workspaceIcon
      presets.currentIndex = -1
    }
  }

  GridLayout {
    id: content
    anchors.fill: parent
    columns: root.vertical ? 1 : root.indicatorIds.length + 1
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.indicatorIds

      Item {
        id: slot
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: root.workspaceId === modelData

        readonly property string iconGlyph: root.indicatorIcons[modelData] || ""
        readonly property string numberText: modelData === 10 ? "0" : String(modelData)
        // With both shown, the icon and the number are drawn as two items
        // rather than as one string. Every Nerd Font glyph advances exactly
        // one monospace cell, but the ink inside that cell runs from about
        // half a cell to nearly two: the wide ones spill past their own
        // advance and crowd the number, the narrow ones leave a hole. One
        // space between them is therefore not one gap, it is whatever each
        // glyph happened to leave over. Measuring the ink and placing the two
        // by hand is what makes the gap the same under every icon.
        readonly property bool pairDrawn: root.showNumbers && iconGlyph !== ""
        readonly property real pairGap: Style.spaceReal(5)

        implicitWidth: button.implicitWidth
        implicitHeight: button.implicitHeight

        // The workspace you are on is marked by a filled block behind it, the
        // way the stock indicators mark theirs, rather than by recoloring the
        // glyph. An icon is picked to be recognised, and recoloring spends the
        // one thing it was chosen for. The block sits under the icon, so both
        // survive.
        Rectangle {
          anchors.fill: parent
          anchors.topMargin: Style.space(3)
          anchors.bottomMargin: Style.space(3)
          radius: Style.cornerRadius
          color: root.tint(0.18)
          visible: parent.focused
        }

        WidgetButton {
          id: button
          anchors.fill: parent
          bar: root.bar
          text: root.indicatorText(slot.modelData)
          // The pair below stands in for the built-in label when it is drawn.
          labelVisible: !slot.pairDrawn
          opacity: slot.occupied || slot.focused ? 1 : 0.5
          horizontalMargin: 6
          verticalPadding: 6
          fixedWidth: root.vertical
                      ? root.barSize
                      : (slot.pairDrawn
                         ? pair.implicitWidth + button.scaledHorizontalMargin * 2
                         : (root.showNumbers || slot.iconGlyph.length > 0 ? -1 : Style.space(20)))
          fixedHeight: root.barSize
          // Clicking the workspace you are already on has nothing to focus,
          // so that click opens the panel instead. The button you are looking
          // at is the one you want to name, and it takes the same plain left
          // click as everything else on the bar.
          onPressed: function(b) {
            if (slot.focused) root.toggle()
            else root.focusWorkspace(slot.modelData)
          }

          // tightBoundingRect is the ink, as against the advance width the
          // string layout would have used.
          TextMetrics {
            id: iconInk
            font.family: button.fontFamily
            font.pixelSize: button.fontSize
            text: slot.iconGlyph
          }

          Item {
            id: pair
            visible: slot.pairDrawn
            anchors.centerIn: parent
            implicitWidth: iconInk.tightBoundingRect.width + slot.pairGap + numberLabel.implicitWidth
            implicitHeight: numberLabel.implicitHeight
            width: implicitWidth
            height: implicitHeight

            Text {
              id: iconLabel
              // Pulled left by the ink's own left bearing, so the glyph starts
              // at the left edge of the width it was measured into.
              x: -iconInk.tightBoundingRect.x
              // Baseline rather than centre: this is where a single string put
              // the two, and it is what keeps an icon sitting on the number's
              // own line instead of floating above it.
              anchors.baseline: numberLabel.baseline
              text: slot.iconGlyph
              // The glyph is read out of a file another process writes, so
              // never AutoText: Qt decides for itself that something
              // tag-shaped is rich text and then fetches what it points at.
              // parseIcon only ever returns a single codepoint today, which
              // cannot form markup, but that is a property of parseIcon and
              // not of this element.
              textFormat: Text.PlainText
              color: button.foreground
              font.family: button.fontFamily
              font.pixelSize: button.fontSize
              renderType: Text.NativeRendering
            }

            Text {
              id: numberLabel
              x: iconInk.tightBoundingRect.width + slot.pairGap
              anchors.verticalCenter: parent.verticalCenter
              text: slot.numberText
              textFormat: Text.PlainText
              color: button.foreground
              font.family: button.fontFamily
              font.pixelSize: button.fontSize
              renderType: Text.NativeRendering
            }
          }
        }
      }
    }

    WidgetButton {
      id: label
      bar: root.bar
      text: root.labelText
      active: root.flashing
      // Wider than a plain button: the name is prose sitting in a row of
      // single glyphs and needs the air to read as its own thing.
      horizontalMargin: 16
      verticalPadding: 6
      fixedWidth: root.vertical ? root.barSize : -1
      fixedHeight: root.barSize
      tooltipText: ""
      onPressed: function(b) { root.toggle() }
    }
  }

  // The bar draws a dash under whichever module owns the open panel, centered
  // on that module's slot. Centered on this one it lands mid-row, under a
  // workspace that has nothing to do with the panel, and only its length is
  // ours to set, never its place. A mark pointing at the wrong thing is worse
  // than no mark, so the panel registers with the bar's one-popup-at-a-time
  // coordinator under this stand-in instead of under the widget. The bar
  // compares that registration against the module to decide what to mark, so
  // it finds no match and marks nothing, while every other panel on the bar
  // still closes this one when it opens.
  QtObject {
    id: popoutKey

    readonly property bool popoutSwitchClosing: root.popoutSwitchClosing

    function close() { root.close() }
    function closeForPopoutSwitch() { root.closeForPopoutSwitch() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: label.visible ? label : content
    owner: popoutKey
    bar: root.bar
    open: root.opened
    focusTarget: nameField
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(8)

      PanelSectionHeader {
        width: parent.width
        textFormat: Text.PlainText
        text: "WORKSPACE " + root.workspaceId
        foreground: root.foreground
        fontFamily: root.fontFamily
      }

      // Input Row: Icons Field (front/left) + Name Field (right) + Save Button
      RowLayout {
        width: parent.width
        spacing: Style.space(4)

        TextField {
          id: iconField
          Layout.preferredWidth: Style.space(110)
          placeholderText: "Icons"
          text: root.pickedIcon
          foreground: Color.accent
          font.pixelSize: Style.font.icon
          verticalPadding: Style.space(4)
          onAccepted: root.save()
          Keys.onEscapePressed: root.close()
        }

        TextField {
          id: nameField
          Layout.fillWidth: true
          placeholderText: "Workspace name (optional)"
          foreground: root.foreground
          verticalPadding: Style.space(4)
          onAccepted: root.save()
          Keys.onEscapePressed: root.close()
          Keys.onDownPressed: presets.forceActiveFocus()
        }

        PanelActionButton {
          iconText: "\uf00c"
          tooltipText: "Save workspace"
          bordered: true
          onClicked: root.save()
        }
      }

      // Quick Clear and Toggle hint row
      RowLayout {
        width: parent.width
        spacing: Style.space(6)

        Text {
          Layout.fillWidth: true
          text: "Click icons to toggle on/off:"
          color: Qt.darker(root.foreground, 1.4)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        PanelActionButton {
          iconText: "\u00d7"
          tooltipText: "Clear all"
          bordered: true
          onClicked: root.clearAll()
        }
      }

      Grid {
        id: presets
        width: parent.width
        columns: 8
        spacing: Style.space(2)

        readonly property real cell: Math.floor((width - spacing * (columns - 1)) / columns)
        readonly property int count: root.presetIcons.length

        function glyphAt(i) {
          return String.fromCodePoint(root.presetIcons[i])
        }

        Repeater {
          model: presets.count

          Rectangle {
            required property int index
            readonly property string glyph: presets.glyphAt(index)
            readonly property bool chosen: (iconField.text || "").indexOf(glyph) !== -1

            width: presets.cell
            height: presets.cell
            radius: Style.cornerRadius
            color: chosen ? root.tint(0.35)
              : (hover.hovered ? root.tint(0.12) : "transparent")
            border.color: chosen ? Color.accent : (hover.hovered ? root.tint(0.3) : "transparent")
            border.width: 1

            Text {
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: parent.glyph
              color: parent.chosen ? Color.accent : root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.icon
            }

            HoverHandler { id: hover }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.toggleIcon(parent.glyph)
            }
          }
        }
      }
    }
  }
}
