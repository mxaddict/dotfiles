# Plan

What we intend to build, in order. Work raised and not planned lives in
[`docs/backlog.md`](../backlog.md).

1. Modernize and clean up: drop stow, fix the docs that called krypt's copies
   symlinks, lint Lua with stylua and the workflows with actionlint, parse TOML
   with `tomllib`. **Done** (2026-11-10).
2. [CI coverage](02-ci-coverage.md): check that the deployed configs load in the
   tools that read them, not only that they parse. **Not started.**
