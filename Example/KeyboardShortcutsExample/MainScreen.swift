import SwiftUI
import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut")
	static let testShortcut2 = Self("testShortcut2")
	static let testShortcut3 = Self("testShortcut3")
}

struct MainScreen: View {
	@Environment(\.colorScheme) var colorScheme
    @State private var selectedField: KeyboardShortcuts.Name?

    var body: some View {
		VStack(spacing: 0) {
			KeyboardShortcutRecorder(
				for: .testShortcut1,
				label: "Test Shortcut",
				focused: $selectedField
			)
			.background(Color(nsColor: .alternatingContentBackgroundColors[1]).opacity(0.75).padding(.horizontal, -12))
			
			KeyboardShortcutRecorder(
				for: .testShortcut2,
				label: "Test Shortcut 2",
				focused: $selectedField
			)

			KeyboardShortcutRecorder(
				for: .testShortcut3,
				label: "Test Shortcut 3",
				focused: $selectedField
			)
			.background(Color(nsColor: .alternatingContentBackgroundColors[1]).opacity(0.75).padding(.horizontal, -12))
		}
		.background(.regularMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 6))
		.overlay(
			RoundedRectangle(cornerRadius: 6)
				.stroke(Color(nsColor: .separatorColor), lineWidth: 0.75)
				.opacity(colorScheme == .dark ? 1 : 0.5)
				)
        .frame(width: 400, height: 72)
		.task {
			for await event in KeyboardShortcuts.events(for: .testShortcut1) {
				switch event {
					   case .keyDown:
						   print("Shortcut key pressed down")
						   // Perform action when key is pressed
						   
					   case .keyUp:
						   print("Shortcut key released")
						   // Perform action when key is released
					   }
			}
		}
		.task {
			for await event in KeyboardShortcuts.events(for: .testShortcut2) {
				switch event {
					   case .keyDown:
						   print("Shortcut key 2 pressed down")
						   // Perform action when key 2 is pressed
						   
					   case .keyUp:
						   print("Shortcut key 2 released")
						   // Perform action when key 2 is released
					   }
			}
		}
		.task {
			for await event in KeyboardShortcuts.events(for: .testShortcut3) {
				switch event {
					   case .keyDown:
						   print("Shortcut key 3 pressed down")
						   // Perform action when key 3 is pressed
						   
					   case .keyUp:
						   print("Shortcut key 3 released")
						   // Perform action when key 3 is released
					   }
			}
		}
    }
}

#Preview {
    MainScreen()
}