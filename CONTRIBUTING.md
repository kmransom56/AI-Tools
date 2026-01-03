# Contributing

Thanks for contributing! Please follow the project conventions to ensure CI runs and your contributions are reviewed consistently.

## Branch naming & CI behavior
- CI runs for pushes to `main`, and for pull requests whose source branch uses one of the following prefixes:
  - `feat/` (new features)
  - `fix/` (bug fixes)
  - `hotfix/` (urgent fixes)
  - `chore/` (maintenance tasks)
  - `docs/` (documentation changes)
  - `release/` (release updates)

This means: create a branch using one of the prefixes above (e.g., `feat/add-vault-integration`) to ensure the PortManager normalization & tests run automatically for your PR.

## Running tests locally
- Normalize your local port registry (creates a backup):

```powershell
.\scripts\portmanager\normalize-port-registry.ps1
```

- Run the PortManager test runner (writes a log to `artifacts/` and opens it during local runs):

```powershell
.\scripts\portmanager\run-portmanager-tests.ps1
```

If tests fail, include the logfile found in `artifacts/` and any backup registry in `artifacts/backups/` when creating a PR comment.

---

If you have questions about the workflow or need the CI to run for other prefixes, open an issue or discuss in the PR.