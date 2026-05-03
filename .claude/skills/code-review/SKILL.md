---
name: code-review
description: Perform deep critical analysis of changes with focus on performance vs sustainability trade-offs
license: MIT
---

## What I do
- Analyze proposed changes for performance impact and long-term sustainability
- Evaluate trade-offs between immediate performance gains and architectural maintainability
- Identify potential regressions, N+1 queries, and scalability concerns
- Provide actionable, balanced recommendations

## When to use me
- Before merging feature work
- Reviewing refactoring proposals
- Evaluating performance optimizations
- Assessing architectural decisions

## Review Framework

### Performance Concerns
- **N+1 queries**: Check for missing `preload`/`includes` in controller actions
  - Project uses Prosopite in non-production to detect N+1 (in ApplicationController)
  - Look for `.each` loops over collections without association loading
- **Counter cache usage**: Verify counter caches are used instead of `.count` in hot paths
- **Query complexity**: Large joins, complex SQL, raw queries
- **Background vs synchronous**: Expensive operations should use `perform_later`, not `perform_now`
- **Index usage**: New queries should have corresponding indexes
- **Memory**: Large result sets loaded into memory (pagination with Kaminari)

### Sustainability Concerns
- **STI sprawl**: Are new STI children adding meaningful behavior or duplicating logic?
- **Service object boundaries**: Is the service object too large? Does it need splitting?
- **Model bloat**: Are model methods handling concerns better placed in services?
- **Callback chains**: Are callbacks becoming hard to follow or create hidden dependencies?
- **State machine complexity**: Are state transitions adding too much indirection?
- **Test coverage**: Are new features adequately tested? Coverage gaps identified by SimpleCov?

### Trade-off Analysis

#### Performance wins vs sustainability costs
| Pattern | Performance | Sustainability | Verdict |
|---------|------------|----------------|---------|
| Raw SQL for complex queries | High | Low — hard to maintain, loses AR benefits | Avoid unless necessary |
| N+1 bypass with eager loading | Medium | High — standard AR pattern | Preferred |
| Counter cache | High | High — standard Rails pattern | Preferred |
| Instance variable caching (@var) | Medium | Low — fragile, hard to test | Use sparingly |
| Service object extraction | Medium | High — clear separation of concerns | Preferred |
| Callback-heavy models | Low | Low — hidden execution order, hard to debug | Extract to services |

### Review Checklist
- [ ] No N+1 queries (check `preload`/`includes`)
- [ ] Counter caches used where `.count` was used
- [ ] Background jobs for non-critical async work
- [ ] Strong params with `params.expect` (Rails 8)
- [ ] Model validations present, no business logic in controllers
- [ ] STI hierarchy is clean, not adding unnecessary children
- [ ] Service objects follow naming convention (PascalCase, verb-noun)
- [ ] Tests written: model, service, controller, system as appropriate
- [ ] Fixtures updated with STI type and enum values
- [ ] SimpleCov coverage doesn't drop significantly
- [ ] Rubocop passes (rubocop:autocorrect or bin/rubocop)
- [ ] Tailwind classes follow dark mode patterns
- [ ] No hardcoded URLs, uses path/url helpers
- [ ] Migration is reversible (use `change` or define `up`/`down`)

### Critical Questions
1. **Does this change make the code easier or harder to change later?**
2. **If this grows 10x, will it still work?**
3. **Is the performance gain worth the complexity added?**
4. **Are there simpler approaches that achieve the same goal?**
5. **What assumptions is this code making about data?**
6. **Can this be tested without fixtures or with minimal fixtures?**
7. **Does this follow the project's established patterns or introduce a new one?**

## Key Files
- `app/controllers/application_controller.rb` — Prosopite N+1 detection
- `test/test_helper.rb` — SimpleCov parallel worker setup
- `.rubocop.yml` — Style rules that enforce consistency
