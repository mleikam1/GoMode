# GoMode Agent Rules

- Never commit secrets, signing keys, service account files, API keys, local `.env` files, or generated credential bundles.
- Use the minimal Google API fields required for a feature. Do not request broad place, map, or location payloads when narrower fields will do.
- Keep UI implementation faithful to `docs/design_refs/approved`.
- Commit after each milestone with a focused message.
- Run `dart format .`, `flutter analyze`, and `flutter test` before committing.
- Document assumptions and product or technical decisions in `docs/decisions.md`.
- Keep generated code and platform settings reviewable; avoid unrelated refactors during feature work.
