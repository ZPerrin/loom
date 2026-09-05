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
WHEN a user performs the action, the system SHALL record the result within 1 second.
#### Scenario: basic -> test_example_basic
- GIVEN a ready system
- WHEN the user performs the action
- THEN the result is recorded

### R-OTHER-001: Second behavior
WHEN a user cancels the action, the system SHALL discard the pending result immediately.
#### Scenario: cancel -> test_example_cancel
- GIVEN a pending action
- WHEN the user cancels it
- THEN the pending result is discarded
