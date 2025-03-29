import Vapor
import Leaf

// configures your application
public func configure(_ app: Application) async throws {
    let publicDirectory = app.directory.publicDirectory
    app.middleware.use(FileMiddleware(publicDirectory: publicDirectory, defaultFile: "index"))
    app.views.use(.leaf)
    try await routes(app)
}
