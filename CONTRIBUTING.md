# Contributing to ChoghadiyaKit

Thank you for your interest in improving **ChoghadiyaKit**! We welcome contributions from the community.

---

## Code of Conduct

All contributors are expected to adhere to our [Code of Conduct](CODE_OF_CONDUCT.md). Please be courteous, constructive, and respectful in all interactions.

---

## How Can I Contribute?

- **Reporting Bugs:** If you discover a calculation discrepancy, timezone edge case, or crash, please open an issue with full reproduction steps.
- **Suggesting Features:** Ideas for expanding the astronomical calculations (e.g. offline solar calculation engine, Rahu Kaal, Hora, Yamagandam) are warmly welcomed.
- **Submitting Pull Requests:** We appreciate bug fixes, performance improvements, and documentation enhancements.

---

## Development Workflow

1. **Fork the Repository:** Create your own fork and clone it locally.
2. **Create a Topic Branch:**
   ```bash
   git checkout -b feature/my-feature-name
   ```
3. **Make Your Changes:** Follow Apple's official Swift API Design Guidelines and our architecture patterns.
4. **Enforce Concurrency Safety:** Ensure your changes do not introduce data races or compiler warnings under Swift 6 strict concurrency:
   ```bash
   swift build -Xswiftc -strict-concurrency=complete
   ```
5. **Run the Test Suite:** Ensure all existing and new unit tests pass:
   ```bash
   swift test -Xswiftc -strict-concurrency=complete
   ```
6. **Commit with Conventional Commits:**
   - `feat: ...` for new features
   - `fix: ...` for bug fixes
   - `docs: ...` for documentation changes
   - `test: ...` for adding or modifying tests
   - `refactor: ...` for code reorganization without behavior change
7. **Submit a Pull Request:** Open a PR against the `main` branch with a clear summary of your changes.

---

## Architectural Guidelines

- **Zero Data Races:** All new public types must conform to `Sendable`. Avoid mutable global state or non-Sendable captures.
- **SOLID Compliance:** High-level facades must depend on abstractions (protocols), never on concrete network classes.
- **SwiftUI Ready:** Keep domain models lightweight, value-typed (`struct`), and conforming to `Identifiable` and `Codable` where appropriate.
- **Test Coverage:** Every bug fix or new feature must be accompanied by comprehensive unit tests.
