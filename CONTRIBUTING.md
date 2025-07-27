# Contributing to RouteX

Thank you for your interest in contributing to RouteX! This document provides guidelines and information for contributors.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Requirements](#testing-requirements)
- [Submitting Changes](#submitting-changes)
- [Issue Reporting](#issue-reporting)
- [Feature Requests](#feature-requests)

## Code of Conduct

RouteX is committed to providing a welcoming and inclusive environment for all contributors. Please be respectful, considerate, and professional in all interactions.

## Getting Started

### Prerequisites
- **macOS 12.0+** for development and testing
- **Swift 5.9+** for building and testing
- **Administrator privileges** for testing route modifications
- **Git** for version control

### Initial Setup
1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/yourusername/routex.git
   cd routex
   ```
3. **Build** the project to ensure everything works:
   ```bash
   ./build.sh
   ```
4. **Run tests** to verify your setup:
   ```bash
   ./run_tests.sh
   ```
5. **Alternative**: Use Swift Package Manager directly:
   ```bash
   swift build -c release
   swift test
   ```

## Development Workflow

### Branch Strategy
- **`main`**: Stable release branch
- **`develop`**: Integration branch for new features
- **`feature/feature-name`**: Individual feature branches
- **`bugfix/issue-number`**: Bug fix branches
- **`hotfix/issue-number`**: Critical fixes for production

### Working on Features
1. **Create a feature branch** from `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the guidelines below

3. **Test thoroughly** including:
   - Unit tests: `./run_tests.sh`
   - Manual testing on multiple macOS versions
   - Route creation/deletion scenarios
   - Edge cases and error conditions

4. **Commit your changes** with descriptive messages:
   ```bash
   git add .
   git commit -m "feat: add support for IPv6 route validation"
   ```

5. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request** to the `develop` branch

### Commit Message Format
Follow the [Conventional Commits](https://conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation updates
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build system, dependencies, etc.

**Examples:**
```
feat(routing): add blackhole route support
fix(ui): resolve phantom route display issue
docs: update installation instructions
test: add route validation test cases
```

## Code Style Guidelines

### Swift Style
Follow Apple's [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and these project-specific rules:

#### General Principles
- **Clarity over brevity**: Code should be self-documenting
- **Consistency**: Follow existing patterns in the codebase
- **Safety**: Prefer safe APIs and handle errors appropriately

#### Naming Conventions
```swift
// Classes and Structs: PascalCase
class RouteManager { }
struct NetworkRoute { }

// Functions and Variables: camelCase
func addRoute(_ route: NetworkRoute) { }
var isValidDestination: Bool = false

// Constants: camelCase with descriptive names
private let phantomRouteCacheKey = "RouteX_PhantomRoutes"

// Enums: PascalCase with camelCase cases
enum RouteType {
    case auto
    case network
    case host
}
```

#### SwiftUI Specific
```swift
// State variables: descriptive names with type
@State private var destinationText = ""
@State private var selectedRouteType = RouteType.auto
@State private var showingAdvancedOptions = false

// Computed properties: clear intent
var isValidInput: Bool {
    !destination.isEmpty && !gateway.isEmpty
}

// View builder: logical grouping
var body: some View {
    VStack(spacing: 16) {
        headerSection
        contentSection
        footerSection
    }
}
```

#### Documentation
Use Swift's documentation format for public APIs:

```swift
/// Manages network route operations with system integration
///
/// RouteManager provides a high-level interface for route management,
/// handling privilege escalation, command generation, and error handling.
class RouteManager: ObservableObject {
    
    /// Adds a new route to the system routing table
    /// 
    /// - Parameters:
    ///   - route: The route configuration to add
    ///   - completion: Callback with success status and optional error message
    func addRoute(_ route: NetworkRoute, completion: @escaping (Bool, String?) -> Void) {
        // Implementation
    }
}
```

### File Organization
```swift
// MARK: - Imports
import SwiftUI
import Foundation

// MARK: - Main Type Definition
struct ContentView: View {
    
    // MARK: - Properties
    @StateObject private var routeManager = RouteManager()
    @State private var searchText = ""
    
    // MARK: - Computed Properties
    var filteredRoutes: [NetworkRoute] {
        // Implementation
    }
    
    // MARK: - Body
    var body: some View {
        // Implementation
    }
    
    // MARK: - Private Methods
    private func refreshRoutes() {
        // Implementation
    }
}

// MARK: - Helper Extensions
extension ContentView {
    // Additional functionality
}
```

## Testing Requirements

### Test Coverage Requirements
- **New features**: Must include comprehensive unit tests
- **Bug fixes**: Must include regression tests
- **UI changes**: Should include UI tests where appropriate
- **Route operations**: Must test both success and failure scenarios

### Test Categories

#### Unit Tests (`RouteXTests/`)
```swift
// RouteManagerTests.swift - Business logic
func testAddRouteValidation() {
    // Test route validation logic
}

func testCommandGeneration() {
    // Test route command generation
}

// RouteModelTests.swift - Data models
func testDestinationInterpretation() {
    // Test shorthand and CIDR parsing
}

func testRouteFlags() {
    // Test flag handling
}

// AddRouteViewTests.swift - UI validation
func testFormValidation() {
    // Test input validation
}
```

#### Integration Tests
```swift
func testEndToEndRouteCreation() {
    // Test complete route creation flow
    // (Note: requires admin privileges)
}
```

### Running Tests
```bash
# Run all tests
./run_tests.sh

# Run specific test file
xcodebuild test -project RouteX.xcodeproj -scheme RouteX -only-testing:RouteXTests/RouteManagerTests

# Run specific test method
xcodebuild test -project RouteX.xcodeproj -scheme RouteX -only-testing:RouteXTests/RouteManagerTests/testRouteValidation
```

### Test Guidelines
- **Isolated**: Each test should be independent
- **Fast**: Unit tests should run quickly
- **Deterministic**: Tests should not depend on external state
- **Clear**: Test names should describe what is being tested

```swift
func testDestinationInterpretation_WithShorthandNotation_ReturnsCorrectNetworkForm() {
    // Given
    let destination = "172.1"
    let route = NetworkRoute(destination: destination, routeType: .network)
    
    // When
    let interpretation = route.interpretDestination()
    
    // Then
    XCTAssertTrue(interpretation.isValid)
    XCTAssertEqual(interpretation.networkForm, "172.1.0.0/16")
}
```

## Submitting Changes

### Pull Request Guidelines
1. **Target Branch**: Submit PRs to `develop` branch
2. **Title**: Clear, descriptive title following commit message format
3. **Description**: Include:
   - Summary of changes
   - Related issue numbers
   - Testing performed
   - Screenshots (for UI changes)
   - Breaking changes (if any)

### PR Template
```markdown
## Description
Brief description of changes

## Related Issues
Fixes #123
Related to #456

## Changes Made
- [ ] Added new feature X
- [ ] Fixed bug Y
- [ ] Updated documentation Z

## Testing
- [ ] Unit tests pass
- [ ] Manual testing completed
- [ ] Tested on macOS versions: [list versions]

## Screenshots (if applicable)
[Add screenshots for UI changes]

## Breaking Changes
[List any breaking changes]

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Tests added/updated
- [ ] Documentation updated
```

### Review Process
1. **Automated Checks**: CI/CD runs tests and style checks
2. **Code Review**: Maintainers review for:
   - Code quality and style
   - Test coverage
   - Documentation completeness
   - Security considerations
3. **Testing**: Changes are tested on multiple macOS versions
4. **Approval**: Two maintainer approvals required for merge

## Issue Reporting

### Bug Reports
Use the bug report template and include:

```markdown
**Environment:**
- macOS version: [e.g., 13.0]
- RouteX version: [e.g., 1.0.0]
- Hardware: [e.g., MacBook Pro M1]

**Steps to Reproduce:**
1. Go to '...'
2. Click on '....'
3. See error

**Expected Behavior:**
A clear description of what you expected to happen.

**Actual Behavior:**
A clear description of what actually happened.

**Screenshots:**
If applicable, add screenshots to help explain your problem.

**Additional Context:**
- Network configuration details
- System routing table state
- Console logs (if relevant)
```

### Security Issues
**Do not report security issues publicly.** Email security@routex.app with:
- Detailed description of the vulnerability
- Steps to reproduce
- Potential impact assessment
- Suggested fix (if known)

## Feature Requests

### Feature Request Template
```markdown
**Is your feature request related to a problem?**
A clear description of what the problem is.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Alternative solutions or features you've considered.

**Additional context**
Any other context or screenshots about the feature request.

**Implementation Ideas**
If you have ideas about how this could be implemented.
```

### Feature Development Process
1. **Discussion**: Create an issue to discuss the feature
2. **Design**: Document the approach and get feedback
3. **Implementation**: Follow the development workflow
4. **Review**: Thorough review process
5. **Documentation**: Update user and developer docs

## Development Environment

### Recommended Tools
- **Xcode**: Latest stable version
- **Git**: Command line or GUI client
- **SwiftFormat**: Code formatting (optional)
- **SwiftLint**: Code style checking (optional)

### Useful Scripts
```bash
# Build project
./build.sh

# Run tests
./run_tests.sh

# Generate icons
cd ../IconGenerator && ./generate_icons.sh -a RouteX

# Clean build artifacts
rm -rf build/
```

## Architecture Guidelines

### Adding New Features
1. **Model Layer**: Update `RouteModel.swift` for data structures
2. **Business Logic**: Extend `RouteManager.swift` for system integration
3. **UI Layer**: Add/modify SwiftUI views
4. **Tests**: Add comprehensive test coverage

### Code Organization
- Keep SwiftUI views focused and small
- Extract complex logic to separate classes/structs
- Use extensions to organize related functionality
- Follow MVVM patterns where appropriate

### Performance Considerations
- Avoid expensive operations on the main thread
- Use appropriate data structures for performance
- Cache expensive calculations
- Monitor memory usage for large route tables

## Release Process

### Version Numbers
Follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist
- [ ] All tests pass
- [ ] Documentation updated
- [ ] Version number bumped
- [ ] Release notes prepared
- [ ] Security review completed
- [ ] Performance testing done

---

## Questions?

If you have questions about contributing:
- **Documentation**: Check existing docs first
- **Discussion**: Start a GitHub Discussion
- **Direct Contact**: Email the maintainers

Thank you for contributing to RouteX! 🚀 