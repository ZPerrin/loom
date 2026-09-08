---
kind: spec
status: living
updated: 2026-09-05
---
# Capability: demo

## Purpose
Demonstrates minimal valid spec structure for isolated lint fixtures.

## Requirements
### R-DEMO-001: Example behavior
WHEN a user submits a password reset request from the account settings page after three failed sign-in attempts in a row, the system SHALL generate a single-use reset link bound to that account within one minute.
#### Scenario: basic -> test_example_basic
- GIVEN a ready system
- WHEN the user performs the action
- THEN the result is recorded
