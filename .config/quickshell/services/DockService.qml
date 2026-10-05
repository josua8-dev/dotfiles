// ╭──────────────────────────────────────────────────────────────────────────╮
// │                                                                          │
// │   D O C K   S E R V I C E                                                │
// │   kept applications · pinned and running                                  │
// │                                                                          │
// │   github.com/andreumassanet/impasto                                      │
// │                                                                          │
// ╰──────────────────────────────────────────────────────────────────────────╯

pragma Singleton

import QtQml
import QtQuick
import Quickshell

import "../theme"

// The pinned ("kept") application list, which leads the launcher, and the
// fullscreen test the desktop's spectrum asks for.
//
// The dock surface itself is gone: this service now only owns the list of
// applications the user keeps, and the window queries that list needs.
Singleton {
    id: root

    // ── PINNED ──────────────────────────────────────────────────────────────
    //
    // Kept locally and written to the settings on a debounce. Reading back
    // from the JsonAdapter mid-edit returns a stale value, so consecutive
    // reorders would build on the wrong list.
    property var pinned: SettingsService.dockPinned ?? []

    Connections {
        target: SettingsService

        function onDockPinnedChanged(): void {
            if (saver.running)
                return
            root.pinned = SettingsService.dockPinned ?? []
        }
    }

    readonly property Timer saver: Timer {
        interval: 120
        onTriggered: SettingsService.set("dockPinned", root.pinned)
    }

    function write(next: var): void {
        root.pinned = next
        saver.restart()
    }

    function isPinned(id: string): bool {
        return id !== "" && root.pinned.indexOf(id) >= 0
    }

    function pin(id: string): void {
        if (id === "" || root.isPinned(id))
            return
        root.write(root.pinned.concat([id]))
    }

    function unpin(id: string): void {
        if (!root.isPinned(id))
            return
        root.write(root.pinned.filter(entry => entry !== id))
    }

    function togglePin(id: string): void {
        if (root.isPinned(id))
            root.unpin(id)
        else
            root.pin(id)
    }

    // `from` and `to` are positions in the pinned list.
    function reorder(from: int, to: int): void {
        if (from < 0 || from >= root.pinned.length || to < 0 || to >= root.pinned.length
                || from === to)
            return
        const next = root.pinned.slice()
        next.splice(to, 0, next.splice(from, 1)[0])
        root.write(next)
    }

    readonly property int pinnedCount: root.pinned.length

    // ── APPLICATION INDEX ───────────────────────────────────────────────────

    readonly property var applications: LauncherService.applications

    function entryOf(id: string): var {
        return root.applications.find(app => app.id === id) ?? null
    }

    // ── RUNNING ─────────────────────────────────────────────────────────────
    //
    // Keeps `HyprlandService.clients` live while anything asks for the
    // fullscreen test: the desk's spectrum, the overview and the launcher all
    // read the list. Without it, refreshes only happen while the list is
    // non-empty, which is fine for the overview but freezes once the last
    // window closes.
    readonly property Binding watching: Binding {
        target: HyprlandService
        property: "watchClients"
        value: true
    }

    Component.onCompleted: HyprlandService.loadClients()

    // A fullscreen window on the workspace a screen is showing. Hyprland
    // reports maximised as 1 and fullscreen as 2; only the latter takes the
    // spectrum away — and only on its own screen.
    function coveredOn(name: string): bool {
        const workspace = HyprlandService.activeOn(name)
        return workspace > 0 && HyprlandService.clients.some(
            client => (client.fullscreen ?? 0) >= 2
                && client.workspace && client.workspace.id === workspace)
    }
}
