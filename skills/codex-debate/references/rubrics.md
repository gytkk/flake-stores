# Debate Mode Rubrics

Each mode defines the evaluation lens for both Claude (builder) and Codex (reviewer).

## architecture

| Criteria | Weight | Description |
|----------|--------|-------------|
| Modularity | High | Clear boundaries, single responsibility, composability |
| Coupling/Cohesion | High | Minimal inter-module dependencies, strong intra-module relatedness |
| Scalability | Medium | Handles 10x growth without redesign |
| Dependency Management | Medium | Pinned versions, minimal transitive deps, no circular imports |
| Migration Path | Medium | Incremental adoption possible, backward compatibility story |
| API Contract Stability | High | Public interfaces are versioned, documented, hard to misuse |
| Data Flow | Medium | Clear ownership, no implicit state sharing, traceable paths |
| Error Boundaries | Medium | Failures contained, graceful degradation, meaningful messages |
| Extensibility | Low | Open for extension without modification (but don't over-engineer) |

## security

| Criteria | Weight | Description |
|----------|--------|-------------|
| OWASP Top 10 | Critical | Injection, broken auth, sensitive data exposure, XXE, broken access control, misconfig, XSS, insecure deserialization, vulnerable components, insufficient logging |
| Authentication | Critical | Strong identity verification, session management, MFA readiness |
| Authorization | Critical | Role-based or attribute-based access, least privilege enforced |
| Input Validation | High | Allowlist over denylist, validated at trust boundaries |
| Output Encoding | High | Context-aware encoding (HTML, URL, JS, SQL) |
| Secrets Management | Critical | No hardcoded secrets, rotation strategy, encrypted at rest |
| Dependency Safety | High | Known CVE scan, provenance verification, minimal attack surface |
| Data Protection | High | Classification, encryption in transit/at rest, retention policy |
| Audit Logging | Medium | Who did what when, tamper-evident, sufficient for incident response |

## perf

| Criteria | Weight | Description |
|----------|--------|-------------|
| Algorithmic Complexity | High | O(n) or better for hot paths, justified trade-offs for worse |
| Memory Allocation | Medium | Avoid unnecessary copies, pool reusable objects, bounded growth |
| I/O Optimization | High | Batched reads/writes, async where beneficial, minimal round trips |
| Caching Strategy | Medium | Cache what's expensive, invalidate correctly, measure hit rates |
| Concurrency | High | Lock-free where possible, no deadlocks, bounded parallelism |
| Database Queries | High | No N+1, proper indexes, explain plan reviewed, connection pooling |
| Network Calls | Medium | Minimize external calls, timeout/retry with backoff, circuit breaker |
| Lazy Loading | Low | Defer expensive work until needed, but don't add complexity |
| Observability | Medium | Profiling hooks, metrics endpoints, latency percentiles tracked |

## testing

| Criteria | Weight | Description |
|----------|--------|-------------|
| Test Pyramid | High | Unit > Integration > E2E ratio, fast feedback loop |
| Edge Cases | High | Boundary values, empty/null/max inputs, error paths |
| Mock Boundaries | Medium | Mock at system boundaries only, no mocking implementation details |
| CI Integration | High | Tests run on every PR, fast enough for developer workflow |
| Flaky Prevention | Medium | Deterministic, no time-dependent, isolated test data |
| Test Data | Medium | Factory patterns, no shared mutable state between tests |
| Assertion Quality | Medium | Specific assertions, meaningful failure messages, no assert true |
| Coverage Strategy | Medium | Behavior coverage over line coverage, critical paths 100% |
| Regression | High | New bugs get a test before fix, no silent regressions |
