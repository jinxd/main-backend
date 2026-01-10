import Vapor
import Foundation

actor HTMLCache {
    // Key: file path, Value: Processed HTML
    private var cache: [String: String] = [:]
    
    func get(filePath: String, cssPath: String) -> String? {
        // Return cached content if available
        if let cached = cache[filePath] {
            return cached
        }
        
        // Read and process new content
        guard let fileData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            return nil
        }
        
        var htmlString = String(decoding: fileData, as: UTF8.self)
        
        // Get CSS timestamp for cache busting
        if let cssAttributes = try? FileManager.default.attributesOfItem(atPath: cssPath),
           let cssDate = cssAttributes[.modificationDate] as? Date {
            let timeStamp = Int(cssDate.timeIntervalSince1970)
            htmlString = htmlString.replacingOccurrences(of: "/css/main.css", with: "/css/main.css?v=\(timeStamp)")
        }
        
        // Update cache
        cache[filePath] = htmlString
        
        return htmlString
    }
}
