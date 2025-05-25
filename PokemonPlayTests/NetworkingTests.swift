//
//  NetworkingTests.swift
//  PokemonPlayTests
//
//  Created on 5/25/25.

@testable import PokemonPlay
import XCTest

class MockURLProtocol: URLProtocol {
    static var stubResponseData: Data?

    override class func canInit(with _: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let data = MockURLProtocol.stubResponseData {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class NetworkingTests: XCTestCase {
    /// for Testing:
    func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    func testFetchPokemonData_returnsDecodedJSON() throws {
        // Given
        let mockJSON: [String: Any] = ["name": "pikachu"]
        let data = try JSONSerialization.data(withJSONObject: mockJSON, options: [])
        MockURLProtocol.stubResponseData = data
        let session = makeMockSession()

        let expectation = expectation(description: "Fetch completes")

        // When
        fetchPokemonData(name: "pikachu", session: session) { result in
            // Then
            switch result {
            case let .success(json):
                XCTAssertEqual(json["name"] as? String, "pikachu")
            case let .failure(error):
                XCTFail("Expected success, got error: \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testFetchPokemonData_returnsError() throws {
        // Given: No response data to simulate error
        MockURLProtocol.stubResponseData = nil
        let session = makeMockSession()

        let expectation = expectation(description: "Fetch fails")

        // When
        fetchPokemonData(name: "pikachu", session: session) { result in
            // Then
            switch result {
            case .success:
                XCTFail("Expected failure, but got success")
            case let .failure(error):
                XCTAssertNotNil(error, "Expected an error to be returned")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
