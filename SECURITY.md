# Security

Report a vulnerability using this repository’s GitHub private vulnerability reporting feature. Do not include real personal data or credentials in public issues. Version 0.1 is the supported MVP line.

No credentials, remote model calls, telemetry, or third-party runtime packages are required. The app/CLI does not execute user text. CI has read-only repository permissions and pins actions to commits. A full-history Gitleaks scan runs on pushes and pull requests. Automated scanning is evidence, not a guarantee of security.

Kit storage uses atomic writes and complete file protection on iOS. This is platform data protection, not an independent encryption scheme. OS/device backups may contain app data. No cloud sync or analytics is implemented. A corrupt or unsupported saved file blocks mutations to avoid silent data loss. External resource links open in the browser. This checklist is not an emergency alert service, professional advice, or certification of preparedness.
