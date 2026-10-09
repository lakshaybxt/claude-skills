# Code Review Checklist

Use the sections that match the language and change. Not every item applies to every review.

## 1. Correctness

- Does the code do what the change description says?
- Off-by-one errors, wrong comparison operators, inverted conditions
- Null / undefined / empty handling (collections, strings, Optional, API responses)
- Edge cases: empty input, single element, very large input, duplicates, negative numbers
- Concurrency: shared mutable state, race conditions, missing synchronization, non-atomic check-then-act
- Resource leaks: unclosed streams, connections, file handles, subscriptions, timers
- Time and money: timezone handling, rounding, floating point used for currency (use BigDecimal / integer cents)
- Does a change in one place break callers, subclasses, or serialized formats elsewhere?

## 2. Security

- Input validation on every external boundary (request body, query params, headers, files)
- SQL / JPQL / NoSQL injection: string concatenation in queries instead of bound parameters
- Authentication and authorization: is every endpoint protected, and does it check that the caller owns the resource (not just that they are logged in)?
- Secrets: hardcoded keys, tokens, passwords, connection strings committed to source
- Sensitive data in logs, error messages, or API responses (passwords, tokens, PII)
- XSS: unescaped user content rendered as HTML; `dangerouslySetInnerHTML` in React
- CSRF and CORS: overly permissive origins, state-changing GET requests
- Unsafe deserialization, path traversal in file handling, SSRF in server-side URL fetching
- Dependencies: new packages that are unmaintained, unnecessary, or have known vulnerabilities
- Mass assignment: binding request bodies directly to entities

## 3. Error handling

- Exceptions swallowed silently (empty catch blocks)
- Catching overly broad types (`Exception`, `Throwable`) without reason
- Errors that lose the original cause (rethrow without chaining)
- Clear, consistent error responses for API clients; correct HTTP status codes
- Retries and timeouts on network calls; behavior when a dependency is down
- Failing fast on invalid state instead of continuing with bad data

## 4. Performance

- N+1 queries (loops that call the database or an API per item)
- Missing database indexes for new query patterns; unbounded queries without pagination or limits
- Loading entire tables or large files into memory
- Repeated work inside loops that could be hoisted out or cached
- Blocking calls on a thread that should not block (reactive code, UI thread, event loop)
- Unnecessary re-renders in React (new object/function props every render, missing keys, expensive work not memoized)
- Chatty network usage: many small requests that could be batched

## 5. Tests

- Is new behavior covered, including at least one failure path?
- Do tests assert outcomes, or only that code runs without throwing?
- Are tests deterministic (no real time, randomness, network, or ordering dependence)?
- Mocks used sensibly: mocking the thing under test, or mocking so much that nothing real is verified
- Does a bug fix include a test that fails without the fix?
- Test names that say what is being verified

## 6. Design and maintainability

- Single responsibility: functions and classes that do one thing
- Duplicated logic that should be shared, or abstraction added with only one use
- Naming that reveals intent; no misleading names
- Function length and nesting depth; deeply nested conditionals that could return early
- Magic numbers and strings without names
- Public API surface: is more exposed than necessary?
- Dead code, commented-out code, leftover debug output, stray TODOs
- Comments that explain why, not what; comments that no longer match the code
- Consistency with the rest of the codebase

## 7. Language-specific notes

### Java / Spring Boot

- Constructor injection over field injection (`@Autowired` on fields)
- Controllers stay thin; business logic lives in services
- Do not expose JPA entities directly in API responses; use DTOs
- `@Transactional` on the right layer; no self-invocation that bypasses the proxy; read-only where applicable
- Lazy loading outside a transaction (`LazyInitializationException`); `FetchType.EAGER` used by default
- Bean Validation (`@Valid`, `@NotNull`, etc.) on request DTOs
- `Optional` used as a return type, not as a field or parameter; no `Optional.get()` without a check
- Centralized exception handling with `@ControllerAdvice`
- Configuration via properties/environment, not hardcoded values
- Mockito: verify behavior that matters, avoid over-stubbing, prefer real objects for simple value types

### GraphQL

- N+1 resolvers (use batching / data loaders)
- Query depth and complexity limits; authorization in resolvers, not only at the edge
- Nullability of schema fields matches reality

### Kafka / messaging

- Idempotent consumers; handling of duplicate and out-of-order messages
- Offset commit strategy matches the processing guarantee needed
- Dead-letter handling for poison messages
- Serialization format changes that break existing consumers

### React / JavaScript / TypeScript

- Hook rules: dependencies in `useEffect` / `useMemo` / `useCallback` complete and correct; cleanup functions for subscriptions and timers
- State derived from props or other state stored redundantly
- Stable `key` props in lists (not array index for dynamic lists)
- Missing loading and error states for async data
- `async` functions whose rejections are unhandled
- Loose equality, implicit coercion, `any` in TypeScript without justification
- Accessibility: labels, alt text, keyboard support, semantic elements

### SQL / database migrations

- Migration is reversible or has a clear rollback plan
- Locking behavior on large tables; backfills done in batches
- Constraints, foreign keys, and indexes present
- No destructive change without a confirmed data migration

## 8. Final pass

- Would you be comfortable getting paged for this code at 3 AM?
- Is the change small and focused, or should it be split?
- Is anything surprising that a future reader would need explained?
