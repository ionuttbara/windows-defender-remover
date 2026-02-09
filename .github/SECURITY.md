# Security Policy

## ⚠️ False Positives / Virus Detections

This application works by modifying system files and terminating security processes (Windows Defender). By definition, **antivirus software will flag this behavior as malicious.** The EXE file is flagged as virus. To download virus-free version, you can download the .zip source code version or clone the project with Git.

**Please DO NOT report antivirus detections as security vulnerabilities.**
These are expected behavior (False Positives).

## Reporting a Vulnerability

If you find a genuine security vulnerability (e.g., the script can be exploited to run arbitrary code remotely, or privilege escalation outside the intended scope), please report it follows:

1.  Do not open a public GitHub issue.
2.  Send an email to [ionutbaraooo@gmail.com](mailto:ionutbaraooo@gmail.com) or open a draft Security Advisory if enabled.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 12.x    | :white_check_mark: |
| 11.x    | :x:                |
| < 11.x  | :x:                |