import SwiftUI
import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut")
}

private struct KeyboardShortcut: View {
	@State private var isPressed = false

	var body: some View {
		GroupBox {
			KeyboardShortcutRecorder(for: .testShortcut1, label: "Test Shortcut")
				.onChange(of: isPressed) { _, _ in
					print("Pressed")
				}
				.padding(.horizontal, -4)
				.padding(.vertical, -4)
		}
		.frame(width: 432)
		.task {
			for await event in KeyboardShortcuts.events(for: .testShortcut1) {
				isPressed = event == .keyDown
				//Add Shortcut Functionality Here. 
			}
		}
	}
}

struct MainScreen: View {
	var body: some View {
		VStack {
			KeyboardShortcut()
		}
		.frame(width: 400, height: 320)
	}
}

#Preview {
	MainScreen()
}
