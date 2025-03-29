import Vapor
import WebSocketKit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession{
    func data(from url: URL) async throws -> (Data, URLResponse){
        try await withCheckedThrowingContinuation{con in
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data, let response{
                    con.resume(returning: (data, response))
                }
                else if let error {
                    con.resume(throwing: error)
                }
                else
                {
                    con.resume(throwing: APIError.requestFailed)

                }
            }
            task.resume()
        }
    }
}


@SuperGameService
func routes(_ app: Application) throws {
    app.get("open", "*", "*") {req async throws in
        try await req.fileio.asyncStreamFile(at: app.directory.publicDirectory.appending("openapp"))
    }
}

