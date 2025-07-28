import XCTest
@testable import RouteX

final class BasicFunctionalityTests: XCTestCase {
    
    func testRouteManagerInitialization() {
        // Test that RouteManager can be initialized
        let routeManager = RouteManager()
        XCTAssertNotNil(routeManager, "RouteManager should initialize successfully")
    }
    
    func testNetworkRouteCreation() {
        // Test that NetworkRoute can be created
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
    }
    
    func testRouteTypeEnum() {
        // Test RouteType enum values
        XCTAssertEqual(RouteType.auto.rawValue, "auto", "Auto route type should have correct raw value")
        XCTAssertEqual(RouteType.network.rawValue, "net", "Network route type should have correct raw value")
        XCTAssertEqual(RouteType.host.rawValue, "host", "Host route type should have correct raw value")
    }
    
    func testRouteFlagEnum() {
        // Test RouteFlag enum values
        XCTAssertEqual(RouteFlag.staticRoute.rawValue, "S", "Static route flag should have correct raw value")
        XCTAssertEqual(RouteFlag.reject.rawValue, "R", "Reject route flag should have correct raw value")
        XCTAssertEqual(RouteFlag.blackhole.rawValue, "b", "Blackhole route flag should have correct raw value")
        XCTAssertEqual(RouteFlag.llinfo.rawValue, "L", "Link info route flag should have correct raw value")
    }
    
    func testIPAddressValidation() {
        let routeManager = RouteManager()
        
        // Test valid IP addresses
        XCTAssertTrue(routeManager.isValidIPAddress("192.168.1.1"), "Valid IPv4 should pass validation")
        XCTAssertTrue(routeManager.isValidIPAddress("10.0.0.1"), "Valid IPv4 should pass validation")
        XCTAssertTrue(routeManager.isValidIPAddress("::1"), "Valid IPv6 should pass validation")
        XCTAssertTrue(routeManager.isValidIPAddress("fe80::1"), "Valid IPv6 should pass validation")
        
        // Test invalid IP addresses
        XCTAssertFalse(routeManager.isValidIPAddress("notanip"), "Invalid IP should fail validation")
        XCTAssertFalse(routeManager.isValidIPAddress("256.256.256.256"), "Invalid IP should fail validation")
        XCTAssertFalse(routeManager.isValidIPAddress("192.168.1"), "Incomplete IP should fail validation")
    }
    
    func testInterfaceNameValidation() {
        let routeManager = RouteManager()
        
        // Test valid interface names
        XCTAssertTrue(routeManager.isValidInterfaceName("en0"), "Valid interface name should pass validation")
        XCTAssertTrue(routeManager.isValidInterfaceName("en1"), "Valid interface name should pass validation")
        XCTAssertTrue(routeManager.isValidInterfaceName("lo0"), "Valid interface name should pass validation")
        
        // Test invalid interface names
        XCTAssertFalse(routeManager.isValidInterfaceName(""), "Empty interface name should fail validation")
        XCTAssertFalse(routeManager.isValidInterfaceName("invalid"), "Invalid interface name should fail validation")
    }
    
    func testMACAddressValidation() {
        let routeManager = RouteManager()
        
        // Test valid MAC addresses
        XCTAssertTrue(routeManager.isValidMACAddress("00:11:22:33:44:55"), "Valid MAC address should pass validation")
        XCTAssertTrue(routeManager.isValidMACAddress("AA:BB:CC:DD:EE:FF"), "Valid MAC address should pass validation")
        
        // Test invalid MAC addresses
        XCTAssertFalse(routeManager.isValidMACAddress(""), "Empty MAC address should fail validation")
        XCTAssertFalse(routeManager.isValidMACAddress("invalid"), "Invalid MAC address should fail validation")
        XCTAssertFalse(routeManager.isValidMACAddress("00:11:22:33:44"), "Incomplete MAC address should fail validation")
    }
    
    func testDestinationInterpretation() {
        // Test destination interpretation
        let interpretation1 = NetworkRoute.interpretDestination("192.168.1.0")
        XCTAssertTrue(interpretation1.isValid, "Valid destination should be interpreted correctly")
        XCTAssertEqual(interpretation1.interpretedType, .host, "Should be interpreted as host route")
        
        let interpretation2 = NetworkRoute.interpretDestination("10.0.0.1")
        XCTAssertTrue(interpretation2.isValid, "Valid destination should be interpreted correctly")
        XCTAssertEqual(interpretation2.interpretedType, .host, "Should be interpreted as host route")
    }
    
    static var allTests = [
        ("testRouteManagerInitialization", testRouteManagerInitialization),
        ("testNetworkRouteCreation", testNetworkRouteCreation),
        ("testRouteTypeEnum", testRouteTypeEnum),
        ("testRouteFlagEnum", testRouteFlagEnum),
        ("testIPAddressValidation", testIPAddressValidation),
        ("testInterfaceNameValidation", testInterfaceNameValidation),
        ("testMACAddressValidation", testMACAddressValidation),
        ("testDestinationInterpretation", testDestinationInterpretation)
    ]
} 