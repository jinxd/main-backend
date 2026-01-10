import Foundation

let fileManager = FileManager.default
let currentDir = "file:///Users/hannesnagel/Desktop/main-backend/"
let publicDir = "/Users/hannesnagel/Desktop/main-backend/Public/"
let cssRelPath = "css/main.css"
let cssPath = publicDir + cssRelPath

print("Checking path: \(cssPath)")

if fileManager.fileExists(atPath: cssPath) {
    print("File exists!")
    do {
        let attributes = try fileManager.attributesOfItem(atPath: cssPath)
        if let date = attributes[.modificationDate] as? Date {
            print("Modification date found: \(date)")
            let timeStamp = Int(date.timeIntervalSince1970)
            print("Timestamp: \(timeStamp)")
            
            let html = "<link rel=\"stylesheet\" href=\"/css/main.css\">"
            let replaced = html.replacingOccurrences(of: "/css/main.css", with: "/css/main.css?v=\(timeStamp)")
            print("Original: \(html)")
            print("Replaced: \(replaced)")
        } else {
            print("No modification date found.")
        }
    } catch {
        print("Error getting attributes: \(error)")
    }
} else {
    print("File DOES NOT exist at path.")
}
