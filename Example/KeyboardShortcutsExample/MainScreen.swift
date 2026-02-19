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
	@State private var shortcutsKeyProxyView: NSView?

	private let shortcutRows: [(name: KeyboardShortcuts.Name, label: String)] = [
		(.testQuickAction, "Quick Action"),
		(.testCaptureSelection, "Capture Selection"),
		(.testShowLauncher, "Show Launcher"),
		(.testRunWorkflow, "Run Workflow"),
		(.testOpenPreferences, "Open Preferences")
	]

	var body: some View {
		VStack(spacing: 0) {
			Text("Keyboard Shortcuts")
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.vertical, 8)
				.padding(.leading, 12)
				.font(.system(size: 11, weight: .medium))
				.foregroundStyle(.secondary)
				.background {
					if colorScheme == .light {
						Color(nsColor: .alternatingContentBackgroundColors[1])
							.padding(.horizontal, -12)
					}
				}

			Divider()
				.padding(.bottom, -12)
				.padding(.horizontal, -12)
				.opacity(0.5)
				.frame(height: 1.5)

			ForEach(Array(shortcutRows.enumerated()), id: \.element.name.rawValue) { index, row in
				KeyboardShortcutRecorder(
					for: row.name,
					label: row.label,
					focused: $selectedField,
					onInteraction: focusShortcutsSection
				)
				.focusEffectDisabled(true)
				.background {
					if shouldUseAlternatingBackground(for: index) {
						Color(nsColor: .alternatingContentBackgroundColors[1])
							.padding(.horizontal, -12)
					}
				}
			}
		}
		.clipShape(RoundedRectangle(cornerRadius: 6))
		.overlay(
			RoundedRectangle(cornerRadius: 6)
				.stroke(Color(nsColor: .separatorColor), lineWidth: 0.75)
				.opacity(colorScheme == .dark ? 1 : 0.5)
		)
		.padding(20)
		.frame(width: 470, height: 220)
		.background {
			ShortcutNavigationProxy(onMove: moveShortcutSelection) { view in
				if shortcutsKeyProxyView !== view {
					shortcutsKeyProxyView = view
				}
			}
			.frame(width: 0, height: 0)
		}
		.task {
			await logEvents(for: .testQuickAction)
		}
		.task {
			await logEvents(for: .testCaptureSelection)
		}
		.task {
			await logEvents(for: .testShowLauncher)
		}
		.task {
			await logEvents(for: .testRunWorkflow)
		}
		.task {
			await logEvents(for: .testOpenPreferences)
		}
	}

	private func shouldUseAlternatingBackground(for index: Int) -> Bool {
		if colorScheme == .light {
			return index.isMultiple(of: 2)
		}

		return !index.isMultiple(of: 2)
	}

	private func moveShortcutSelection(_ direction: MoveCommandDirection) {
		guard direction == .up || direction == .down else { return }
		guard !shortcutRows.isEmpty else { return }

		let names = shortcutRows.map(\.name)
		let currentIndex = selectedField.flatMap { names.firstIndex(of: $0) }
		let seedIndex = currentIndex ?? (direction == .down ? -1 : names.count)
		let nextIndex = direction == .down
			? min(seedIndex + 1, names.count - 1)
			: max(seedIndex - 1, 0)

		selectedField = names[nextIndex]
	}

	private func focusShortcutsSection() {
		DispatchQueue.main.async {
			guard let proxyView = shortcutsKeyProxyView else { return }
			NSApp.keyWindow?.makeFirstResponder(proxyView)
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

private struct ShortcutNavigationProxy: NSViewRepresentable {
	let onMove: (MoveCommandDirection) -> Void
	let onReady: (NSView) -> Void

	func makeNSView(context: Context) -> ProxyView {
		let view = ProxyView()
		view.onMove = onMove
		DispatchQueue.main.async {
			onReady(view)
		}
		return view
	}

	func updateNSView(_ nsView: ProxyView, context: Context) {
		nsView.onMove = onMove
		DispatchQueue.main.async {
			onReady(nsView)
		}
	}

	final class ProxyView: NSView {
		var onMove: ((MoveCommandDirection) -> Void)?

		override var acceptsFirstResponder: Bool { true }

		override var focusRingType: NSFocusRingType {
			get { .none }
			set { }
		}

		override func keyDown(with event: NSEvent) {
			switch event.keyCode {
			case 125:
				onMove?(.down)
			case 126:
				onMove?(.up)
			default:
				super.keyDown(with: event)
			}
		}
	}
}

#Preview {
	MainScreen()
}
