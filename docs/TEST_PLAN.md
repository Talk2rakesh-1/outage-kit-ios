# Manual acceptance plan

Not yet executed in a running simulator/device. Local sandbox access to CoreSimulator was unavailable. Native SDK compilation is verified separately.

1. Launch empty: clear empty-state guidance, no false readiness percentage.
2. Add flashlight, stock 0, target 2; save; row says needs more.
3. Edit stock to 2; save; row says stocked. Relaunch and confirm persistence.
4. Add an expiry of yesterday: row says expired even with enough stock. Today remains valid.
5. Search by partial name; clear search; all supplies return.
6. Swipe delete, cancel, verify no deletion; repeat and confirm.
7. Try whitespace name and oversized name; editor retains input with a readable error.
8. Test large Dynamic Type, dark mode, iPad layout, and VoiceOver navigation and announcements.
9. Run in airplane mode; all local operations should still work.
10. With app stopped, replace its stored JSON with corrupt content; relaunch. Error and retry appear, original file remains, Add is disabled.
11. Verify protected storage on a physical device and device-backup behavior before any distribution.
