# RouteX Unit Test Suite

This directory contains comprehensive unit tests for the RouteX application, covering end-to-end route creation and editing functionality.

## Test Structure

### Test Files

1. **`RouteManagerTests.swift`** - Tests for the core route management functionality
2. **`AddRouteViewTests.swift`** - Tests for the UI form validation and route editing
3. **`RouteModelTests.swift`** - Tests for the data model and parsing functionality

### Test Categories

#### Route Creation Tests
- ✅ Basic route creation with IP gateway
- ✅ Route creation with all advanced properties (MTU, hop count, RTT, etc.)
- ✅ Route creation with interface gateway
- ✅ Route creation with MAC address gateway
- ✅ Route creation with special gateway types (link#, default)

#### Route Editing Tests
- ✅ Editing routes with advanced properties
- ✅ Changing gateway types (IP → Interface, etc.)
- ✅ Editing routes without making changes (should not error)
- ✅ Preserving advanced properties during editing

#### Error Handling Tests
- ✅ Invalid gateway validation
- ✅ Empty field validation
- ✅ Invalid advanced property values
- ✅ Error message generation and display

#### Gateway Type Detection Tests
- ✅ IP address detection and validation
- ✅ Interface name detection and validation
- ✅ MAC address detection and validation
- ✅ Special gateway detection and validation

#### IP Address Parsing Tests
- ✅ Network route parsing (right-padding for shorthand)
- ✅ Host route parsing (left-padding for shorthand)
- ✅ Full IP address handling
- ✅ Invalid IP address rejection

#### Command Generation Tests
- ✅ Route add commands with different gateway types
- ✅ Route delete commands
- ✅ Route change commands
- ✅ Advanced options inclusion in commands

## Running the Tests

### Option 1: Using the Test Runner Script (Recommended)

```bash
./run_tests.sh
```

This script provides a comprehensive test suite that validates:
- Test file structure
- Basic functionality validation
- Integration tests
- Error handling tests

### Option 2: Using Xcode (Full XCTest Framework)

1. Open `RouteX.xcodeproj` in Xcode
2. Add a new Unit Testing Bundle target:
   - Right-click on the project in the navigator
   - Select "New Target"
   - Choose "Unit Testing Bundle" under macOS
   - Name it "RouteXTests"
3. Add the test files to the target
4. Run tests using `⌘+U` or Product → Test

### Option 3: Using xcodebuild

```bash
xcodebuild test -project RouteX.xcodeproj -scheme RouteX -destination 'platform=macOS'
```

## Test Coverage

### RouteManager Tests

**Route Creation:**
- `testCreateBasicRouteWithIPGateway()` - Validates basic route creation with IP gateway
- `testCreateRouteWithAllAdvancedProperties()` - Tests route creation with all advanced options
- `testCreateRouteWithInterfaceGateway()` - Tests interface gateway handling
- `testCreateRouteWithMACGateway()` - Tests MAC address gateway handling
- `testCreateRouteWithSpecialGateway()` - Tests special gateway types

**Route Editing:**
- `testEditRouteWithAdvancedProperties()` - Tests editing advanced properties
- `testEditRouteGatewayType()` - Tests changing gateway types
- `testEditRouteWithoutChanges()` - Tests editing without modifications

**Error Handling:**
- `testInvalidGatewayValidation()` - Tests invalid gateway rejection
- `testEmptyDestinationValidation()` - Tests empty destination rejection
- `testEmptyGatewayValidation()` - Tests empty gateway rejection

**Gateway Type Detection:**
- `testGatewayTypeDetection()` - Tests all gateway type detection methods

**IP Address Parsing:**
- `testIPAddressParsing()` - Tests IP address parsing for networks and hosts
- `testRouteDestinationNormalization()` - Tests destination normalization

**Command Generation:**
- `testDeleteRouteCommand()` - Tests delete command generation
- `testChangeRouteCommand()` - Tests change command generation

### AddRouteView Tests

**Form Validation:**
- `testValidBasicRouteValidation()` - Tests basic form validation
- `testInvalidDestinationValidation()` - Tests invalid destination rejection
- `testValidGatewayTypes()` - Tests all valid gateway types
- `testInvalidGatewayTypes()` - Tests invalid gateway rejection

**Route Editing:**
- `testEditRouteWithIPGateway()` - Tests editing IP gateway routes
- `testEditRouteWithInterfaceGateway()` - Tests editing interface gateway routes
- `testEditRouteWithMACGateway()` - Tests editing MAC gateway routes
- `testEditRouteWithAdvancedProperties()` - Tests editing advanced properties

**Field Validation:**
- `testDestinationFieldValidation()` - Tests destination field validation
- `testGatewayFieldValidation()` - Tests gateway field validation
- `testInterfaceFieldValidation()` - Tests interface field validation

**Advanced Properties:**
- `testAdvancedPropertiesValidation()` - Tests advanced property validation

**Error Messages:**
- `testErrorMessageForInvalidGateway()` - Tests error message generation
- `testErrorMessageForEmptyFields()` - Tests empty field error handling

**Command Generation:**
- `testRouteCommandGenerationForDifferentGatewayTypes()` - Tests command generation for different gateway types
- `testRouteCommandGenerationWithAdvancedOptions()` - Tests advanced options in commands

### RouteModel Tests

**Initialization:**
- `testNetworkRouteInitialization()` - Tests basic route initialization
- `testNetworkRouteWithAdvancedProperties()` - Tests advanced properties initialization

**Display Properties:**
- `testDisplayGatewayForIPAddress()` - Tests IP gateway display
- `testDisplayGatewayForInterface()` - Tests interface gateway display
- `testDisplayGatewayForMACAddress()` - Tests MAC gateway display
- `testDisplayGatewayForSpecialGateway()` - Tests special gateway display

**Route Parsing:**
- `testParseNetstatOutput()` - Tests netstat output parsing
- `testParseNetstatOutputWithInterfaceGateway()` - Tests interface gateway parsing
- `testParseNetstatOutputWithMACGateway()` - Tests MAC gateway parsing
- `testParseInvalidNetstatOutput()` - Tests invalid output handling
- `testParseEmptyNetstatOutput()` - Tests empty output handling

**IP Address Parsing:**
- `testParseIPAddressRightPadding()` - Tests network route parsing
- `testParseHostAddressLeftPadding()` - Tests host route parsing
- `testParseFullIPAddresses()` - Tests full IP address handling
- `testParseInvalidIPAddresses()` - Tests invalid IP rejection

**Route Operations:**
- `testRouteFlagsParsing()` - Tests route flags parsing
- `testRouteEquality()` - Tests route equality comparison
- `testRouteCopying()` - Tests route copying and modification

**Edge Cases:**
- `testRouteWithEmptyFields()` - Tests empty field handling
- `testRouteWithSpecialCharacters()` - Tests special character handling
- `testRouteWithVeryLongValues()` - Tests long value handling

## Test Best Practices

### Naming Conventions
- Test methods follow the pattern: `test[WhatIsBeingTested]()`
- Use descriptive names that explain what is being tested
- Group related tests with MARK comments

### Test Structure
- Follow the Given-When-Then pattern:
  - **Given**: Set up the test data and conditions
  - **When**: Execute the code being tested
  - **Then**: Assert the expected outcomes

### Assertions
- Use specific assertions (`XCTAssertEqual`, `XCTAssertTrue`, etc.)
- Provide descriptive failure messages
- Test both positive and negative cases

### Test Isolation
- Each test should be independent
- Use `setUp()` and `tearDown()` for common initialization
- Avoid dependencies between tests

## Continuous Integration

The test suite is designed to run in CI/CD environments:

```bash
# Run tests in CI
./run_tests.sh

# Check exit code
if [ $? -eq 0 ]; then
    echo "All tests passed"
else
    echo "Some tests failed"
    exit 1
fi
```

## Troubleshooting

### Common Issues

1. **Test files not found**: Ensure all test files are in the `RouteXTests/` directory
2. **Compilation errors**: Check that the main RouteX source files are accessible
3. **Missing dependencies**: Ensure XCTest framework is available

### Debugging Tests

1. Run individual test files:
   ```bash
   swift RouteXTests/RouteManagerTests.swift
   ```

2. Add debug output to tests:
   ```swift
   print("Debug: \(variable)")
   ```

3. Use Xcode's test navigator for detailed test results

## Contributing

When adding new tests:

1. Follow the existing naming conventions
2. Add tests for both success and failure cases
3. Include edge cases and boundary conditions
4. Update this README with new test descriptions
5. Ensure tests are isolated and don't depend on external state

## References

- [Swift Unit Testing Best Practices](https://www.avanderlee.com/swift/unit-tests-best-practices/)
- [XCTest Framework Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Testing Guidelines](https://www.swiftanytime.com/blog/unit-testing-in-swift) 