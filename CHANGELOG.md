# Changelog

## [0.1.1] - 2026-03-14

### Added
- Optional LLM enhancement via Helpers::LlmEnhancer — `enhance_reflection(monitors_data:, health_scores:)` enhances the observation text on each reflection entry with analytically generated prose (preserves all category, severity, and recommendation symbols — only the human-readable observation string is replaced). `reflect_on_dream(dream_results:)` generates a first-person, present-tense reflection on a completed dream cycle for the new `reflect_on_dream` runner method. Both methods gate on `Legion::LLM.started?` and fall back to template observation strings when LLM is unavailable.

## [0.1.0] - 2026-03-13

### Added
- Initial release
