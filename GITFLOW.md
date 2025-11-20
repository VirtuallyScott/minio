# Git Flow Branching Strategy

This repository follows the Git Flow branching model to manage development and releases.

## Branch Structure

### Main Branches

- **main** - Production-ready code. All releases are tagged from this branch.
- **develop** - Integration branch for features. This is the default branch for development.

### Supporting Branches

#### Feature Branches
- **Naming**: `feature/<feature-name>`
- **Branch from**: `develop`
- **Merge back to**: `develop`
- **Purpose**: Develop new features for upcoming releases

```bash
# Create a feature branch
git checkout develop
git checkout -b feature/my-new-feature

# Work on your feature
git add .
git commit -m "feat: add new feature"

# Merge back to develop
git checkout develop
git merge --no-ff feature/my-new-feature
git branch -d feature/my-new-feature
git push origin develop
```

#### Release Branches
- **Naming**: `release/<version>`
- **Branch from**: `develop`
- **Merge back to**: `main` and `develop`
- **Purpose**: Prepare for a new production release

```bash
# Create a release branch
git checkout develop
git checkout -b release/v1.0.0

# Prepare release (version bumps, documentation, etc.)
git commit -m "chore: prepare release v1.0.0"

# Merge to main
git checkout main
git merge --no-ff release/v1.0.0
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin main --tags

# Merge back to develop
git checkout develop
git merge --no-ff release/v1.0.0
git push origin develop

# Delete release branch
git branch -d release/v1.0.0
```

#### Hotfix Branches
- **Naming**: `hotfix/<version>`
- **Branch from**: `main`
- **Merge back to**: `main` and `develop`
- **Purpose**: Quick fixes for production issues

```bash
# Create a hotfix branch
git checkout main
git checkout -b hotfix/v1.0.1

# Fix the issue
git commit -m "fix: critical production bug"

# Merge to main
git checkout main
git merge --no-ff hotfix/v1.0.1
git tag -a v1.0.1 -m "Hotfix v1.0.1"
git push origin main --tags

# Merge back to develop
git checkout develop
git merge --no-ff hotfix/v1.0.1
git push origin develop

# Delete hotfix branch
git branch -d hotfix/v1.0.1
```

## Development Workflow

1. **For new features**: Create a feature branch from `develop`
2. **For releases**: Create a release branch from `develop`
3. **For hotfixes**: Create a hotfix branch from `main`

## Pull Request Guidelines

- All feature branches should be merged into `develop` via Pull Request
- Release and hotfix branches should be merged into both `main` and `develop`
- Require at least one code review before merging
- Ensure CI/CD checks pass before merging

## Docker Image Building

This fork is specifically maintained to build custom Docker images for lab use. Docker images will be built from:
- The `main` branch for production releases
- The `develop` branch for testing and development

## Additional Resources

- [Git Flow Original Blog Post](https://nvie.com/posts/a-successful-git-branching-model/)
- [Atlassian Git Flow Tutorial](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
