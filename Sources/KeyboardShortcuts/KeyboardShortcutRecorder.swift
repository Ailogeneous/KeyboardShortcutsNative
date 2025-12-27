import SwiftUI
import Carbon.HIToolbox

public struct KeyboardShortcutRecorder: View {
	public let shortcutName: KeyboardShortcuts.Name
	public let label: String
	public let onChange: ((KeyboardShortcuts.Shortcut?) -> Void)?

	@State private var currentShortcut: KeyboardShortcuts.Shortcut?
	@State private var isHighlighted = false
	@FocusState private var isRecording: Bool
	@State private var isConflicting = false
	@State private var conflictReason = ""
	@State private var userDesiredIsEnabled: Bool = true

	public init(for name: KeyboardShortcuts.Name, label: String, onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil) {
		self.shortcutName = name
		self.label = label
		self.onChange = onChange
	}

	public var body: some View {
		HStack {
			Toggle("", isOn: $userDesiredIsEnabled)
				.labelsHidden()
				.toggleStyle(.checkbox)
				.focusable(false)
				.focusEffectDisabled()
				.padding(.leading)
				.padding(.trailing, 4)

			Text(label)
				.foregroundColor(isHighlighted ? .white : .primary)
			Spacer()

			ZStack {
				ZStack(alignment: .trailing) {
					TextField("", text: .constant(""))
						.textFieldStyle(.plain)
						.multilineTextAlignment(.trailing)
						.frame(width: 100, height: 22, alignment: .trailing)
						.foregroundStyle(.clear)
						.tint(.blue)
						.focused($isRecording)
						.focusEffectDisabled()
						.onKeyPress { keyPress in
							handleKeyPress(keyPress)
							return .handled
						}
						.padding(.trailing, 4)
				}
				.background(Rectangle().fill(Color.white))
				.frame(width: 100, height: 22)
				.opacity(isRecording ? 1 : 0)
				.allowsHitTesting(isRecording)

				if !isRecording {
					HStack(spacing: 4) {
						Text(currentShortcut?.description ?? "none")
							.font(.system(size: 13, weight: .medium))
							.foregroundColor(isHighlighted ? .white : .primary)
					}
					.frame(width: 100, height: 22, alignment: .trailing)
					.opacity(isRecording ? 0 : 1)
					.allowsHitTesting(!isRecording)
				}
			}
			.contentShape(Rectangle())
			.onTapGesture {
				if self.isHighlighted {
					self.isRecording = true
				} else {
					self.isHighlighted = true
				}
			}
			if isConflicting && userDesiredIsEnabled {
				Image(systemName: "exclamationmark.triangle")
					.foregroundColor(isHighlighted ? .white : .secondary)
					.help(conflictReason)
			}
		}
		.padding(.horizontal, 12)
		.padding(.vertical, 4)
		.frame(minWidth: 100, maxWidth: .infinity)
		.background(isHighlighted ? Color("AccentColor") : .clear)
		.contentShape(Rectangle())
		.onTapGesture {
			isHighlighted = true
		}
		.onAppear {
			currentShortcut = KeyboardShortcuts.getShortcut(for: shortcutName)
			KeyboardShortcuts.isPaused = isRecording
			updateConflictStatus(for: currentShortcut)
		}
		.onChange(of: isRecording) { _, newValue in
			KeyboardShortcuts.isPaused = newValue
			if !newValue {
				isHighlighted = false
			}
		}
		.onChange(of: currentShortcut) { _, newValue in
			KeyboardShortcuts.setShortcut(newValue, for: shortcutName)
			updateConflictStatus(for: newValue)
			onChange?(newValue)
		}
		.focusEffectDisabled()
	}

	private func handleKeyPress(_ keyPress: SwiftUI.KeyPress) {
		if keyPress.key == .escape {
			isRecording = false
			isHighlighted = false
			return
		}

		if keyPress.key == .delete || keyPress.key == .deleteForward {
			currentShortcut = nil
			isRecording = false
			isHighlighted = false
			return
		}

		guard
			let key = KeyboardShortcuts.Key(keyPress: keyPress),
			!keyPress.modifiers.isEmpty || key.isSpecialKey
		else {
			return
		}
		
		let newShortcut = KeyboardShortcuts.Shortcut(key, modifiers: keyPress.modifiers)
		
		currentShortcut = newShortcut
		isRecording = false
		isHighlighted = false
	}

	private func updateConflictStatus(for shortcut: KeyboardShortcuts.Shortcut?) {
		Task { @MainActor in
			guard let shortcut else {
				isConflicting = false
				conflictReason = ""
				return
			}
			
			if shortcut.isDisallowed {
				isConflicting = true
				conflictReason = "This shortcut is disallowed by the system."
			} else if shortcut.isTaken {
				isConflicting = true
				conflictReason = "This shortcut is used by the system or the app."
			} else {
				isConflicting = false
				conflictReason = ""
			}
		}
	}
}
