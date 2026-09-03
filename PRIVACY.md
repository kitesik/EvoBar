# EvoBar Privacy

EvoBar is local-first. Usage tracking reads local provider data and extracts only token counts, timestamps, provider and model identifiers, and session identifiers. Prompt text, responses, code, raw log lines, and project paths are not persisted, logged, exported, or sent to a server.

Optional official-quota, provider-status, purchase, catalog-update, and application-update features may make network requests. These integrations must be independently switchable and must never attach local usage events or project paths to requests.

Provider-status checks are enabled by default and can be disabled in Settings. When enabled, EvoBar requests only the public status JSON from `status.claude.com` and `status.openai.com`, at most once every five minutes. No token count, session identifier, log path, animal record, or other local app data is attached; as with any direct web request, the destination can observe ordinary network metadata such as the connecting IP address.

Diagnostics use provider IDs, anonymous source fingerprints, byte offsets, and error categories only.

User-added log patterns stay in the local settings database. Aggregate export deliberately excludes those paths, individual usage events, provider session identifiers, source fingerprints, and scan checkpoints.

Credentials explicitly entered for a future documented integration are stored through macOS Keychain and never in EvoBar's JSON database. EvoBar does not import or reuse another application's cached login file, keychain item, or session token. Current DEBUG quota meters are labelled local demo data; current RELEASE quota services make no quota network request because a supported personal-account API has not been documented.

Local quota notifications are opt-in. macOS authorization is requested only after the user enables them, and notification content contains only provider name, quota-window name, and utilization percentage.
