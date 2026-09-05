# EvoBar Privacy

EvoBar is local-first. Usage tracking reads local provider data and extracts only token counts, timestamps, provider and model identifiers, and session identifiers. Prompt text, responses, code, raw log lines, and project paths are not persisted, logged, exported, or sent to a server.

Optional official-quota, provider-status, purchase, catalog-update, and application-update features may make network requests. These integrations must be independently switchable and must never attach local usage events or project paths to requests.

Provider-status checks are enabled by default and can be disabled in Settings. When enabled, EvoBar requests only the public status JSON from `status.claude.com` and `status.openai.com`, at most once every five minutes. No token count, session identifier, log path, animal record, or other local app data is attached; as with any direct web request, the destination can observe ordinary network metadata such as the connecting IP address.

Automatic update checks are enabled by default and can be disabled in Settings. At launch, EvoBar requests the latest public release metadata from `api.github.com/repos/kitesik/EvoBar/releases/latest`, sending only the installed EvoBar version in the standard `User-Agent` header. Manual checks remain available when automatic checks are disabled. EvoBar links to the HTTPS GitHub release page and does not silently download or install software.

Diagnostics use provider IDs, anonymous source fingerprints, byte offsets, and error categories only.

User-added log patterns stay in the local settings database. Aggregate export deliberately excludes those paths, individual usage events, provider session identifiers, source fingerprints, and scan checkpoints.

The Application Support directory is restricted to the current macOS user, and the local state and signed-license files are written with owner-only filesystem permissions. EvoBar also repairs overly broad permissions when it opens an existing state file.

Credentials explicitly entered for a future documented integration are stored through macOS Keychain and never in EvoBar's JSON database. EvoBar does not import or reuse another application's cached login file, keychain item, or session token. Current DEBUG quota meters are labelled local demo data; current RELEASE quota services make no quota network request because a supported personal-account API has not been documented.

The local state store keeps one owner-only last-known-good backup beside the primary state file for corruption recovery. A confirmed local-data reset replaces both files with fresh empty state, preventing recovery from resurrecting deleted history.

Local companion and quota notifications are opt-in. macOS authorization is requested only after the user enables either feature. Companion notifications contain only the user-chosen animal name and evolution-stage name; quota notifications contain only provider name, quota-window name, and utilization percentage.
