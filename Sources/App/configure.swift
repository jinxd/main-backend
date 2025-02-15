import Vapor
import Leaf

// configures your application
public func configure(_ app: Application) async throws {
    let publicDirectory = app.directory.publicDirectory
    let fileMiddleware = FileMiddleware(publicDirectory: publicDirectory)
    let excludedPaths = [
        "/ghost/game/create",
        "/ghost/game/findEmptyPlayer2Id",
        "/ghost/game/join",
        "/ghost/game",
        "/ghost/subscribe/game",
        "/superghost/game",
        "/superghost/private",
        "/superghost/subscribe/game",
        "/api/"
    ]
    let customFileMiddleware = CustomFileMiddleware(fileMiddleware: fileMiddleware, excludedPaths: excludedPaths)

    app.middleware.use(customFileMiddleware)
    app.views.use(.leaf)
    try await routes(app)
}
struct CustomFileMiddleware: AsyncMiddleware {
    let fileMiddleware: FileMiddleware
    let excludedPaths: [String]

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Check if the request path matches any of the excluded paths
        if excludedPaths.contains(where: { request.url.path.hasPrefix($0) }) {
            return try await next.respond(to: request)
        }
        // Otherwise, use the file middleware to serve files
        return try await fileMiddleware.respond(to: request, chainingTo: next)
    }
}
