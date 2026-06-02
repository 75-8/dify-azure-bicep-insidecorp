# Repository Directory Structure

このファイルは、リポジトリ配下の主要ファイル/ディレクトリ構成を一覧化したものです。

```text
/dify-azure-bicep-insidecorp
|--.agents
|  |--skills
|  |  |--azure-enterprise-infra-planner
|  |  |  |--SKILL.md
|  |  |  |--references
|  |  |  |  |--bicep-generation.md
|  |  |  |  |--constraints
|  |  |  |  |  |--README.md
|  |  |  |  |  |--ai-ml.md
|  |  |  |  |  |--compute-apps.md
|  |  |  |  |  |--compute-infra.md
|  |  |  |  |  |--data-analytics.md
|  |  |  |  |  |--data-relational.md
|  |  |  |  |  |--messaging.md
|  |  |  |  |  |--monitoring.md
|  |  |  |  |  |--networking-connectivity.md
|  |  |  |  |  |--networking-core.md
|  |  |  |  |  |--networking-traffic.md
|  |  |  |  |  |--security.md
|  |  |  |  |--deployment.md
|  |  |  |  |--pairing-checks.md
|  |  |  |  |--phases
|  |  |  |  |  |--1-extract-insights.md
|  |  |  |  |  |--2-research-best-practices.md
|  |  |  |  |  |--3-research-resources.md
|  |  |  |  |  |--4-generate-plan.md
|  |  |  |  |  |--5-verify.md
|  |  |  |  |  |--6-generate-iac.md
|  |  |  |  |  |--7-deploy.md
|  |  |  |  |--resources
|  |  |  |  |  |--README.md
|  |  |  |  |  |--ai-ml.md
|  |  |  |  |  |--compute-apps.md
|  |  |  |  |  |--compute-infra.md
|  |  |  |  |  |--data-analytics.md
|  |  |  |  |  |--data-relational.md
|  |  |  |  |  |--messaging.md
|  |  |  |  |  |--monitoring.md
|  |  |  |  |  |--networking-connectivity.md
|  |  |  |  |  |--networking-core.md
|  |  |  |  |  |--networking-traffic.md
|  |  |  |  |  |--security.md
|  |  |  |  |--schema.md
|  |  |  |  |--terraform-generation.md
|  |  |  |  |--verification.md
|  |  |  |  |--waf-checklist.md
|  |  |  |  |--workflow.md
|  |  |--azure-hosted-copilot-sdk
|  |  |  |--SKILL.md
|  |  |  |--references
|  |  |  |  |--auth-best-practices.md
|  |  |  |  |--azure-model-config.md
|  |  |  |  |--copilot-sdk.md
|  |  |  |  |--deploy-existing.md
|  |  |  |  |--existing-project-integration.md
|  |  |--azure-prepare
|  |  |  |--SKILL.md
|  |  |  |--references
|  |  |  |  |--analyze.md
|  |  |  |  |--apim.md
|  |  |  |  |--architecture.md
|  |  |  |  |--aspire.md
|  |  |  |  |--auth-best-practices.md
|  |  |  |  |--azure-context.md
|  |  |  |  |--functional-verification.md
|  |  |  |  |--generate.md
|  |  |  |  |--global-rules.md
|  |  |  |  |--plan-template.md
|  |  |  |  |--recipe-selection.md
|  |  |  |  |--recipes
|  |  |  |  |  |--azcli
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--commands.md
|  |  |  |  |  |  |--scripts.md
|  |  |  |  |  |--azd
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--aspire.md
|  |  |  |  |  |  |--azure-yaml.md
|  |  |  |  |  |  |--docker.md
|  |  |  |  |  |  |--iac-rules.md
|  |  |  |  |  |  |--terraform.md
|  |  |  |  |  |--bicep
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--patterns.md
|  |  |  |  |  |--terraform
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--patterns.md
|  |  |  |  |--region-availability.md
|  |  |  |  |--requirements.md
|  |  |  |  |--research.md
|  |  |  |  |--resources-limits-quotas.md
|  |  |  |  |--runtimes
|  |  |  |  |  |--nodejs.md
|  |  |  |  |--scan.md
|  |  |  |  |--sdk
|  |  |  |  |  |--azd-deployment.md
|  |  |  |  |  |--azure-appconfiguration-java.md
|  |  |  |  |  |--azure-appconfiguration-py.md
|  |  |  |  |  |--azure-appconfiguration-ts.md
|  |  |  |  |  |--azure-identity-dotnet.md
|  |  |  |  |  |--azure-identity-java.md
|  |  |  |  |  |--azure-identity-py.md
|  |  |  |  |  |--azure-identity-ts.md
|  |  |  |  |--security.md
|  |  |  |  |--services
|  |  |  |  |  |--aks
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--addons.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |  |  |--manifests.md
|  |  |  |  |  |--app-insights
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |--app-service
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |  |  |--custom-domains.md
|  |  |  |  |  |  |--deployment-slots.md
|  |  |  |  |  |  |--networking.md
|  |  |  |  |  |  |--scaling.md
|  |  |  |  |  |  |--sku-selection.md
|  |  |  |  |  |  |--templates
|  |  |  |  |  |  |  |--recipes
|  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |--auth
|  |  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |  |--source
|  |  |  |  |  |  |  |  |  |  |--dotnet.md
|  |  |  |  |  |  |  |  |  |  |--nodejs.md
|  |  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |  |--composition.md
|  |  |  |  |  |  |  |  |--cosmos
|  |  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |  |--source
|  |  |  |  |  |  |  |  |  |  |--dotnet.md
|  |  |  |  |  |  |  |  |  |  |--nodejs.md
|  |  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |  |--redis
|  |  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |  |--source
|  |  |  |  |  |  |  |  |  |  |--dotnet.md
|  |  |  |  |  |  |  |  |  |  |--nodejs.md
|  |  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |  |--sql
|  |  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |  |--source
|  |  |  |  |  |  |  |  |  |  |--dotnet.md
|  |  |  |  |  |  |  |  |  |  |--nodejs.md
|  |  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |--selection.md
|  |  |  |  |  |  |  |--web-api.md
|  |  |  |  |  |  |  |--web-app.md
|  |  |  |  |  |--container-apps
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |  |  |--day2-operations.md
|  |  |  |  |  |  |--environment.md
|  |  |  |  |  |  |--health-probes.md
|  |  |  |  |  |  |--networking.md
|  |  |  |  |  |  |--revisions.md
|  |  |  |  |  |  |--scaling.md
|  |  |  |  |  |  |--terraform.md
|  |  |  |  |  |--cosmos-db
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |  |  |--partitioning.md
|  |  |  |  |  |  |--sdk.md
|  |  |  |  |  |--durable-task-scheduler
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |  |  |--dotnet.md
|  |  |  |  |  |  |--java.md
|  |  |  |  |  |  |--javascript.md
|  |  |  |  |  |  |--python.md
|  |  |  |  |  |--event-grid
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |  |  |--subscriptions.md
|  |  |  |  |  |--foundry
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--region-availability.md
|  |  |  |  |  |--functions
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--aspire-containerapps.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |  |  |--durable.md
|  |  |  |  |  |  |--templates
|  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |--base
|  |  |  |  |  |  |  |  |--eval
|  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |  |  |--summary.md
|  |  |  |  |  |  |  |  |  |--typescript.md
|  |  |  |  |  |  |  |--recipes
|  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |--blob-eventgrid
|  |  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |  |--eval
|  |  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |  |  |  |--summary.md
|  |  |  |  |  |  |  |  |--common
|  |  |  |  |  |  |  |  |  |--dotnet-entry-point.md
|  |  |  |  |  |  |  |  |  |--error-handling.md
|  |  |  |  |  |  |  |  |  |--health-check.md
|  |  |  |  |  |  |  |  |  |--nodejs-entry-point.md
|  |  |  |  |  |  |  |  |--composition.md
|  |  |  |  |  |  |  |  |--cosmosdb
|  |  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |  |--eval
|  |  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |  |  |  |--summary.md
|  |  |  |  |  |  |  |  |  |  |--typescript.md
|  |  |  |  |  |  |  |  |--durable
|  |  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |  |--eval
|  |  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |  |  |  |--summary.md
|  |  |  |  |  |  |  |  |--eventhubs
|  |  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |  |--eval
|  |  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |  |  |  |--summary.md
|  |  |  |  |  |  |  |  |--mcp
|  |  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |  |--eval
|  |  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |  |  |  |--summary.md
|  |  |  |  |  |  |  |  |--servicebus
|  |  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |  |--eval
|  |  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |  |  |  |--summary.md
|  |  |  |  |  |  |  |  |  |  |--typescript.md
|  |  |  |  |  |  |  |  |--sql
|  |  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |  |--eval
|  |  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |  |  |  |--summary.md
|  |  |  |  |  |  |  |  |--timer
|  |  |  |  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |  |  |  |--eval
|  |  |  |  |  |  |  |  |  |  |--python.md
|  |  |  |  |  |  |  |  |  |  |--summary.md
|  |  |  |  |  |  |  |--selection.md
|  |  |  |  |  |  |--terraform.md
|  |  |  |  |  |--key-vault
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |  |  |--sdk.md
|  |  |  |  |  |--logic-apps
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |  |  |--triggers.md
|  |  |  |  |  |--service-bus
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |  |  |--patterns.md
|  |  |  |  |  |--sql-database
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--auth.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |  |  |--scripts
|  |  |  |  |  |  |  |--grant-sql-access.ps1
|  |  |  |  |  |  |  |--grant-sql-access.sh
|  |  |  |  |  |  |--sdk.md
|  |  |  |  |  |--static-web-apps
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |  |  |--deployment.md
|  |  |  |  |  |  |--region-availability.md
|  |  |  |  |  |  |--routing.md
|  |  |  |  |  |  |--terraform.md
|  |  |  |  |  |--storage
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--access.md
|  |  |  |  |  |  |--bicep.md
|  |  |  |  |--specialized-routing.md
|  |  |--azure-validate
|  |  |  |--SKILL.md
|  |  |  |--references
|  |  |  |  |--aspire-functions-secrets.md
|  |  |  |  |--global-rules.md
|  |  |  |  |--policy-validation.md
|  |  |  |  |--recipes
|  |  |  |  |  |--README.md
|  |  |  |  |  |--azcli
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--errors.md
|  |  |  |  |  |--azd
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--aspire.md
|  |  |  |  |  |  |--environment.md
|  |  |  |  |  |  |--errors.md
|  |  |  |  |  |--bicep
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--errors.md
|  |  |  |  |  |--terraform
|  |  |  |  |  |  |--README.md
|  |  |  |  |  |  |--errors.md
|  |  |  |  |--region-availability.md
|  |  |  |  |--role-verification.md
|--.azure
|  |--deployment-plan.md
|--.git
|  |--COMMIT_EDITMSG
|  |--FETCH_HEAD
|  |--HEAD
|  |--ORIG_HEAD
|  |--branches
|  |--config
|  |--description
|  |--hooks
|  |  |--applypatch-msg.sample
|  |  |--commit-msg.sample
|  |  |--fsmonitor-watchman.sample
|  |  |--post-update.sample
|  |  |--pre-applypatch.sample
|  |  |--pre-commit.sample
|  |  |--pre-merge-commit.sample
|  |  |--pre-push.sample
|  |  |--pre-rebase.sample
|  |  |--pre-receive.sample
|  |  |--prepare-commit-msg.sample
|  |  |--push-to-checkout.sample
|  |  |--sendemail-validate.sample
|  |  |--update.sample
|  |--index
|  |--info
|  |  |--exclude
|  |--logs
|  |  |--HEAD
|  |  |--refs
|  |  |  |--heads
|  |  |  |  |--main
|  |  |  |--remotes
|  |  |  |  |--origin
|  |  |  |  |  |--HEAD
|  |  |  |  |  |--main
|  |--objects
|  |  |--00
|  |  |  |--8eb1993c7d0b101b20e21db85c349663ef0842
|  |  |--01
|  |  |  |--643554a096bab1bfc9cee7bf5ef5eb8cd2ea68
|  |  |  |--a704ab4b82e0d119d2bd7a173af9e320c822a2
|  |  |  |--aeec9d7f0894c4a38df68e77c96835c87ea1f2
|  |  |--03
|  |  |  |--7beaed31b8018673df27feb393ccc25a8f7e90
|  |  |--04
|  |  |  |--13b82619b945812aba874a6910d5ffacbb26e4
|  |  |  |--36d825cc1ef10756761f59ba86e1d8a068e78c
|  |  |  |--b9bb9fd64c52660c34986dd653682e974eec7c
|  |  |--05
|  |  |  |--320c8d3796d3561b980a2e507e26c2ff48329a
|  |  |--07
|  |  |  |--a396f40696f8b2f7206f947d1c68a3c0e7c994
|  |  |--08
|  |  |  |--6f74e7b1e52e25e8e237644fc72b298aa89e71
|  |  |  |--b35dd79a8ee65b02ddef91a421b2122aa657bf
|  |  |  |--e776a98bb8163d5773c5731eada897641560b1
|  |  |--09
|  |  |  |--975dc33389bb82bc5e7a74da1ca0d35a589b28
|  |  |--0a
|  |  |  |--9e3f20deda10590d9633624d33ed9364e3a304
|  |  |--0b
|  |  |  |--0e730ba298ca9cd07d3918769df03a25d523cc
|  |  |  |--28c326b717dfde1b85162e28ad11dd436402ba
|  |  |  |--d3b48c11ab74553d8489cd2ac5dbaddf4a13eb
|  |  |--0c
|  |  |  |--4178a52002d25cbf449e426b6d3f8dae90ec8f
|  |  |  |--4364e19f48b96e0ce6c557d85a2ab43a64431a
|  |  |--0e
|  |  |  |--61cc71e17f2e1ec5df62820b23389ff45c36ef
|  |  |--0f
|  |  |  |--6c6dd4b31d4047346fac01bbe8c96a42fa124e
|  |  |  |--c635a0b7f338861b02d4924a96dd42d524dc8f
|  |  |--10
|  |  |  |--c6d311477ba0dd61bec9f17e24a76c3223c749
|  |  |--11
|  |  |  |--fc4f6ada90ece03abe977532c28c89cf886c3d
|  |  |--13
|  |  |  |--7444da0ff6ba1c988a1d64fdf834f8fd173efe
|  |  |--16
|  |  |  |--96eb04016296b1405994002a6e22224f9c33a3
|  |  |--17
|  |  |  |--1153d7338bd0e4b4fead12152da054974ff6d0
|  |  |  |--5ed45e75d8df4e2cb4de7f72f2051cc4ddb33f
|  |  |  |--a0ce4435ce130daf4bd06ead22259f06dbb023
|  |  |  |--e34161981c0e642a803f77685c78c2b729e0e9
|  |  |--18
|  |  |  |--2b54b64a22343874348cf7710f9084a31c8618
|  |  |  |--2ec3f48e1e3d66ab0656a4977d49887f17cb19
|  |  |--19
|  |  |  |--5a29fe37024a1cca28cddd329427c61d90a62c
|  |  |  |--bfb3d1c275d844b1604212f6e3aecfa735c679
|  |  |--1e
|  |  |  |--6e175276590d0f392c8a7c83aa8c286229e101
|  |  |  |--ee2553d05df6d1458b59002ffcebb38a189ba5
|  |  |--1f
|  |  |  |--def1b0659e829831b2c233179072a362d95183
|  |  |--20
|  |  |  |--40ef3eaec636ebd4bf281360b33db3d3722335
|  |  |--21
|  |  |  |--42645035ec13220a2a9ec4a36e8bd03f7642f7
|  |  |  |--68591a5bd9c92fe6f734c730982c04ed7fe5f2
|  |  |  |--791ac2d151db61e380f7401ac6fb3841e61daa
|  |  |  |--b303b9085a0cb4123cf88ecdb18e1bb046debe
|  |  |  |--d556e62f0accf06c42abe01eaa738dc8a183e4
|  |  |--23
|  |  |  |--6e61787ffad825afebe1abb5a5f115b8071096
|  |  |--25
|  |  |  |--4d5f36feaf365cbc5f3cd888541c1b80ae3a04
|  |  |  |--6787dd8e6cb789f5338508d50ab00befb1a095
|  |  |--27
|  |  |  |--00db246770ee5cb9974a3dc8afac5b616c8e78
|  |  |--28
|  |  |  |--38dbc68169a55ad46db22db9ca5353349096a6
|  |  |  |--56da6742fc731d9127e2447d2198b742a2d739
|  |  |  |--6dc495710d522be8ed35ba3a90a94a3cb97749
|  |  |--29
|  |  |  |--595f8ada5428c4d98f568300269320d07ff3a4
|  |  |--2a
|  |  |  |--208ce7abddbfc9e2d4d7da6b5e23483fdc25d9
|  |  |--2d
|  |  |  |--137f7b37170ca353d7a09cc91d2aa0bec688ca
|  |  |--2e
|  |  |  |--bbf90f724e88d36474da9634731c4401e8ef47
|  |  |--2f
|  |  |  |--2ddb7913c29998fe758591ef570526b5104c14
|  |  |  |--71446e26230d53cc9c11634cf2c9c760fb4790
|  |  |  |--cb30628a838dd08f5da9908cf9c94152d12f8f
|  |  |--30
|  |  |  |--0775fd3cac128eb9e38fa551ef446c38963cc6
|  |  |--31
|  |  |  |--ded7686ad53789a61b470295896da26258f037
|  |  |--32
|  |  |  |--f5e9364034880b5b4ac45085a582c685142865
|  |  |--33
|  |  |  |--fb62fd8e6bc076937fec57f8de2b7d43419f0a
|  |  |--34
|  |  |  |--20e65dd04777fdb6dca23c04e9fd5f5ced8b84
|  |  |  |--9ea5cf9d6b7118adad857922089da2d8bdd399
|  |  |  |--c593bc160fc5fbfcc9a548b04f88efda118064
|  |  |--35
|  |  |  |--e3ae8e8caeec1957788bd91fdf6d1c4d6d9bd1
|  |  |  |--e98faa0d5b559225fe1544486749c4c90df2ed
|  |  |--36
|  |  |  |--33f81dd55de041baae158ffcae281597caed27
|  |  |  |--b20dd9dac43f2bad0c48935cfeab6b6edca27e
|  |  |--37
|  |  |  |--0768d04d82ae0dead26f345ea921774afb1482
|  |  |  |--89938ed1e8c0d80e67a05cddf45d072e3f58d8
|  |  |  |--cfc5eb72f8a685b56b2d79300227e7dca02f22
|  |  |  |--fa5bec29c615cb264aa81349372b9f8df69442
|  |  |--38
|  |  |  |--5ad3e925a8ffd981d7b8cf563b5f486905ac90
|  |  |  |--60c7dddf1bbd8f092ae2784290cb4891d40c9c
|  |  |  |--6aaa78b5fb76207352476ebbc71f9720a72eda
|  |  |  |--f1906d567a419b00cc8152e7f7aa48867dfd03
|  |  |--39
|  |  |  |--1cd9394c374bba809c8be2c82942d388b1dcda
|  |  |  |--2af5ccf003271ebd76b8a1164d3c967383a4f1
|  |  |  |--999a6899d98b1ae7a1779cfce2124b90184063
|  |  |  |--b339e567924948ef5bc2dcc7b8442da883e482
|  |  |--3a
|  |  |  |--133248a63e503258d35221d747c856fdc9d8a0
|  |  |--3c
|  |  |  |--40cef49f0c26bd9c97d7aabe379119083961de
|  |  |--3d
|  |  |  |--b966063e77171b3a7c49d5078b41578fff24a3
|  |  |--3e
|  |  |  |--ef3daa1059053009317b039463ec80802355ca
|  |  |--40
|  |  |  |--732a79c753ec4dc63095ca61bf6a3316d226c9
|  |  |  |--803029ecddfcffec80d05f539ef355878e3f17
|  |  |--41
|  |  |  |--551ecbcfd1f921a0d8510df2e094162e7a6f3d
|  |  |--42
|  |  |  |--05f79db94db26839fa712f7daa71a82a311403
|  |  |--43
|  |  |  |--7b128fb24e4b517e720fa47debaec3075ba5d5
|  |  |  |--854788cbc68ad568940e31636cbf8e7287558c
|  |  |  |--f5f4f58e65d20a4c8e584bf30931213a057404
|  |  |--44
|  |  |  |--2e55683496b5658f168ef1baf2dcf61828e297
|  |  |  |--456c4439614ff645e79b8de840e2ded93126ef
|  |  |  |--a4e9cb835201cafc87f88e581de3db84aaeb04
|  |  |--45
|  |  |  |--0572c01da27c30975b307b6acb1d4feef80f0b
|  |  |--46
|  |  |  |--01f11a67d999b7b3b3ec5235b395867e120a9a
|  |  |--47
|  |  |  |--5c8fcd1d0aaf3f92a62eaf9ec9e24519789a2f
|  |  |--48
|  |  |  |--41b7e5265dce22a1722d42de6e13d8a21fe784
|  |  |--49
|  |  |  |--99981166bfc0c58a4dcefbfa916303e5cb45ca
|  |  |--4a
|  |  |  |--3afd5049756e2198e87cb367f0d6db0c356f41
|  |  |  |--69a52157b04795a6e36928fce99c4ee172e9f5
|  |  |  |--c03523b269aa3a55ac6cb14169eb9c7ae0b6fe
|  |  |--4c
|  |  |  |--8aead44252aaed57af9240ada6d5bd091e206a
|  |  |  |--e274b39d9ab4e34a4da3507c68eae8b5b07687
|  |  |--4d
|  |  |  |--4b728f7eaae753149204c58a6680e47ea0f195
|  |  |  |--ee2b2ea34b4402aa8acbad523bedc092c0e2a3
|  |  |--4e
|  |  |  |--39e95699aa1de762b399b6b686b84052187f89
|  |  |  |--55817937af64b6d3a0803dff02559d76c6f70e
|  |  |  |--c773a35e3ff76d03c7ff673d4c45d9e6e0cf91
|  |  |--4f
|  |  |  |--057f5a63b297cc3a47dc9fb0a050771ea618f4
|  |  |  |--fc7d9935929c1c249370e8b496a4117cce3431
|  |  |--50
|  |  |  |--5824b90399eb457d731ecb987a64b7d787901e
|  |  |--53
|  |  |  |--72c6be15262aeeb020218934a983e8a140452a
|  |  |  |--c32f27683b38e646aec35c73558b6e90023864
|  |  |  |--e7114100ae591265261724457ec7348633ea90
|  |  |  |--f644f4c89584ca95a881a98f7dcbe60bc5c380
|  |  |--55
|  |  |  |--0e069ebf50b60d10d3478ce56a34f8f25d27c3
|  |  |  |--7c910973152084ef98c009478098169e9e2213
|  |  |--59
|  |  |  |--5c6d90927e92f82a0a394b78a69a61d2c8bfa5
|  |  |  |--695f46945649203cc21faa61c06dec500f4aa4
|  |  |--5a
|  |  |  |--0b5bd25f0381b51380e94b454cf4e66bfb42bd
|  |  |--5b
|  |  |  |--ef774810598fcee07231a7169da7b264c83ab9
|  |  |--5d
|  |  |  |--4ad9d668e1e639827f68a910127fb890d8a254
|  |  |  |--91b32a914fb161a4795c22b98a36bedecbc860
|  |  |--5e
|  |  |  |--1872bcda973ee235a4dc54ec37711f4372640e
|  |  |  |--829b9f3d41f344e712f7ae582b371c5b805253
|  |  |  |--a18599f39ac65e4d6926a6f20924dd86dc40c7
|  |  |--5f
|  |  |  |--39e69fa173d4504fece039c3510bc168b1262e
|  |  |--61
|  |  |  |--ff2a0295a290c5d10366157b296730789e3fb7
|  |  |--62
|  |  |  |--2ee638312fa2ab74e1ec0ea20118273b2226f0
|  |  |--64
|  |  |  |--0d082e2ba82d50088faefe9c3363502817ee28
|  |  |  |--4552994ec00a16f979c57b52ceb527f35ebc05
|  |  |  |--a14ab6d666a6431c89802ed10d5decb42cb7fb
|  |  |  |--abb03e2b512a844bd91859cd8c54ee890e8750
|  |  |  |--b239df00aa320b64a9009c1875b303a87080b1
|  |  |--67
|  |  |  |--6da92d08a16bff240f7dbdb2585a927edab6e6
|  |  |--68
|  |  |  |--1ff1d928bf491b59539bc8dbe04269b3c1a41f
|  |  |  |--22d537949612984edbe52724d9d01c52865fdb
|  |  |--69
|  |  |  |--38d5f0eb32c0e5726222336cdc9365eceae865
|  |  |  |--dee56e92eed70461b891a4ad674de5cff42eb7
|  |  |--6a
|  |  |  |--11e1b8d19d6383b51a31020434b68007b6707b
|  |  |--6b
|  |  |  |--5b0f3adf42031dfdbc07255abe71db70110e8e
|  |  |--6c
|  |  |  |--46f083e06c862002f10718a3d570a19c3067c4
|  |  |--6e
|  |  |  |--091d77c931ecfbcaa7e982af129fe92cf0ac16
|  |  |  |--5109fcbd675d1e94bf3a14e54c29f184b1e1cc
|  |  |  |--9a0957602dd46bc0109a61b1ac08d5c54661ee
|  |  |--70
|  |  |  |--83cb01460ddb6ea2d139e165557b3171d39682
|  |  |  |--9e3690ba9e3d6a0d7ed2fb70937613f889d06b
|  |  |  |--c7dea5a13505c3bb0a7bb83a8118df720e7858
|  |  |--71
|  |  |  |--819911d81527a909a6216a1a47adbae6f47811
|  |  |--72
|  |  |  |--3cae86a9b3dbc439f19aaf5c4c027c16abaa4a
|  |  |  |--efea3549d2dbd301cbf9f4669ffeea1ec63cad
|  |  |  |--f08b8968e09c371db941cfabb96a2268d662e0
|  |  |--73
|  |  |  |--cc1e38563767e1e92efb4fe4129a9122c45176
|  |  |--74
|  |  |  |--79b63178137ad79e96d2b177df880b0fec9f37
|  |  |  |--c04d45b1c89b5e5f9cbb5f3925041cf117906c
|  |  |  |--c09cef4bade86e5e49a63791c032e0b63482f4
|  |  |  |--c32b21fd6b174a3e22a242578d1948ea36b9e0
|  |  |  |--e2edb72b56d5a8969f76c6101b1864a9458dce
|  |  |  |--fbb558af2ad4b7e42dba6f37357a0881847e0b
|  |  |--75
|  |  |  |--2e9ff4bab1ca025bd85a130a7d7e525fabbd35
|  |  |--76
|  |  |  |--162b6f838276c6f8bbd3799561a29b32a8b3d3
|  |  |--77
|  |  |  |--3c7d794628fee77fdb307477a5659310326be8
|  |  |--78
|  |  |  |--a91edce1cf367434e9277d12899e6a08edbd0c
|  |  |  |--da763aca61d58b6f401b92c2efdbfe609d2288
|  |  |--79
|  |  |  |--d5059aef5ad7a33e3414e8e3483e4709dcc3ca
|  |  |--7c
|  |  |  |--b2640d7ac8f18b82e72cfe015628f43903bc23
|  |  |--7e
|  |  |  |--dd0c9a5078212a7b3a509c666e256b6517f158
|  |  |--7f
|  |  |  |--12782b3a5d4b9c5d53160a7bcb3af0b17fa300
|  |  |  |--57e70f8bf1d97faa4373c740f6f910dc264066
|  |  |--82
|  |  |  |--174d89190bb013f6eca4c0bb7179fb3fa27ecb
|  |  |--83
|  |  |  |--99a9f0b5a3b92d072f331733342f3c87e8a594
|  |  |  |--c2af381bf2cc0614cc6f62983caa15d3b69fc7
|  |  |--88
|  |  |  |--3935a6bf765a81fe46f83be0bcd3f822e7aaf5
|  |  |  |--65c83d3e9e873a34aa03fa2193e01ece50c323
|  |  |  |--765d1e136f8ded75ae3ddfaf8ae36adea67104
|  |  |--8b
|  |  |  |--5d100edef015b5a2190e042addc7858b624171
|  |  |--8c
|  |  |  |--09435b2992b6f204029f487423d06263cafdad
|  |  |--8d
|  |  |  |--20a5437316311849cd6bcf141f34efa311c908
|  |  |  |--a5d7ad95951c4a97426a30106dd417cb45b560
|  |  |--8e
|  |  |  |--e247fc3269fdd5a43c7acd528a33eed48ff7e5
|  |  |--8f
|  |  |  |--36c5af2fa955fd74905f12a2ce2bce14d9ea70
|  |  |  |--7fc66c90730d49a51b3181eae922dba7cb5269
|  |  |  |--94fd76fbb2c09132cd2812880cb99bf01f8ef8
|  |  |--90
|  |  |  |--53ccb12c828df298dc9842be82c07e98a05f17
|  |  |--91
|  |  |  |--d2a156cf1856ccda0901409fbbbf763333ba50
|  |  |--92
|  |  |  |--16547dfb3808c3554dba91df3d64188dd0acd2
|  |  |--93
|  |  |  |--1a464c6911d5a1dd3dc9cc3181db6d5ddcad49
|  |  |  |--ec1fcdec360dadf5c66f847fe84fa177e5a76a
|  |  |--96
|  |  |  |--361b1313e3079507c9fa964ef9b63e5db4b849
|  |  |  |--f158ca55c35134221f0e4b79f95086762e8b5a
|  |  |--98
|  |  |  |--a7a5ad52b5e2397ded9146ce9bd95619413668
|  |  |  |--f7803fa7f820358e7ed805311e1ed1069e1687
|  |  |--99
|  |  |  |--75cf9b2acad6f15b7b3a9cdcb2334b98a5933d
|  |  |--9a
|  |  |  |--5f396e95b729c144eeb777dbdf43073eed9733
|  |  |--9b
|  |  |  |--de82d62ff87d8f1bfd08fa9eb118594fb9af43
|  |  |--9c
|  |  |  |--b6c2000e446f5d5aebf314058ef1a32782d360
|  |  |--9e
|  |  |  |--11314afcd2ea9d230cfc17ee6bcf1c15a9e432
|  |  |  |--7744b9373fda88cf8995003d147ca4169dc466
|  |  |  |--b1e4b899aa7d16da97562b9ed3cc31b361f772
|  |  |  |--b31bee0137ef33eff3cc5ddb0a0ef6a5179d46
|  |  |  |--bc1f4a8ee57eb0845ed55a45b118c0dfd5d6fb
|  |  |--9f
|  |  |  |--4dae0285a967a5210a51abac0544991f7aa8b5
|  |  |  |--77d4fb62a720d2dba9c63f808ad466be814670
|  |  |  |--ed3e1a4dfc1ec03e46d37960477456e797d0cb
|  |  |--a0
|  |  |  |--5e753190b7d26ba155b2eba66a3a8eae45eb7f
|  |  |--a3
|  |  |  |--96a50dfab8e612c876aef1905727d39aaa9d31
|  |  |  |--dcffcc562f79ab3cbec2b745b224a452269976
|  |  |--a5
|  |  |  |--0e9f42dcec1840f0ce57065bbff7f308e0b105
|  |  |  |--8af346db2b17effb437d5ea7156b7a758282e9
|  |  |  |--db56fd6b824bbaffe9e18655cd6a948a75d2bd
|  |  |--a6
|  |  |  |--11c5f08fc91203bae65be585a6c8413bd606a4
|  |  |  |--fc8f2040dfb8485b540cf7555a717af4f31a35
|  |  |--a7
|  |  |  |--8b1c9b0660cabeeebf11f31ed30a39121e0407
|  |  |--a8
|  |  |  |--5c1ed6e5e187ea2fb7a296fcb0183bcc7ffeb8
|  |  |  |--e6474f997e41512d424b2377f7d52901937bb8
|  |  |--a9
|  |  |  |--3523a42467c6edc3a021d9d698ce727a54d3cd
|  |  |--aa
|  |  |  |--b2ead7232c1bd7d3ed341b41dd808ba8418817
|  |  |  |--ec0f40b72667a4c780b247963d6c0767d7183f
|  |  |--ab
|  |  |  |--6b48a394e32645efc4312ddf6265e51e584fbb
|  |  |  |--73a6f6962a0887db38fad0c155715af450b913
|  |  |  |--e4f00dee4a5d13323801a18924c51777797f89
|  |  |--ac
|  |  |  |--54f954b4d9657521b20ed5a393f40dc4652b2e
|  |  |--ae
|  |  |  |--d686cc2387d0ba2e208297d56a3cdd2c57f556
|  |  |--af
|  |  |  |--2631c85a3ae660a57165e0f35495d31727ad32
|  |  |--b0
|  |  |  |--947fde10214d62edc152f1fd198056c6d8fde5
|  |  |--b1
|  |  |  |--6f93e7be67beda0233f906c7c3194b5d33a70a
|  |  |  |--d969fc7d968864ecb00f04e34d6d91f01653b1
|  |  |--b2
|  |  |  |--3d91902d0a6085fdb5f6a8eb6388ee90b00222
|  |  |  |--553f3815be4100adba7a9eea735bde80cbe950
|  |  |--b4
|  |  |  |--0a34efc42839d8c2f79d2f089ee56e86de7a75
|  |  |  |--0b5cd37b90e356c0117be812cea165825e8eac
|  |  |--b5
|  |  |  |--12b4d5340c4f5541e778fb158ec8c13ecb811b
|  |  |  |--95dc5285fb6f3cb4fc1652d3ccd9d38801e5a3
|  |  |--b7
|  |  |  |--193e9533ee2189bf735e2d89708b5a429293f4
|  |  |--b8
|  |  |  |--a41ba10ad35919761c5cab00c859d8b98cd74a
|  |  |--b9
|  |  |  |--40fa5c59f21fb6b16c0b4655d37165a2bda19d
|  |  |  |--73ac456f21b779b9f986f42285b27118d189aa
|  |  |  |--e4c453425519924a3dd25aab7663c2c6e74466
|  |  |  |--ec974e66b764cd7f7b270eb9bc623697d7cc32
|  |  |--ba
|  |  |  |--347b6acf2b92fd6f92d75804a995b2e5c04278
|  |  |  |--845d43366a6c5622e3ba7a9ae346ac214e5d4d
|  |  |  |--a7518c7c27910d3550e0df1d01c7e2cf71c091
|  |  |  |--df392f7d65b22eefa07b741cb7fdc2f85faea8
|  |  |--bb
|  |  |  |--59caf16afd7915925fe6e3b2008d9230bbeae5
|  |  |--bc
|  |  |  |--05766472e27d90661e1c85d295d7faf57a9a44
|  |  |  |--80b2c71936da8a18c3c0d184b4200450d18d38
|  |  |--bd
|  |  |  |--85db7c1ecee8786a5b7881f5b6ae51c3359f7b
|  |  |--be
|  |  |  |--72dbd843c83bf54e19addf18e82bbba8b6c937
|  |  |--bf
|  |  |  |--b406673c2689c1274a5573e6141e72594711c2
|  |  |--c0
|  |  |  |--048d84fdb7f0fca4303520cf5113bd55fd30a1
|  |  |  |--0ed110d49feb8ca63950e486f9747b2fc7bbff
|  |  |  |--d47a39b579ff2e6a30874c3adbd2495b26508c
|  |  |--c1
|  |  |  |--8d8df238d340761ef167279113e20ed418716a
|  |  |--c2
|  |  |  |--26eb7042ad4235ee4e6a15a580c239efcf8207
|  |  |  |--2c7a9a3821b79a6a93af71792b14e8102151ad
|  |  |  |--b11f4c85b5da999b34682501629bf13e3de6f0
|  |  |--c3
|  |  |  |--5827472e41f8482b9c611abbc6ed10fd6417c4
|  |  |--c5
|  |  |  |--281a5ceb431719f2046dd167d6ff0a033a7e98
|  |  |--c6
|  |  |  |--5ac0ea3bcf63c0d85c3c16ea28c72134f9fb8f
|  |  |--c8
|  |  |  |--2f382015452917e34b3930e9543dcb6878b1bb
|  |  |--ca
|  |  |  |--80461b41e8a6903122c36d57422dcb6dbcb8c1
|  |  |  |--ed8ee2c745cdeab3afd81405db74f49d2e9f0b
|  |  |--cb
|  |  |  |--8c53f43565940abaca58fc60191a69fe28f3bd
|  |  |--cc
|  |  |  |--4518e7ec379c9883aab6a3cf88362523a4ecf9
|  |  |  |--90b3df457a56e42f409fb58495be86aa577834
|  |  |  |--eb1d5127696adb1478a5200233ef455a988d82
|  |  |--cd
|  |  |  |--807f0845ca1b38f7f8187724cab60436398a16
|  |  |--ce
|  |  |  |--82adc4dd5d26cbdcd1c7a4b17ad6710eb28956
|  |  |  |--a8f79d7efa9cf5fbf1d2e476eee0e32726ae2b
|  |  |--d0
|  |  |  |--4b0a62b0823632558d1685a4f3169a8d24d06d
|  |  |--d1
|  |  |  |--0cc29fb4245d049a84c1d3d094eb7a1905c00d
|  |  |  |--4207cc79afdc9ad833935cc97137f44de80555
|  |  |  |--d855cb6f55e0a12ae42d0f982a40444e3cbfdc
|  |  |  |--ee640f8e73dbb3d67a5398c96f689c689b9f05
|  |  |--d2
|  |  |  |--ecdf7c5af463bf964e014d3d6ebdac34db8a64
|  |  |--d3
|  |  |  |--6dfd0918da2c5909292800be32e15a292093da
|  |  |  |--b5e9543a7daa2c733895bcd0b8d27495954dda
|  |  |  |--f2ee5bb9379f161d6fc0e1d6645290f07cddb0
|  |  |--d4
|  |  |  |--4597fbe8317eeca55b9202cfd973933581c8ad
|  |  |  |--d037b15a0561e2a572a599ea82a49a2b817d16
|  |  |--d5
|  |  |  |--f3d1d16e2d9b3dd58251d5b1c88a396093bbbc
|  |  |--d6
|  |  |  |--c4547cc1e246922dded4c9760463f25828a9c0
|  |  |  |--dc799be9619bdf01b42b91ebf26a76d1a10fa0
|  |  |--d7
|  |  |  |--1309eafae0f75831460eb9842c5f0a7c39149b
|  |  |--d9
|  |  |  |--6ea221332e02d1410fc9c31f76912a452e3a19
|  |  |--dc
|  |  |  |--6b6cf1f21529f32d800b1bec9d4ecd1fea9142
|  |  |--de
|  |  |  |--ab66f947493abbde918e322e8f08390442e05e
|  |  |  |--d8cccc5d3ef4490034619ac9f84105003dfddd
|  |  |--df
|  |  |  |--35ac746a895986eed55b140f812e5e8622d97f
|  |  |  |--c64a00cf1bf29c2828a4abfd09386d6ba9745e
|  |  |--e2
|  |  |  |--beaf717b7d491882618e87a24375d630a97833
|  |  |--e3
|  |  |  |--4fff5d77d9f258a71598f63109f8dc59f0ccb8
|  |  |--e6
|  |  |  |--4d2b47c3fce266cf561e51ded88c10e3150d2d
|  |  |--e8
|  |  |  |--52edd0519414ed61ee39d786b50bd8a8b0d389
|  |  |--ea
|  |  |  |--58c2a1b1647416fba749d60c2b3d9aa710591c
|  |  |--eb
|  |  |  |--4e86d6c4b555b249f18be1780a66cc28d1e86a
|  |  |--ec
|  |  |  |--02a9bf7c8a9cb93f09bb96bc78ced7be71bf9d
|  |  |  |--cc7a83c6d704d257405f3e39d70af5a171ff0d
|  |  |--ed
|  |  |  |--11dfe8eb30c2c9d2ac9c78404ebf002c0a0acb
|  |  |  |--b78c5021b50782a41728449ef4bd2e72610304
|  |  |--ee
|  |  |  |--166d12b8f9a88a1d4d932a23e844d8203efa13
|  |  |--f0
|  |  |  |--003fe97f1edc8d7ad3752e2044f391f48d4521
|  |  |  |--eac59b12bba969fdec0e29b7558e441f7be14f
|  |  |--f3
|  |  |  |--d05081f3294e8d065d439d7eccec5dfe6d3e2a
|  |  |--f4
|  |  |  |--c9fe79ed9ab28ffae1cf38168129f0eda25c19
|  |  |--f6
|  |  |  |--689a22b167e07e9cd4cea11c332dab3019d6f4
|  |  |--f7
|  |  |  |--5323135cb43230743ca9e1280337ac4f385a11
|  |  |--f8
|  |  |  |--fab6e2cdd451989c400019ba7501dc92f42d07
|  |  |--f9
|  |  |  |--c103861d377f9c815e04f4259ba8cde75d8a65
|  |  |--fa
|  |  |  |--389b5c6d41077b39bfd6729291acbbb49dab98
|  |  |--fb
|  |  |  |--2917fb502fba1383513ff3f3b20ecc45d1495a
|  |  |--fd
|  |  |  |--1831f6d8a67fddf8c54e61c72c25ecc01a944b
|  |  |--ff
|  |  |  |--92a292af8c95fcadd8f06f1021edb8a60c7a6e
|  |  |--info
|  |  |--pack
|  |  |  |--pack-be37bf826ddc1f452600d71743d1086085a9486a.idx
|  |  |  |--pack-be37bf826ddc1f452600d71743d1086085a9486a.pack
|  |  |  |--pack-be37bf826ddc1f452600d71743d1086085a9486a.rev
|  |--packed-refs
|  |--refs
|  |  |--heads
|  |  |  |--main
|  |  |--remotes
|  |  |  |--origin
|  |  |  |  |--HEAD
|  |  |  |  |--main
|  |  |--tags
|--.github
|  |--ISSUE_TEMPLATE
|  |  |--requirement-analysis.md
|--.gitignore
|--README.md
|--agents.md
|--docs
|  |--directory.md
|  |--spec
|  |  |--10_network.md
|  |  |--20_auth.md
|  |  |--30_api.md
|  |  |--40_aoai.md
|  |  |--50_aca.md
|  |  |--60_db.md
|  |  |--70_secret.md
|  |  |--80_bicep.md
|  |  |--spec.md
|  |--task_list.md
|  |--test
|  |  |--10_network_test.md
|  |  |--20_auth_test.md
|  |  |--30_api_test.md
|  |  |--40_aoai_test.md
|  |  |--50_aca-env_test.md
|  |  |--99_e2e_test.md
|  |  |--test.md
|--infra
|  |--deploy.ps1
|  |--docs
|  |  |--apim-plan.md
|  |--main.bicep
|  |--modules
|  |  |--aca-env
|  |  |--aca-env.bicep
|  |  |  |--application.bicep
|  |  |  |--edge-runtime.bicep
|  |  |  |--platform.bicep
|  |  |--apim-placeholder.bicep
|  |  |--apim.bicep
|  |  |--appgw.bicep
|  |  |--keyvault.bicep
|  |  |--network.bicep
|  |  |--nsg.bicep
|  |  |--postgresql.bicep
|  |  |--redis-cache.bicep
|  |  |--storage.bicep
|  |--mountfiles
|  |  |--nginx
|  |  |  |--conf.d
|  |  |  |  |--default.conf
|  |  |  |--fastcgi_params
|  |  |  |--mime.types
|  |  |  |--modules
|  |  |  |  |--ngx_http_geoip_module-debug.so
|  |  |  |  |--ngx_http_geoip_module.so
|  |  |  |  |--ngx_http_image_filter_module-debug.so
|  |  |  |  |--ngx_http_image_filter_module.so
|  |  |  |  |--ngx_http_js_module-debug.so
|  |  |  |  |--ngx_http_js_module.so
|  |  |  |  |--ngx_http_xslt_filter_module-debug.so
|  |  |  |  |--ngx_http_xslt_filter_module.so
|  |  |  |  |--ngx_stream_geoip_module-debug.so
|  |  |  |  |--ngx_stream_geoip_module.so
|  |  |  |  |--ngx_stream_js_module-debug.so
|  |  |  |  |--ngx_stream_js_module.so
|  |  |  |--nginx.conf
|  |  |  |--proxy.conf
|  |  |  |--scgi_params
|  |  |  |--uwsgi_params
|  |  |--sandbox
|  |  |  |--python-requirements.txt
|  |  |--ssrfproxy
|  |  |  |--conf.d
|  |  |  |  |--debian.conf
|  |  |  |  |--rock.conf
|  |  |  |--errorpage.css
|  |  |  |--squid.conf
|  |--parameters
|  |  |--parameters_dev.example.json
|  |  |--parameters_prd.example.json
|--pipelines
|  |--azure-pipeline-cd.yaml
|  |--azure-pipeline-ci.yaml
```
