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
            print("[HTMLCache] Failed to read file at: \(filePath)")
            return nil
        }
        
        var htmlString = String(decoding: fileData, as: UTF8.self)
        
        // Get CSS timestamp for cache busting
        print("[HTMLCache] Checking CSS at: \(cssPath)")
        do {
            let cssAttributes = try FileManager.default.attributesOfItem(atPath: cssPath)
            if let cssDate = cssAttributes[.modificationDate] as? Date {
                let timeStamp = Int(cssDate.timeIntervalSince1970)
                print("[HTMLCache] CSS Timestamp: \(timeStamp)")
                let original = htmlString
                htmlString = htmlString.replacingOccurrences(of: "/css/main.css", with: "/css/main.css?v=\(timeStamp)")
                if original != htmlString {
                     print("[HTMLCache] Replacement SUCCESS")
                } else {
                     print("[HTMLCache] Replacement FAILED - String not found?")
                }
            }
        } catch {
            print("[HTMLCache] Failed to get CSS attributes: \(error)")
        }
        
        // Update cache
        cache[filePath] = htmlString
        
        return htmlString
    }
}
