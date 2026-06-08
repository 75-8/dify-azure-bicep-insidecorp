# AGENTS.md

## Purpose

This repository manages Infrastructure as Code (IaC) for deploying and operating a Dify platform on Azure.

## Source of Truth

* Infrastructure definitions: `main.bicep` and `modules/`
* Architecture and design decisions: `docs/`
* Deployment instructions: `README.md`

Do not duplicate information that already exists in code or other documentation.

## Change Guidelines

When making changes, prioritize the following:

1. Preserve module reusability.
2. Maintain existing security boundaries.
3. Preserve parameter compatibility whenever possible.
4. Minimize impact on production environments.

## Security Requirements

* Never hardcode secrets or credentials.
* Do not commit `infra/parameters.json`.
* Any new public endpoint must be explicitly justified.
* Any relaxation of network restrictions must be documented.

## Repository Areas

### docs/

Contains architecture specifications, design decisions, and security guidance.

### modules/

Contains reusable Azure resource definitions.

## Validation

Before submitting changes, verify:

* Bicep files compile successfully.
* Resource dependencies remain valid.
* Existing parameter compatibility is maintained.
* Security settings are not unintentionally weakened.

Refer to `README.md` or the `docs/` directory for those details.
