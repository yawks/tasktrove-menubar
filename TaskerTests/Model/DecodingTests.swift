import XCTest
@testable import Tasker

class DecodingTests: XCTestCase {

    var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()

        let dateFormatter = DateFormatter()
        // Custom date decoding strategy to handle multiple formats
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try ISO 8601 format with fractional seconds first
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            // Fallback to simple yyyy-MM-dd format
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        })
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    func testDecodeAPIResponse() throws {
        // 1. Use the static JSON data from MockData
        let data = Data(MockData.tasksJSON.utf8)

        // 2. Decode the data
        do {
            let response = try decoder.decode(APIResponse.self, from: data)

            // 4. Assert that the data was decoded correctly
            XCTAssertEqual(response.version, "v0.6.0")
            XCTAssertEqual(response.tasks.count, 1)
            XCTAssertEqual(response.projects.count, 1)
            XCTAssertEqual(response.labels.count, 2)

            // Check a few nested properties to be sure
            let firstTask = response.tasks.first
            XCTAssertEqual(firstTask?.title, "Multi collections et DMRag et fichiers uploadés")
            XCTAssertEqual(firstTask?.subtasks.count, 3)

            let firstProject = response.projects.first
            XCTAssertEqual(firstProject?.name, "Dydu")
            XCTAssertEqual(firstProject?.sections.count, 3)

        } catch {
            // If decoding fails, print the detailed error
            XCTFail("Decoding failed with error: \(error)")
        }
    }
}