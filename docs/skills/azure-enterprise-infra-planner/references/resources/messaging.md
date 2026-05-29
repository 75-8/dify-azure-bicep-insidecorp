# Messaging

## Common resources

- Event Grid (`Microsoft.EventGrid/systemTopics`, `Microsoft.EventGrid/topics`)
- Event Hubs (`Microsoft.EventHub/namespaces`)
- Service Bus (`Microsoft.ServiceBus/namespaces`)

## Planning notes

- Match ordering, throughput, retention, and dead-letter requirements to the service.
- Use private endpoints and managed identities for enterprise integration.
- Plan diagnostics, alerting, and retry semantics.
