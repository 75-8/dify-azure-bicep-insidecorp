# Phase 5: Verify

Verify the plan before generating IaC.

- Validate schema completeness.
- Run WAF checks from [waf-checklist.md](../waf-checklist.md).
- Run pairing checks from [pairing-checks.md](../pairing-checks.md).
- Confirm all destructive, public exposure, and cost-incurring decisions are explicit.
- Stop if verification fails or `meta.status` is not `approved`.
