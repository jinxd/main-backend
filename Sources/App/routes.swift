import Vapor
import Foundation

@SuperGameService
func routes(_ app: Application) throws {
    // Helper to serve files with text/html content type
    func serveHTML(at path: String, req: Request) async throws -> Response {
        let response = try await req.fileio.asyncStreamFile(at: path)
        response.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
        return response
    }

    let publicDir = app.directory.publicDirectory

    // Handle root
    app.get { req in
        try await serveHTML(at: publicDir.appending("index"), req: req)
    }

    // Handle home explicitly as it's the main entry point
    app.get("home") { req in
        try await serveHTML(at: publicDir.appending("home"), req: req)
    }

    // Handle openapp redirect with Clean URL
    app.get("openapp") { req in
        try await serveHTML(at: publicDir.appending("openapp"), req: req)
    }

    // Handle old openapp route if needed (keeping compatibility)
    app.get("open", "*", "*") { req in
        try await serveHTML(at: publicDir.appending("openapp"), req: req)
    }

    // Catch-all for top-level extensionless files
    app.get(":page") { req -> Response in
        let page = req.parameters.get("page")!
        let path = publicDir.appending(page)
        
        // Simple check if it's a file without extension in Public
        if FileManager.default.fileExists(atPath: path) && !page.contains(".") {
            return try await serveHTML(at: path, req: req)
        }
        
        throw Abort(.notFound)
    }

    // Handle subdirectories (containeye, ghost, recipes)
    let components = ["containeye", "ghost", "recipes"]
    for component in components {
        app.get(PathComponent(stringLiteral: component), ":subpage") { req -> Response in
            let subpage = req.parameters.get("subpage")!
            let path = publicDir.appending("\(component)/\(subpage)")
            
            if FileManager.default.fileExists(atPath: path) && !subpage.contains(".") {
                return try await serveHTML(at: path, req: req)
            }
            throw Abort(.notFound)
        }
    }
}
