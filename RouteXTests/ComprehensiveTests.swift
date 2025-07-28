import XCTest
@testable import RouteX

final class ComprehensiveTests: XCTestCase {
    
    var routeManager: RouteManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        routeManager = RouteManager()
    }
    
    override func tearDownWithError() throws {
        routeManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Core RouteManager Tests
    
    func testRouteManagerInitialization() {
        XCTAssertNotNil(routeManager, "RouteManager should initialize successfully")
    }
    
    func testIPAddressValidation() {
        // Valid IP addresses
        XCTAssertTrue(routeManager.isValidIPAddress("192.168.1.1"), "Valid IPv4 should pass validation")
        XCTAssertTrue(routeManager.isValidIPAddress("10.0.0.1"), "Valid IPv4 should pass validation")
        XCTAssertTrue(routeManager.isValidIPAddress("::1"), "Valid IPv6 should pass validation")
        XCTAssertTrue(routeManager.isValidIPAddress("fe80::1"), "Valid IPv6 should pass validation")
        
        // Invalid IP addresses
        XCTAssertFalse(routeManager.isValidIPAddress("notanip"), "Invalid IP should fail validation")
        XCTAssertFalse(routeManager.isValidIPAddress("256.256.256.256"), "Invalid IP should fail validation")
        XCTAssertFalse(routeManager.isValidIPAddress("192.168.1"), "Incomplete IP should fail validation")
    }
    
    func testInterfaceNameValidation() {
        // Valid interface names
        XCTAssertTrue(routeManager.isValidInterfaceName("en0"), "Valid interface name should pass validation")
        XCTAssertTrue(routeManager.isValidInterfaceName("en1"), "Valid interface name should pass validation")
        XCTAssertTrue(routeManager.isValidInterfaceName("lo0"), "Valid interface name should pass validation")
        
        // Invalid interface names
        XCTAssertFalse(routeManager.isValidInterfaceName(""), "Empty interface name should fail validation")
        XCTAssertFalse(routeManager.isValidInterfaceName("invalid"), "Invalid interface name should fail validation")
    }
    
    func testMACAddressValidation() {
        // Valid MAC addresses
        XCTAssertTrue(routeManager.isValidMACAddress("00:11:22:33:44:55"), "Valid MAC address should pass validation")
        XCTAssertTrue(routeManager.isValidMACAddress("AA:BB:CC:DD:EE:FF"), "Valid MAC address should pass validation")
        
        // Invalid MAC addresses
        XCTAssertFalse(routeManager.isValidMACAddress(""), "Empty MAC address should fail validation")
        XCTAssertFalse(routeManager.isValidMACAddress("invalid"), "Invalid MAC address should fail validation")
        XCTAssertFalse(routeManager.isValidMACAddress("00:11:22:33:44"), "Incomplete MAC address should fail validation")
    }
    
    func testGatewayTypeDetection() {
        // IP address gateway
        XCTAssertEqual(routeManager.gatewayType("192.168.1.1"), .ipAddress, "IP address should be detected as IP gateway")
        XCTAssertEqual(routeManager.gatewayType("10.0.0.1"), .ipAddress, "IP address should be detected as IP gateway")
        
        // Interface gateway
        XCTAssertEqual(routeManager.gatewayType("en0"), .iface, "Interface should be detected as interface gateway")
        XCTAssertEqual(routeManager.gatewayType("en1"), .iface, "Interface should be detected as interface gateway")
        
        // MAC address gateway
        XCTAssertEqual(routeManager.gatewayType("00:11:22:33:44:55"), .mac, "MAC address should be detected as MAC gateway")
        XCTAssertEqual(routeManager.gatewayType("AA:BB:CC:DD:EE:FF"), .mac, "MAC address should be detected as MAC gateway")
        
        // Special gateway
        XCTAssertEqual(routeManager.gatewayType("link#1"), .special, "Link gateway should be detected as special")
        // Note: "default" is not detected as special in current implementation
        XCTAssertEqual(routeManager.gatewayType("default"), .invalid, "Default gateway should be detected as invalid")
        
        // Invalid gateway
        XCTAssertEqual(routeManager.gatewayType("invalid"), .invalid, "Invalid gateway should be detected as invalid")
    }
    
    func testSpecialGatewayValidation() {
        // Valid special gateways
        XCTAssertTrue(routeManager.isSpecialGateway("link#1"), "Link gateway should be valid")
        XCTAssertTrue(routeManager.isSpecialGateway("link#2"), "Link gateway should be valid")
        // Note: "default" is not considered special in current implementation
        XCTAssertFalse(routeManager.isSpecialGateway("default"), "Default gateway should not be valid")
        
        // Invalid special gateways
        XCTAssertFalse(routeManager.isSpecialGateway("notspecial"), "Invalid special gateway should fail validation")
        XCTAssertFalse(routeManager.isSpecialGateway(""), "Empty special gateway should fail validation")
    }
    
    // MARK: - NetworkRoute Tests
    
    func testNetworkRouteCreation() {
        let route = NetworkRoute(
            destination: "192.168.1.0",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: "",
            routeType: .network,
            mtu: "1500",
            hopCount: "1",
            rtt: "",
            rttvar: "",
            sendpipe: "",
            recvpipe: "",
            ssthresh: ""
        )
        
        XCTAssertEqual(route.destination, "192.168.1.0", "Destination should be set correctly")
        XCTAssertEqual(route.gateway, "192.168.1.1", "Gateway should be set correctly")
        XCTAssertEqual(route.interface, "en0", "Interface should be set correctly")
        XCTAssertEqual(route.flags, "S", "Flags should be set correctly")
        XCTAssertEqual(route.routeType, .network, "Route type should be set correctly")
        XCTAssertEqual(route.mtu, "1500", "MTU should be set correctly")
        XCTAssertEqual(route.hopCount, "1", "Hop count should be set correctly")
    }
    
    func testRouteTypeEnum() {
        XCTAssertEqual(RouteType.auto.rawValue, "auto", "Auto route type should have correct raw value")
        XCTAssertEqual(RouteType.network.rawValue, "net", "Network route type should have correct raw value")
        XCTAssertEqual(RouteType.host.rawValue, "host", "Host route type should have correct raw value")
    }
    
    func testRouteFlagEnum() {
        XCTAssertEqual(RouteFlag.staticRoute.rawValue, "S", "Static route flag should have correct raw value")
        XCTAssertEqual(RouteFlag.reject.rawValue, "R", "Reject route flag should have correct raw value")
        XCTAssertEqual(RouteFlag.blackhole.rawValue, "b", "Blackhole route flag should have correct raw value")
        XCTAssertEqual(RouteFlag.llinfo.rawValue, "L", "Link info route flag should have correct raw value")
    }
    
    // MARK: - Command Generation Tests
    
    func testBasicRouteCommandGeneration() {
        let route = NetworkRoute(
            destination: "192.168.1.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )
        
        let command = routeManager.generateRouteCommand("add", route: route)
        
        XCTAssertTrue(command.contains("route add"), "Command should contain route add")
        XCTAssertTrue(command.contains("192.168.1.0/24"), "Command should contain destination")
        XCTAssertTrue(command.contains("192.168.1.1"), "Command should contain gateway")
    }
    
    func testDeleteRouteCommandGeneration() {
        let route = NetworkRoute(
            destination: "192.168.1.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )
        
        let command = routeManager.generateRouteCommand("delete", route: route)
        
        XCTAssertTrue(command.contains("route delete"), "Command should contain route delete")
        XCTAssertTrue(command.contains("192.168.1.0/24"), "Command should contain destination")
    }
    
    func testAdvancedOptionsCommandGeneration() {
        let route = NetworkRoute(
            destination: "192.168.1.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )
        
        let advancedOptions = [
            "mtu": "1500",
            "hopcount": "5"
        ]
        
        let command = routeManager.generateRouteCommand("add", route: route, advancedOptions: advancedOptions)
        
        XCTAssertTrue(command.contains("route add"), "Command should contain route add")
        XCTAssertTrue(command.contains("-mtu 1500"), "Command should include MTU")
        XCTAssertTrue(command.contains("-hopcount 5"), "Command should include hop count")
    }
    
    // MARK: - Route Validation Tests
    
    func testRouteValidation() {
        let validRoute = NetworkRoute(
            destination: "192.168.1.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )
        
        XCTAssertTrue(routeManager.validateRouteForCommand(validRoute, command: "add"), "Valid route should pass validation")
    }
    
    func testInvalidRouteValidation() {
        let invalidRoute = NetworkRoute(
            destination: "",  // Empty destination
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )
        
        XCTAssertFalse(routeManager.validateRouteForCommand(invalidRoute, command: "add"), "Invalid route should fail validation")
    }
    
    // MARK: - Destination Interpretation Tests
    
    func testDestinationInterpretation() {
        // Test network destination
        let networkInterpretation = NetworkRoute.interpretDestination("192.168.1.0/24")
        XCTAssertTrue(networkInterpretation.isValid, "Valid network destination should be interpreted correctly")
        XCTAssertEqual(networkInterpretation.interpretedType, .network, "Should be interpreted as network route")
        
        // Test host destination
        let hostInterpretation = NetworkRoute.interpretDestination("192.168.1.1")
        XCTAssertTrue(hostInterpretation.isValid, "Valid host destination should be interpreted correctly")
        XCTAssertEqual(hostInterpretation.interpretedType, .host, "Should be interpreted as host route")
        
        // Test invalid destination
        let invalidInterpretation = NetworkRoute.interpretDestination("")
        XCTAssertFalse(invalidInterpretation.isValid, "Invalid destination should fail interpretation")
    }
    
    // MARK: - Route Flag Tests
    
    func testRouteFlagDescriptions() {
        let descriptions = routeManager.getRouteFlagDescriptions()
        
        XCTAssertNotNil(descriptions["S"], "Static flag should have description")
        XCTAssertNotNil(descriptions["R"], "Reject flag should have description")
        XCTAssertNotNil(descriptions["b"], "Blackhole flag should have description")
        XCTAssertNotNil(descriptions["L"], "Link info flag should have description")
    }
    
    // MARK: - Metric Validation Tests
    
    func testMetricValidation() {
        // Valid metrics
        XCTAssertTrue(routeManager.validateMetric("1500", type: "MTU"), "Valid MTU should pass validation")
        XCTAssertTrue(routeManager.validateMetric("5", type: "Hop Count"), "Valid hop count should pass validation")
        XCTAssertTrue(routeManager.validateMetric("100", type: "RTT"), "Valid RTT should pass validation")
        
        // Invalid metrics
        XCTAssertFalse(routeManager.validateMetric("", type: "MTU"), "Empty metric should fail validation")
        XCTAssertFalse(routeManager.validateMetric("notanumber", type: "MTU"), "Non-numeric metric should fail validation")
        XCTAssertFalse(routeManager.validateMetric("-1", type: "MTU"), "Negative metric should fail validation")
    }
    
    // MARK: - Network Address Tests
    
    func testNetworkAddressValidation() {
        // Valid network addresses (IP addresses without CIDR)
        XCTAssertTrue(routeManager.validateNetworkAddress("192.168.1.0"), "Valid network address should pass validation")
        XCTAssertTrue(routeManager.validateNetworkAddress("10.0.0.0"), "Valid network address should pass validation")
        
        // Valid shorthand network addresses
        XCTAssertTrue(routeManager.validateNetworkAddress("192.168"), "Valid shorthand network address should pass validation")
        XCTAssertTrue(routeManager.validateNetworkAddress("10"), "Valid shorthand network address should pass validation")
        
        // Invalid network addresses
        XCTAssertFalse(routeManager.validateNetworkAddress(""), "Empty network address should fail validation")
        XCTAssertFalse(routeManager.validateNetworkAddress("notanetwork"), "Invalid network address should fail validation")
        XCTAssertFalse(routeManager.validateNetworkAddress("192.168.1.0/24"), "CIDR notation should fail validation")
    }
    
    func testCIDRValidation() {
        // Valid CIDR
        XCTAssertTrue(routeManager.validateCIDR("192.168.1.0/24"), "Valid CIDR should pass validation")
        XCTAssertTrue(routeManager.validateCIDR("10.0.0.0/16"), "Valid CIDR should pass validation")
        
        // Invalid CIDR
        XCTAssertFalse(routeManager.validateCIDR(""), "Empty CIDR should fail validation")
        XCTAssertFalse(routeManager.validateCIDR("192.168.1.0"), "Missing CIDR should fail validation")
        XCTAssertFalse(routeManager.validateCIDR("192.168.1.0/33"), "Invalid CIDR should fail validation")
    }
    
    // MARK: - IPv6 Tests
    
    func testIPv6Validation() {
        // Valid IPv6 addresses
        XCTAssertTrue(routeManager.isValidIPv6ForRouting("::1"), "Valid IPv6 should pass validation")
        XCTAssertTrue(routeManager.isValidIPv6ForRouting("fe80::1"), "Valid IPv6 should pass validation")
        XCTAssertTrue(routeManager.isValidIPv6ForRouting("2001:db8::1"), "Valid IPv6 should pass validation")
        
        // Invalid IPv6 addresses
        XCTAssertFalse(routeManager.isValidIPv6ForRouting(""), "Empty IPv6 should fail validation")
        XCTAssertFalse(routeManager.isValidIPv6ForRouting("notanipv6"), "Invalid IPv6 should fail validation")
    }
    
    func testIPv6Sanitization() {
        // Test IPv6 zone identifier removal
        XCTAssertEqual(routeManager.sanitizeIPv6Address("fe80::1%en0"), "fe80::1", "Zone identifier should be removed")
        XCTAssertEqual(routeManager.sanitizeIPv6Address("::1%lo0"), "::1", "Zone identifier should be removed")
        XCTAssertEqual(routeManager.sanitizeIPv6Address("2001:db8::1"), "2001:db8::1", "IPv6 without zone should remain unchanged")
    }
    
    // MARK: - Route Normalization Tests
    
    func testRouteDestinationNormalization() {
        // Test host route normalization
        let hostDestination = routeManager.normalizedRouteDestination("192.168.1.1", isHost: true)
        XCTAssertEqual(hostDestination, "192.168.1.1", "Host destination should remain unchanged")
        
        // Test network route normalization
        let networkDestination = routeManager.normalizedRouteDestination("192.168.1.0/24", isHost: false)
        XCTAssertEqual(networkDestination, "192.168.1.0/24", "Network destination should remain unchanged")
        
        // Test CIDR notation (should not be modified)
        let cidrDestination = routeManager.normalizedRouteDestination("10.0.0.0/24", isHost: false)
        XCTAssertEqual(cidrDestination, "10.0.0.0/24", "CIDR notation should remain unchanged")
    }
    
    // MARK: - Performance Tests
    
    func testRouteManagerPerformance() {
        measure {
            // Test RouteManager initialization performance
            let manager = RouteManager()
            _ = manager.isValidIPAddress("192.168.1.1")
            _ = manager.isValidInterfaceName("en0")
            _ = manager.isValidMACAddress("00:11:22:33:44:55")
        }
    }
    
    func testNetworkRouteCreationPerformance() {
        measure {
            // Test NetworkRoute creation performance
            for index in 0..<100 {
                _ = NetworkRoute(
                    destination: "192.168.\(index).0/24",
                    gateway: "192.168.\(index).1",
                    interface: "en0",
                    flags: "S",
                    expire: ""
                )
            }
        }
    }
    
    // MARK: - Integration Tests (Skipped by default)
    
    func testIntegration_AddRoute() throws {
        guard ProcessInfo.processInfo.environment["ROUTEX_INTEGRATION_TESTS"] == "1" else {
            throw XCTSkip("Integration test skipped unless ROUTEX_INTEGRATION_TESTS=1 is set.")
        }
        
        let testRoute = NetworkRoute(
            destination: "10.254.254.0/30", // Unlikely to conflict
            gateway: "127.0.0.1", // Loopback, safe for test
            interface: "lo0",
            flags: "S",
            expire: ""
        )
        
        let expectation = XCTestExpectation(description: "Add route completes")
        var success = false
        var error: String? = nil
        
        routeManager.addRoute(testRoute) { result, err in
            success = result
            error = err
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        if !success {
            XCTFail("Failed to add route: \(error ?? "Unknown error")")
        }
    }
    
    static var allTests = [
        ("testRouteManagerInitialization", testRouteManagerInitialization),
        ("testIPAddressValidation", testIPAddressValidation),
        ("testInterfaceNameValidation", testInterfaceNameValidation),
        ("testMACAddressValidation", testMACAddressValidation),
        ("testGatewayTypeDetection", testGatewayTypeDetection),
        ("testSpecialGatewayValidation", testSpecialGatewayValidation),
        ("testNetworkRouteCreation", testNetworkRouteCreation),
        ("testRouteTypeEnum", testRouteTypeEnum),
        ("testRouteFlagEnum", testRouteFlagEnum),
        ("testBasicRouteCommandGeneration", testBasicRouteCommandGeneration),
        ("testDeleteRouteCommandGeneration", testDeleteRouteCommandGeneration),
        ("testAdvancedOptionsCommandGeneration", testAdvancedOptionsCommandGeneration),
        ("testRouteValidation", testRouteValidation),
        ("testInvalidRouteValidation", testInvalidRouteValidation),
        ("testDestinationInterpretation", testDestinationInterpretation),
        ("testRouteFlagDescriptions", testRouteFlagDescriptions),
        ("testMetricValidation", testMetricValidation),
        ("testNetworkAddressValidation", testNetworkAddressValidation),
        ("testCIDRValidation", testCIDRValidation),
        ("testIPv6Validation", testIPv6Validation),
        ("testIPv6Sanitization", testIPv6Sanitization),
        ("testRouteDestinationNormalization", testRouteDestinationNormalization),
        ("testRouteManagerPerformance", testRouteManagerPerformance),
        ("testNetworkRouteCreationPerformance", testNetworkRouteCreationPerformance),
        ("testIntegration_AddRoute", testIntegration_AddRoute)
    ]
} 
