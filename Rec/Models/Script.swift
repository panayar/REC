import Foundation
import SwiftData

@Model
final class Script {
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date

    init(title: String = "Untitled Script", content: String = "") {
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
