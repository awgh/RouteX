import XCTest
@testable import RouteX

final class RouteModelTests: XCTestCase {

    // MARK: - NetworkRoute Initialization Tests

    func testNetworkRouteInitialization() throws {
        // Given
        let destination = "10.1.2.0/24"
        let gateway = "192.168.1.1"
        let interface = "en0"
        let flags = "S"
        let expire = "3600"

        // When
        let route = NetworkRoute(
            destination: destination,
            gateway: gateway,
            interface: interface,
            flags: flags,
            expire: expire
        )

        // Then
        XCTAssertEqual(route.destination, destination, "Destination should be set correctly")
        XCTAssertEqual(route.gateway, gateway, "Gateway should be set correctly")
        XCTAssertEqual(route.interface, interface, "Interface should be set correctly")
        XCTAssertEqual(route.flags, flags, "Flags should be set correctly")
        XCTAssertEqual(route.expire, expire, "Expire should be set correctly")
    }

    func testNetworkRouteWithAdvancedProperties() throws {
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

        // Then
        XCTAssertEqual(route.mtu, "1500", "MTU should be set correctly")
        XCTAssertEqual(route.hopCount, "5", "Hop count should be set correctly")
        XCTAssertEqual(route.rtt, "100", "RTT should be set correctly")
        XCTAssertEqual(route.rttvar, "10", "RTT variance should be set correctly")
        XCTAssertEqual(route.sendpipe, "4096", "Send pipe should be set correctly")
        XCTAssertEqual(route.recvpipe, "4096", "Receive pipe should be set correctly")
        XCTAssertEqual(route.ssthresh, "1000", "Slow start threshold should be set correctly")
    }

    // MARK: - Display Properties Tests

    func testDisplayGatewayForIPAddress() throws {
        // Given
        let route = NetworkRoute(
            destination: "10.1.2.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When & Then
        XCTAssertEqual(route.displayGateway, "192.168.1.1", "IP gateway should be displayed as-is")
        XCTAssertEqual(route.gatewayTypeDescription, "IP Address: 192.168.1.1", "IP gateway should have correct description")
    }

    func testDisplayGatewayForInterface() throws {
        // Given
        let route = NetworkRoute(
            destination: "10.2.3.0/24",
            gateway: "en0",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When & Then
        XCTAssertEqual(route.displayGateway, "", "Interface gateway should display as empty")
        XCTAssertEqual(route.gatewayTypeDescription, "Interface: en0", "Interface gateway should have correct description")
    }

    func testDisplayGatewayForMACAddress() throws {
        // Given
        let route = NetworkRoute(
            destination: "10.3.4.0/24",
            gateway: "00:11:22:33:44:55",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When & Then
        XCTAssertEqual(route.displayGateway, "", "MAC gateway should display as empty")
        XCTAssertEqual(route.gatewayTypeDescription, "MAC Address: 00:11:22:33:44:55", "MAC gateway should have correct description")
    }

    func testDisplayGatewayForSpecialGateway() throws {
        // Given
        let route = NetworkRoute(
            destination: "default",
            gateway: "link#1",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When & Then
        XCTAssertEqual(route.displayGateway, "", "Special gateway should display as empty")
        XCTAssertEqual(route.gatewayTypeDescription, "Special: link#1", "Special gateway should have correct description")
    }

    // MARK: - Route Parsing Tests

    func testParseNetstatOutput() throws {
        // Given - Sample netstat output line
        let netstatLine = "default            192.168.1.1        UGSc           en0"

        // When
        let route = NetworkRoute.parse(from: netstatLine)

        // Then
        XCTAssertNotNil(route, "Route should be parsed successfully")
        if let route = route {
            XCTAssertEqual(route.destination, "default", "Destination should be parsed correctly")
            XCTAssertEqual(route.gateway, "192.168.1.1", "Gateway should be parsed correctly")
            XCTAssertEqual(route.interface, "en0", "Interface should be parsed correctly")
            XCTAssertEqual(route.flags, "UGSc", "Flags should be parsed correctly")
        }
    }

    func testParseNetstatOutputWithInterfaceGateway() throws {
        // Given - Sample netstat output line with interface gateway
        let netstatLine = "10.1.2.0/24         en0               USc            en0"

        // When
        let route = NetworkRoute.parse(from: netstatLine)

        // Then
        XCTAssertNotNil(route, "Route with interface gateway should be parsed successfully")
        if let route = route {
            XCTAssertEqual(route.destination, "10.1.2.0/24", "Destination should be parsed correctly")
            XCTAssertEqual(route.gateway, "en0", "Interface gateway should be parsed correctly")
            XCTAssertEqual(route.interface, "en0", "Interface should be parsed correctly")
        }
    }

    func testParseNetstatOutputWithMACGateway() throws {
        // Given - Sample netstat output line with MAC gateway
        let netstatLine = "10.2.3.0/24         00:11:22:33:44:55 USc            en0"

        // When
        let route = NetworkRoute.parse(from: netstatLine)

        // Then
        XCTAssertNotNil(route, "Route with MAC gateway should be parsed successfully")
        if let route = route {
            XCTAssertEqual(route.destination, "10.2.3.0/24", "Destination should be parsed correctly")
            XCTAssertEqual(route.gateway, "00:11:22:33:44:55", "MAC gateway should be parsed correctly")
            XCTAssertEqual(route.interface, "en0", "Interface should be parsed correctly")
        }
    }

    func testParseInvalidNetstatOutput() throws {
        // Given - Invalid netstat output line
        let invalidLine = "invalid line"

        // When
        let route = NetworkRoute.parse(from: invalidLine)

        // Then
        XCTAssertNil(route, "Invalid netstat output should return nil")
    }

    func testParseEmptyNetstatOutput() throws {
        // Given - Empty netstat output line
        let emptyLine = ""

        // When
        let route = NetworkRoute.parse(from: emptyLine)

        // Then
        XCTAssertNil(route, "Empty netstat output should return nil")
    }

    // MARK: - IP Address Parsing Tests

    func testParseIPAddressRightPadding() throws {
        // Test network route parsing (right-padding)
        XCTAssertEqual(NetworkRoute().parseIPAddress(from: "192.168"), "192.168.0.0", "Network shorthand should be right-padded")
        XCTAssertEqual(NetworkRoute().parseIPAddress(from: "10.1.2"), "10.1.2.0", "Network shorthand should be right-padded")
        XCTAssertEqual(NetworkRoute().parseIPAddress(from: "172.16"), "172.16.0.0", "Network shorthand should be right-padded")
    }

    func testParseHostAddressLeftPadding() throws {
        // Test host route parsing (left-padding)
        XCTAssertEqual(NetworkRoute().parseHostAddressLeftPad("128.32"), "128.0.0.32", "Host shorthand should be left-padded")
        XCTAssertEqual(NetworkRoute().parseHostAddressLeftPad("128.32.130"), "128.32.0.130", "Host shorthand should be left-padded")
        XCTAssertEqual(NetworkRoute().parseHostAddressLeftPad("192.168.1"), "192.168.0.1", "Host shorthand should be left-padded")
    }

    func testParseFullIPAddresses() throws {
        // Test full IP addresses (should remain unchanged)
        XCTAssertEqual(NetworkRoute().parseIPAddress(from: "192.168.1.1"), "192.168.1.1", "Full IP should remain unchanged")
        XCTAssertEqual(NetworkRoute().parseHostAddressLeftPad("192.168.1.1"), "192.168.1.1", "Full IP should remain unchanged")
        XCTAssertEqual(NetworkRoute().parseIPAddress(from: "10.0.0.1"), "10.0.0.1", "Full IP should remain unchanged")
    }

    func testParseInvalidIPAddresses() throws {
        // Test invalid IP addresses
        XCTAssertNil(NetworkRoute().parseIPAddress(from: "notanip"), "Invalid IP should return nil")
        XCTAssertNil(NetworkRoute().parseIPAddress(from: "256.256.256.256"), "Invalid IP should return nil")
        XCTAssertNil(NetworkRoute().parseIPAddress(from: "192.168.1"), "Incomplete IP should return nil")

        XCTAssertNil(NetworkRoute().parseHostAddressLeftPad("notanip"), "Invalid IP should return nil")
        XCTAssertNil(NetworkRoute().parseHostAddressLeftPad("256.256.256.256"), "Invalid IP should return nil")
    }

    // MARK: - Route Flags Tests

    func testRouteFlagsParsing() throws {
        // Test various flag combinations
        let flags1 = "UGSc"
        let flags2 = "USc"
        let flags3 = "S"

        // These should parse without errors
        XCTAssertNotNil(flags1, "Flags should be parsed correctly")
        XCTAssertNotNil(flags2, "Flags should be parsed correctly")
        XCTAssertNotNil(flags3, "Flags should be parsed correctly")
    }

    // MARK: - Route Equality Tests

    func testRouteEquality() throws {
        // Given
        let route1 = NetworkRoute(
            destination: "10.1.2.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        let route2 = NetworkRoute(
            destination: "10.1.2.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        let route3 = NetworkRoute(
            destination: "10.2.3.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "S",
            expire: ""
        )

        // When & Then
        XCTAssertEqual(route1.destination, route2.destination, "Routes with same destination should be equal")
        XCTAssertEqual(route1.gateway, route2.gateway, "Routes with same gateway should be equal")
        XCTAssertNotEqual(route1.destination, route3.destination, "Routes with different destinations should not be equal")
    }

    // MARK: - Route Copy Tests

    func testRouteCopying() throws {
        // Given
        let originalRoute = NetworkRoute(
            destination: "10.1.2.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
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

        // When - Create a copy and modify it
        var copiedRoute = originalRoute
        copiedRoute.destination = "10.2.3.0/24"
        copiedRoute.mtu = "1400"

        // Then
        XCTAssertNotEqual(originalRoute.destination, copiedRoute.destination, "Modified copy should have different destination")
        XCTAssertNotEqual(originalRoute.mtu, copiedRoute.mtu, "Modified copy should have different MTU")

        // Original should remain unchanged
        XCTAssertEqual(originalRoute.destination, "10.1.2.0/24", "Original route should remain unchanged")
        XCTAssertEqual(originalRoute.mtu, "1500", "Original route should remain unchanged")
    }

    // MARK: - Edge Cases Tests

    func testRouteWithEmptyFields() throws {
        // Given
        let route = NetworkRoute(
            destination: "",
            gateway: "",
            interface: "",
            flags: "",
            expire: ""
        )

        // When & Then
        XCTAssertEqual(route.destination, "", "Empty destination should be preserved")
        XCTAssertEqual(route.gateway, "", "Empty gateway should be preserved")
        XCTAssertEqual(route.interface, "", "Empty interface should be preserved")
        XCTAssertEqual(route.flags, "", "Empty flags should be preserved")
        XCTAssertEqual(route.expire, "", "Empty expire should be preserved")
    }

    func testRouteWithSpecialCharacters() throws {
        // Given
        let route = NetworkRoute(
            destination: "10.1.2.0/24",
            gateway: "192.168.1.1",
            interface: "en0",
            flags: "UGSc",
            expire: "3600"
        )

        // When & Then
        XCTAssertEqual(route.destination, "10.1.2.0/24", "Destination with special characters should be preserved")
        XCTAssertEqual(route.flags, "UGSc", "Flags with special characters should be preserved")
    }

    func testRouteWithVeryLongValues() throws {
        // Given - Test with maximum reasonable values
        let longDestination = "192.168.1.0/24"
        let longGateway = "192.168.1.1"
        let longInterface = "en0"
        let longFlags = "UGSc"
        let longExpire = "999999"

        let route = NetworkRoute(
            destination: longDestination,
            gateway: longGateway,
            interface: longInterface,
            flags: longFlags,
            expire: longExpire
        )

        // When & Then
        XCTAssertEqual(route.destination, longDestination, "Long destination should be preserved")
        XCTAssertEqual(route.gateway, longGateway, "Long gateway should be preserved")
        XCTAssertEqual(route.interface, longInterface, "Long interface should be preserved")
        XCTAssertEqual(route.flags, longFlags, "Long flags should be preserved")
        XCTAssertEqual(route.expire, longExpire, "Long expire should be preserved")
    }
}
