---
kind: spec
status: living
updated: 2026-09-05
---
# Capability: demo

## Purpose
Demonstrates minimal valid spec structure for isolated lint fixtures.

## Invariants
- INV-1: The system supports concurrent sessions for one user.

## Requirements
### R-DEMO-001: Example behavior
WHEN a user performs the action, the system SHALL record the result within 1 second.
#### Scenario: basic -> test_example_basic
- GIVEN a ready system
- WHEN the user performs the action
- THEN the result is recorded
