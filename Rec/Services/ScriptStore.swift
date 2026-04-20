import Foundation
import SwiftData

// ScriptStore utility for batch operations on scripts.
// Individual CRUD is handled by SwiftData's ModelContext directly.

enum ScriptStore {
    static func createSampleScripts(in context: ModelContext) {
        let sample1 = Script(
            title: "Welcome to Rec",
            content: """
            Welcome to Rec, your personal teleprompter for Mac.

            This is a sample script to help you get started. You can edit this text, \
            adjust the scroll speed, and customize the appearance to match your needs.

            Try pressing Command+Return to start the teleprompter. \
            The text will scroll smoothly near your Mac's notch, \
            so your eyes stay close to the camera.

            You can also enable Voice Tracking in the toolbar menu \
            to have the scroll speed match your speaking pace automatically.

            Happy recording!
            """
        )

        let sample2 = Script(
            title: "Presentation Notes",
            content: """
            Good morning everyone, thank you for joining today's presentation.

            Today I'll be covering three main topics:

            First, our progress over the last quarter. \
            We've seen significant improvements in user engagement \
            and our key metrics are trending upward.

            Second, I'll walk through our roadmap for the next quarter. \
            We have several exciting features planned \
            that I think you'll be very interested in.

            And finally, I'd like to open the floor for questions \
            and discussion about our direction.

            Let's get started.
            """
        )

        context.insert(sample1)
        context.insert(sample2)
    }
}
