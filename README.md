# dify-azure-bicep

Deploy [langgenius/dify](https://github.com/langgenius/dify), an LLM-based chat bot application on Azure with Bicep infrastructure-as-code.

> **Note**: This repository uses Bicep to provision Dify on Azure. The upstream Dify container image tags are referenced from `docker-compose-template.yaml`.

# Agents Guide

## Purpose

This repository deploys Dify on Azure using Bicep.

The source of truth is:
1. Bicep implementation (`infra/`)
2. Design specifications (`docs/spec/`)
3. Architecture and operational documents (`docs/`)

## Change Rules

When modifying infrastructure:

1. Update the relevant specification in `docs/spec/`.
2. Update the corresponding Bicep implementation.
3. Keep parameter definitions aligned with implementation.
4. Update documentation when architecture or behavior changes.

## Navigation

For architecture:
- `docs/architecture.md`

For detailed design:
- `docs/spec/`

For testing:
- `docs/test/`

For cost estimation:
- `docs/cost/`

## Constraints

- Prefer parameter-driven configuration.
- Avoid hardcoded environment values.
- Keep security-sensitive values outside source control.
- Follow existing module boundaries unless a refactor is required.

## Definition of Done

A change is complete only when:
- Implementation is updated.
- Related specifications are updated.
- Documentation remains consistent.
- Validation procedures continue to pass.

## References

- [Dify Documentation](https://docs.dify.ai/)
- [Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure OpenAI Service](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/)



