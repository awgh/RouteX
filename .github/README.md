# GitHub Workflows

This directory contains the CI/CD workflows for the RouteX project.

## Workflow Overview

### 1. Build Workflow (`build.yml`)
**Purpose**: Builds the application and creates release artifacts
**Triggers**: Push to main/develop, Pull requests to main
**Jobs**:
- **Build**: Compiles the app with multiple Xcode versions (14.3, 15.0)
- **Archive**: Creates release archives for distribution

### 2. Test Workflow (`test.yml`)
**Purpose**: Runs comprehensive tests
**Triggers**: Push to main/develop, Pull requests to main
**Jobs**:
- **Unit Tests**: Runs XCTest-based unit tests with multiple Xcode versions
- **UI Tests**: Runs UI tests for the SwiftUI interface
- **Custom Tests**: Runs the custom test script for additional validation

### 3. Code Quality Workflow (`code-quality.yml`)
**Purpose**: Ensures code quality and security
**Triggers**: Push to main/develop, Pull requests to main
**Jobs**:
- **Lint**: Runs SwiftLint for code style consistency
- **Security**: Performs security audits for hardcoded secrets
- **Format**: Checks code formatting and line endings

### 4. Release Workflow (`release.yml`)
**Purpose**: Creates and publishes releases
**Triggers**: Push of version tags (v*)
**Jobs**:
- **Release**: Builds app bundle, creates DMG, publishes to GitHub releases

## Configuration Files

### SwiftLint Configuration (`.swiftlint.yml`)
- Configures code style rules
- Sets appropriate limits for function/type body lengths
- Excludes build artifacts and external projects

## Workflow Dependencies

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Code Quality  │    │      Test       │    │      Build      │
│   (Lint,        │    │   (Unit, UI,    │    │   (Compile,     │
│    Security,    │    │    Custom)       │    │    Archive)     │
│    Format)      │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │     Release     │
                    │  (DMG, GitHub  │
                    │    Releases)    │
                    └─────────────────┘
```

## Key Features

### Multi-Xcode Testing
- Tests against Xcode 14.3 and 15.0
- Ensures compatibility across different Xcode versions

### Comprehensive Testing
- Unit tests using XCTest framework
- UI tests for SwiftUI components
- Custom test script for additional validation

### Security Audits
- Checks for hardcoded secrets
- Validates file permissions
- Ensures proper entitlements

### Code Quality
- SwiftLint for consistent code style
- Format checking for trailing whitespace and line endings
- Comprehensive error reporting

### Release Automation
- Automatic DMG creation
- GitHub releases with proper changelog
- Artifact uploads for debugging

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Xcode version compatibility
   - Verify all dependencies are available
   - Review build logs for specific errors

2. **Test Failures**
   - Ensure test targets are properly configured
   - Check for missing test dependencies
   - Verify test environment setup

3. **Lint Errors**
   - Review SwiftLint configuration
   - Fix code style violations
   - Update `.swiftlint.yml` if needed

4. **Release Issues**
   - Verify tag format (v*)
   - Check GitHub token permissions
   - Ensure app bundle is properly created

### Debugging

- All workflows generate detailed logs
- Test results are uploaded as artifacts
- Build artifacts are preserved for inspection
- Security audit results are clearly reported

## Local Development

To run these workflows locally:

```bash
# Run tests
xcodebuild test -project RouteX.xcodeproj -scheme RouteX

# Run SwiftLint
swiftlint lint

# Build for release
./build.sh
```

## Contributing

When contributing to RouteX:

1. Ensure all workflows pass before submitting PRs
2. Follow the established code style (SwiftLint)
3. Include appropriate tests for new features
4. Update documentation as needed 