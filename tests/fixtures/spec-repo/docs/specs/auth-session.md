---
kind: spec
status: living
updated: 2026-09-05
---
# Capability: auth-session

## Purpose
Session issuance, refresh, and expiry for authenticated users.

## Invariants
- INV-1: Tokens are never written to logs.
- INV-2: Every session is revocable server-side.

## Requirements
### R-AUTH-001: Token issuance
WHEN a user submits valid credentials, the system SHALL issue a signed session token with a 15-minute lifetime.
#### Scenario: valid-login -> test_login_issues_token
- GIVEN a registered user
- WHEN they submit valid credentials
- THEN a signed session token is returned
- AND the token expiry is 15 minutes from issuance

### R-AUTH-003: Idle expiry
WHEN a session is idle for 15 minutes, the system SHALL invalidate it.
#### Scenario: idle-timeout -> test_session_idle_timeout
- GIVEN an authenticated session
- WHEN 15 minutes pass without activity
- THEN the session is invalidated

### R-AUTH-004: Failed validation
IF token validation fails, THEN the system SHALL return HTTP 401 within 200 ms.
#### Scenario: bad-token -> test_invalid_token_401
- GIVEN a request with a tampered token
- WHEN the request reaches any authenticated route
- THEN the response is HTTP 401

## Non-goals
- N-1: SSO federation is owned by capability sso.

## Change log
- 2026-08-28 R-AUTH-003: production config sets a 30-minute idle timeout -> open
- 2026-09-05 N-1: sso capability confirmed as owner; non-goal stands as written -> kept
