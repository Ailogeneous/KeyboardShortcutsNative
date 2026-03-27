import SwiftUI
import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
	static let testQuickAction = Self("testQuickAction")
	static let testCaptureSelection = Self("testCaptureSelection")
	static let testShowLauncher = Self("testShowLauncher")
	static let testRunWorkflow = Self("testRunWorkflow")
	static let testOpenPreferences = Self("testOpenPreferences")
}

struct MainScreen: View {
	@Environment(\.colorScheme) private var colorScheme
	@State private var selectedField: KeyboardShortcuts.Name?
	@State private var selectedRow: KeyboardShortcuts.Name?

	private struct ShortcutRow: Identifiable {
		let id: KeyboardShortcuts.Name
		let label: String
	}

	private let shortcutRows: [ShortcutRow] = [
		ShortcutRow(id: .testQuickAction, label: "Quick Action"),
		ShortcutRow(id: .testCaptureSelection, label: "Capture Selection"),
		ShortcutRow(id: .testShowLauncher, label: "Show Launcher"),
		ShortcutRow(id: .testRunWorkflow, label: "Run Workflow"),
		ShortcutRow(id: .testOpenPreferences, label: "Open Preferences")
	]

	var body: some View {
		Form {
			Section {
				LabeledContent {
				} label: {
					Text("Keyboard Shortcuts")
						.font(.system(size: 11, weight: .medium))
						.foregroundStyle(.secondary)
				}
				
				Table(shortcutRows, selection: $selectedRow) {
					TableColumn("Shortcut") { row in
						KeyboardShortcutToggle(for: row.id, label: row.label)
							.padding(.leading, 10)
					}
	
					TableColumn("Recorder") { row in
						KeyboardShortcutRecorder(
							for: row.id,
							focused: $selectedField
						)
						.focusEffectDisabled(true)
					}
					.width(100)
	
				}
				.onChange(of: selectedRow) { _, newValue in
					guard selectedField != newValue else { return }
					selectedField = newValue
				}
			}
			.task { await logEvents(for: .testQuickAction) }
			.task { await logEvents(for: .testCaptureSelection) }
			.task { await logEvents(for: .testShowLauncher) }
			.task { await logEvents(for: .testRunWorkflow) }
			.task { await logEvents(for: .testOpenPreferences) }
		}
	}

	private func logEvents(for name: KeyboardShortcuts.Name) async {
		for await event in KeyboardShortcuts.events(for: name) {
			switch event {
			case .keyDown:
				print("\(name.rawValue) keyDown")
			case .keyUp:
				print("\(name.rawValue) keyUp")
			}
		}
	}
}

#Preview {
	MainScreen()
}
