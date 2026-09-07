# Optional relay — not required by RC1

RC1 uses the owner-approved direct reporting destination in the shared Feedback module. The relay below remains an optional future alternative and is not deployed.

# Shared report destination — prepared, not deployed

Deploy worker.js as a Cloudflare Worker with FEEDBACK_WEBHOOK stored as a secret and REPORT_LIMITS bound to a KV namespace. Configure the resulting HTTPS URL through SerenityFeedbackRelay (or the library FeedbackRelay option). End users then submit reports without seeing or entering a webhook URL. No secret is stored in this repository.

KV provides a best-effort cooldown, not an atomic global abuse limit. Before public release, enable an edge rate-limit rule appropriate to traffic. No account credentials or tokens are sent by the client; game identifiers are user-supplied context and are not proof of game activity.

This relay has not been deployed or connected to the user's destination. No Discord request has been sent by the development checks.
