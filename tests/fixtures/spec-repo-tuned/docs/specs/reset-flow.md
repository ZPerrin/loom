---
kind: spec
status: living
updated: 2026-09-05
---
# Capability: reset-flow

## Purpose
Password reset link issuance for account recovery.

## Requirements
### R-RESET-001: Reset link issuance
WHEN a user requests a password reset from the account settings page, the system SHALL send a single-use reset link within one minute.
#### Scenario: basic -> test_reset_link_sent
- GIVEN a registered user
- WHEN they request a password reset
- THEN a single-use reset link is sent within one minute
