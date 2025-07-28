import XCTest
@testable import RouteX

final class RouteManagerTests: XCTestCase {

    var routeManager: RouteManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        routeManager = RouteManager()
    }

    override func tearDownWithError() throws {
        routeManager = nil
        try super.tearDownWithError()
    }

    // MARK: - Route Creation Tests

    func testCreateBasicRouteWithIPGateway() throws {
        // Given
        let route = NetworkRoute(
            destination: "10.1.2.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When
        let isValid = routeManager.validateRouteForCommand(route, command: "add")
        let command = routeManager.generateRouteCommand("add", route: route)

        // Then
        XCTAssertTrue(isValid, "Basic IP route should validate")
        XCTAssertTrue(command.contains("route add 10.1.2.0/24 192.168.1.1"), "Command should contain correct route parameters")
        XCTAssertTrue(command.contains("-interface en0"), "Command should specify interface")
    }

    func testCreateRouteWithAllAdvancedProperties() throws {
        // Given
        let route = NetworkRoute(
            destination: "10.2.3.0/24",
            gateway: "192.168.1.1",
            interface: "en1",
            flags: "S",
            expire: "3600",
            mtu: "1500",
            hopCount: "5",
            rtt: "100",
            rttvar: "10",
            sendpipe: "4096",
            recvpipe: "4096",
            ssthresh: "1000"
        )

        let advancedOptions = [
            "mtu": "1500",
            "hopcount": "5",
            "rtt": "100",
            "rttvar": "10",
            "sendpipe": "4096",
            "recvpipe": "4096",
            "ssthresh": "1000"
        ]

        // When
        let isValid = routeManager.validateRouteForCommand(route, command: "add")
        let command = routeManager.generateRouteCommand("add", route: route, advancedOptions: advancedOptions)

        // Then
        XCTAssertTrue(isValid, "Advanced IP route should validate")
        XCTAssertTrue(command.contains("route add 10.2.3.0/24 192.168.1.1"), "Command should contain correct route parameters")
        XCTAssertTrue(command.contains("-interface en1"), "Command should specify interface")
        XCTAssertTrue(command.contains("-mtu 1500"), "Command should include MTU")
        XCTAssertTrue(command.contains("-hopcount 5"), "Command should include hop count")
        XCTAssertTrue(command.contains("-rtt 100"), "Command should include RTT")
        XCTAssertTrue(command.contains("-rttvar 10"), "Command should include RTT variance")
        XCTAssertTrue(command.contains("-sendpipe 4096"), "Command should include send pipe")
        XCTAssertTrue(command.contains("-recvpipe 4096"), "Command should include receive pipe")
        XCTAssertTrue(command.contains("-ssthresh 1000"), "Command should include slow start threshold")
    }

    func testCreateRouteWithInterfaceGateway() throws {
        // Given
        let route = NetworkRoute(
            destination: "10.3.4.0/24",
            gateway: "en0",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When
        let isValid = routeManager.validateRouteForCommand(route, command: "add")
        let command = routeManager.generateRouteCommand("add", route: route)

        // Then
        XCTAssertTrue(isValid, "Interface gateway route should validate")
        XCTAssertTrue(command.contains("route add 10.3.4.0/24 -interface en0"), "Command should use -interface modifier for interface gateway")
    }

    func testCreateRouteWithMACGateway() throws {
        // Given
        let route = NetworkRoute(
            destination: "10.4.5.0/24",
            gateway: "00:11:22:33:44:55",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When
        let isValid = routeManager.validateRouteForCommand(route, command: "add")
        let command = routeManager.generateRouteCommand("add", route: route)

        // Then
        XCTAssertTrue(isValid, "MAC gateway route should validate")
        XCTAssertTrue(command.contains("route add 10.4.5.0/24 -link 00:11:22:33:44:55"), "Command should use -link modifier for MAC gateway")
    }

    func testCreateRouteWithSpecialGateway() throws {
        // Given
        let route = NetworkRoute(
            destination: "default",
            gateway: "link#1",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When
        let isValid = routeManager.validateRouteForCommand(route, command: "add")
        let command = routeManager.generateRouteCommand("add", route: route)

        // Then
        XCTAssertTrue(isValid, "Special gateway route should validate")
        XCTAssertTrue(command.contains("route add default link#1"), "Command should handle special gateway without modifier")
    }

    // MARK: - Route Editing Tests

    func testEditRouteWithAdvancedProperties() throws {
        // Given - Start with a route that has advanced properties
        let originalRoute = NetworkRoute(
            destination: "10.5.6.0/24",
            gateway: "192.168.1.1",
            interface: "en1",
            flags: "S",
            expire: "3600",
            mtu: "1500",
            hopCount: "5",
            rtt: "100",
            rttvar: "10",
            sendpipe: "4096",
            recvpipe: "4096",
            ssthresh: "1000"
        )

        // When - Edit the route (simulate editing in UI)
        var editedRoute = originalRoute
        editedRoute.mtu = "1400"
        editedRoute.hopCount = "10"
        editedRoute.rtt = "200"

        let advancedOptions = [
            "mtu": "1400",
            "hopcount": "10",
            "rtt": "200",
            "rttvar": "10",
            "sendpipe": "4096",
            "recvpipe": "4096",
            "ssthresh": "1000"
        ]

        let isValid = routeManager.validateRouteForCommand(editedRoute, command: "add")
        let command = routeManager.generateRouteCommand("add", route: editedRoute, advancedOptions: advancedOptions)

        // Then
        XCTAssertTrue(isValid, "Edited advanced route should validate")
        XCTAssertTrue(command.contains("route add 10.5.6.0/24 192.168.1.1"), "Command should contain correct route parameters")
        XCTAssertTrue(command.contains("-mtu 1400"), "Command should include updated MTU")
        XCTAssertTrue(command.contains("-hopcount 10"), "Command should include updated hop count")
        XCTAssertTrue(command.contains("-rtt 200"), "Command should include updated RTT")
    }

    func testEditRouteGatewayType() throws {
        // Given - Start with IP gateway
        let originalRoute = NetworkRoute(
            destination: "10.6.7.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When - Change to interface gateway
        var editedRoute = originalRoute
        editedRoute.gateway = "en1"

        let isValid = routeManager.validateRouteForCommand(editedRoute, command: "add")
        let command = routeManager.generateRouteCommand("add", route: editedRoute)

        // Then
        XCTAssertTrue(isValid, "Route with changed gateway type should validate")
        XCTAssertTrue(command.contains("route add 10.6.7.0/24 -interface en1"), "Command should use -interface modifier for new gateway type")
    }

    func testEditRouteWithoutChanges() throws {
        // Given - A route that will be opened for editing but not changed
        let route = NetworkRoute(
            destination: "10.7.8.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When - "Edit" the route but don't change anything
        let isValid = routeManager.validateRouteForCommand(route, command: "add")
        let command = routeManager.generateRouteCommand("add", route: route)

        // Then - Should still be valid and generate correct command
        XCTAssertTrue(isValid, "Unchanged route should still validate")
        XCTAssertTrue(command.contains("route add 10.7.8.0/24 192.168.1.1"), "Command should be correct even without changes")
    }

    // MARK: - Error Handling Tests

    func testInvalidGatewayValidation() throws {
        // Given
        let route = NetworkRoute(
            destination: "10.8.9.0/24",
            gateway: "notagateway",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When
        let isValid = routeManager.validateRouteForCommand(route, command: "add")

        // Then
        XCTAssertFalse(isValid, "Route with invalid gateway should not validate")
    }

    func testEmptyDestinationValidation() throws {
        // Given
        let route = NetworkRoute(
            destination: "",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When
        let isValid = routeManager.validateRouteForCommand(route, command: "add")

        // Then
        XCTAssertFalse(isValid, "Route with empty destination should not validate")
    }

    func testEmptyGatewayValidation() throws {
        // Given
        let route = NetworkRoute(
            destination: "10.9.10.0/24",
            gateway: "",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When
        let isValid = routeManager.validateRouteForCommand(route, command: "add")

        // Then
        XCTAssertFalse(isValid, "Route with empty gateway should not validate")
    }

    // MARK: - Gateway Type Detection Tests

    func testGatewayTypeDetection() throws {
        // Test IP address detection
        XCTAssertEqual(routeManager.gatewayType("192.168.1.1"), .ip, "Valid IP should be detected as IP type")
        XCTAssertEqual(routeManager.gatewayType("10.0.0.1"), .ip, "Valid IP should be detected as IP type")

        // Test interface detection
        XCTAssertEqual(routeManager.gatewayType("en0"), .iface, "Interface name should be detected as interface type")
        XCTAssertEqual(routeManager.gatewayType("en1"), .iface, "Interface name should be detected as interface type")
        XCTAssertEqual(routeManager.gatewayType("lo0"), .iface, "Loopback interface should be detected as interface type")

        // Test MAC address detection
        XCTAssertEqual(routeManager.gatewayType("00:11:22:33:44:55"), .mac, "MAC address should be detected as MAC type")
        XCTAssertEqual(routeManager.gatewayType("aa:bb:cc:dd:ee:ff"), .mac, "MAC address should be detected as MAC type")

        // Test special gateway detection
        XCTAssertEqual(routeManager.gatewayType("link#1"), .special, "Link gateway should be detected as special type")
        XCTAssertEqual(routeManager.gatewayType("link#2"), .special, "Link gateway should be detected as special type")
        XCTAssertEqual(routeManager.gatewayType("default"), .special, "Default gateway should be detected as special type")

        // Test invalid gateway detection
        XCTAssertEqual(routeManager.gatewayType("notagateway"), .invalid, "Invalid gateway should be detected as invalid type")
        XCTAssertEqual(routeManager.gatewayType(""), .invalid, "Empty gateway should be detected as invalid type")
    }

    // MARK: - IP Address Parsing Tests

    func testIPAddressParsing() throws {
        // Test network route parsing (right-padding)
        XCTAssertEqual(NetworkRoute.parseIPAddress(from: "192.168"), "192.168.0.0", "Network shorthand should be right-padded")
        XCTAssertEqual(NetworkRoute.parseIPAddress(from: "10.1.2"), "10.1.2.0", "Network shorthand should be right-padded")

        // Test host route parsing (left-padding)
        let route = NetworkRoute()
        XCTAssertEqual(route.parseHostAddressLeftPad("128.32"), "128.0.0.32", "Host shorthand should be left-padded")
        XCTAssertEqual(route.parseHostAddressLeftPad("128.32.130"), "128.32.0.130", "Host shorthand should be left-padded")

        // Test full IP addresses
        XCTAssertEqual(NetworkRoute.parseIPAddress(from: "192.168.1.1"), "192.168.1.1", "Full IP should remain unchanged")
        XCTAssertEqual(route.parseHostAddressLeftPad("192.168.1.1"), "192.168.1.1", "Full IP should remain unchanged")
    }

    // MARK: - Route Destination Normalization Tests

    func testRouteDestinationNormalization() throws {
        // Test host route normalization (left-padding)
        let hostDestination = routeManager.normalizedRouteDestination("128.32", isHost: true)
        XCTAssertEqual(hostDestination, "128.0.0.32", "Host destination should be left-padded")

        // Test network route normalization (right-padding)
        let networkDestination = routeManager.normalizedRouteDestination("192.168", isHost: false)
        XCTAssertEqual(networkDestination, "192.168.0.0", "Network destination should be right-padded")

        // Test CIDR notation (should not be modified)
        let cidrDestination = routeManager.normalizedRouteDestination("10.0.0.0/24", isHost: false)
        XCTAssertEqual(cidrDestination, "10.0.0.0/24", "CIDR notation should remain unchanged")

        // Test full IP (should not be modified)
        let fullIPDestination = routeManager.normalizedRouteDestination("192.168.1.1", isHost: true)
        XCTAssertEqual(fullIPDestination, "192.168.1.1", "Full IP should remain unchanged")
    }

    // MARK: - Command Generation Tests

    func testDeleteRouteCommand() throws {
        // Given
        let route = NetworkRoute(
            destination: "10.10.11.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When
        let command = routeManager.generateRouteCommand("delete", route: route)

        // Then
        XCTAssertTrue(command.contains("route delete 10.10.11.0/24"), "Delete command should contain correct destination")
        XCTAssertTrue(command.contains("192.168.1.1"), "Delete command should contain gateway")
    }

    func testChangeRouteCommand() throws {
        // Given
        let route = NetworkRoute(
            destination: "10.11.12.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When
        let command = routeManager.generateRouteCommand("change", route: route)

        // Then
        XCTAssertTrue(command.contains("route change 10.11.12.0/24"), "Change command should contain correct destination")
        XCTAssertTrue(command.contains("192.168.1.1"), "Change command should contain gateway")
    }

    // MARK: - Integration/System Tests

    func testIntegration_AddAndDeleteRoute() throws {
        guard ProcessInfo.processInfo.environment["ROUTEX_INTEGRATION_TESTS"] == "1" else {
            throw XCTSkip("Integration test skipped unless ROUTEX_INTEGRATION_TESTS=1 is set.")
        }

        let testDestination = "10.254.254.0/30" // unlikely to conflict
        let testGateway = "127.0.0.1" // loopback, safe for test
        let testInterface = "lo0"
        let testFlags = "S"
        let testRoute = NetworkRoute(
            destination: testDestination,
            gateway: testGateway,
            interface: testInterface,
            flags: testFlags,
            expire: ""
        )
        let addExpectation = expectation(description: "Add route completes")
        var addSuccess = false
        var addError: String? = nil
        routeManager.addRoute(testRoute) { success, error in
            addSuccess = success
            addError = error
            addExpectation.fulfill()
        }
        wait(for: [addExpectation], timeout: 15)
        XCTAssertTrue(addSuccess, "Route should be added successfully. Error: \(addError ?? "none")")

        // Now delete the route
        let deleteExpectation = expectation(description: "Delete route completes")
        var deleteSuccess = false
        var deleteError: String? = nil
        routeManager.deleteRoute(testRoute) { success, error in
            deleteSuccess = success
            deleteError = error
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 15)
        XCTAssertTrue(deleteSuccess, "Route should be deleted successfully. Error: \(deleteError ?? "none")")
    }

    func testIntegration_AddEditDeleteRouteWithAdvancedFields() throws {
        guard ProcessInfo.processInfo.environment["ROUTEX_INTEGRATION_TESTS"] == "1" else {
            throw XCTSkip("Integration test skipped unless ROUTEX_INTEGRATION_TESTS=1 is set.")
        }
        let testDestination = "10.254.254.4/30" // another unlikely-to-conflict subnet
        let testGateway = "127.0.0.1"
        let testInterface = "lo0"
        let testFlags = "S"
        let testExpire = "3600"
        let testMTU = "1500"
        let testHopCount = "5"
        let testRTT = "100"
        let testRTTVar = "10"
        let testSendpipe = "4096"
        let testRecvpipe = "4096"
        let testSsthresh = "1000"
        let testRoute = NetworkRoute(
            destination: testDestination,
            gateway: testGateway,
            interface: testInterface,
            flags: testFlags,
            expire: testExpire,
            mtu: testMTU,
            hopCount: testHopCount,
            rtt: testRTT,
            rttvar: testRTTVar,
            sendpipe: testSendpipe,
            recvpipe: testRecvpipe,
            ssthresh: testSsthresh
        )
        // Add route with advanced fields
        let addExpectation = expectation(description: "Add advanced route completes")
        var addSuccess = false
        var addError: String? = nil
        routeManager.addRoute(testRoute, advancedOptions: ["mtu": testMTU, "hopcount": testHopCount, "rtt": testRTT, "rttvar": testRTTVar, "sendpipe": testSendpipe, "recvpipe": testRecvpipe, "ssthresh": testSsthresh]) { success, error in
            addSuccess = success
            addError = error
            addExpectation.fulfill()
        }
        wait(for: [addExpectation], timeout: 15)
        XCTAssertTrue(addSuccess, "Advanced route should be added successfully. Error: \(addError ?? "none")")
        // Edit the route: change advanced fields
        let editedMTU = "1400"
        let editedHopCount = "10"
        let editedRTT = "200"
        let editedAdvancedOptions = ["mtu": editedMTU, "hopcount": editedHopCount, "rtt": editedRTT, "rttvar": testRTTVar, "sendpipe": testSendpipe, "recvpipe": testRecvpipe, "ssthresh": testSsthresh]
        let editedRoute = NetworkRoute(
            destination: testDestination,
            gateway: testGateway,
            interface: testInterface,
            flags: testFlags,
            expire: testExpire,
            mtu: editedMTU,
            hopCount: editedHopCount,
            rtt: editedRTT,
            rttvar: testRTTVar,
            sendpipe: testSendpipe,
            recvpipe: testRecvpipe,
            ssthresh: testSsthresh
        )
        // Delete the original route (simulate edit)
        let deleteExpectation = expectation(description: "Delete advanced route completes")
        var deleteSuccess = false
        var deleteError: String? = nil
        routeManager.deleteRoute(testRoute) { success, error in
            deleteSuccess = success
            deleteError = error
            deleteExpectation.fulfill()
        }
        wait(for: [deleteExpectation], timeout: 15)
        XCTAssertTrue(deleteSuccess, "Advanced route should be deleted successfully before edit. Error: \(deleteError ?? "none")")
        // Add the edited route
        let editAddExpectation = expectation(description: "Add edited advanced route completes")
        var editAddSuccess = false
        var editAddError: String? = nil
        routeManager.addRoute(editedRoute, advancedOptions: editedAdvancedOptions) { success, error in
            editAddSuccess = success
            editAddError = error
            editAddExpectation.fulfill()
        }
        wait(for: [editAddExpectation], timeout: 15)
        XCTAssertTrue(editAddSuccess, "Edited advanced route should be added successfully. Error: \(editAddError ?? "none")")
        // Clean up: delete the edited route
        let finalDeleteExpectation = expectation(description: "Final delete of edited advanced route completes")
        var finalDeleteSuccess = false
        var finalDeleteError: String? = nil
        routeManager.deleteRoute(editedRoute) { success, error in
            finalDeleteSuccess = success
            finalDeleteError = error
            finalDeleteExpectation.fulfill()
        }
        wait(for: [finalDeleteExpectation], timeout: 15)
        XCTAssertTrue(finalDeleteSuccess, "Edited advanced route should be deleted successfully. Error: \(finalDeleteError ?? "none")")
    }

    func testGenerateRouteCommand() {
        let routeManager = RouteManager()

        let route = NetworkRoute(
            destination: "192.168.1.0/24",
            gateway: "10.0.0.1",
            interface: "en0",
            flags: "S",
            expire: "3600",
            routeType: .network,
            mtu: "1500",
            hopCount: "2",
            rtt: "10",
            rttvar: "5",
            sendpipe: "4096",
            recvpipe: "4096",
            ssthresh: "1000"
        )

        let advancedOptions: [String: String] = [
            "mtu": "1500",
            "hopcount": "2"
        ]

        let command = routeManager.generateRouteCommand("add", route: route, advancedOptions: advancedOptions)

        XCTAssertTrue(command.contains("/sbin/route"), "Command should include route executable")
        XCTAssertTrue(command.contains("add"), "Command should include add operation")
        XCTAssertTrue(command.contains("-mtu"), "Command should include MTU option")
        XCTAssertTrue(command.contains("1500"), "Command should include MTU value")
        XCTAssertTrue(command.contains("-hopcount"), "Command should include hop count option")
        XCTAssertTrue(command.contains("2"), "Command should include hop count value")
        XCTAssertTrue(command.contains("-static"), "Command should include static flag")
        XCTAssertTrue(command.contains("-net"), "Command should include network flag")
        XCTAssertTrue(command.contains("192.168.1.0/24"), "Command should include destination")
        XCTAssertTrue(command.contains("10.0.0.1"), "Command should include gateway")
    }
}
