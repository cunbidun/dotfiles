# Quickshell Review

Last updated: 2026-06-20

Status: all findings addressed.

## Resolved Findings

- [x] Exclude loopback from dashboard network stats with the correct `/proc/net/dev` field.
- [x] Use `weatherMetric` for hourly forecast temperature units.
- [x] Cap rendered notification actions at three buttons to prevent overflow.
- [x] Make `withAlpha()` return transparent for invalid or transparent input.
- [x] Remove optimistic `nightLight` state writes after toggle.
- [x] Run dashboard stats polling only while the dashboard popup is visible.
- [x] Remove automatic full stats refresh after every dashboard action.
- [x] Poll Fcitx only when an Fcitx tray item exists.
- [x] Remove unused `Weather.qml`.
- [x] Remove duplicated inactive weather fetch path by keeping only calendar weather.
- [x] Move shared popup X positioning into `ModuleChip.qml`.
- [x] Replace duplicated inline `TextButton` and `IconButton` components with shared files.
- [x] Add `popupElementSize` for generic popup controls.
- [x] Make `dashboardControlCell` scale from `em`.
- [x] Add `popupBorderWidth` and use it across popup borders.
- [x] Use one `Theme` instance at `ShellRoot` scope.
- [x] Remove the duplicate `rem` alias from `Theme.qml`.
- [x] Derive `recording` and `nightLight` from polled stats only.
- [x] Recompute workspace buttons from workspace collection changes instead of raw events.

## Validation

- `rtk quickshell-reload-cunbidun` exits successfully.
- `quickshell-cunbidun.service` is active.
- Recent QuickShell log ends with `INFO: Configuration Loaded`.
