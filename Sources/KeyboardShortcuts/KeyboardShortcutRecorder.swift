import SwiftUI
import Carbon.HIToolbox

public struct KeyboardShortcutRecorder: View {
	public let shortcutName: KeyboardShortcuts.Name
	public let label: String
	public let onChange: ((KeyboardShortcuts.Shortcut?) -> Void)?
	public let onInteraction: (() -> Void)?
	@Binding public var focused: KeyboardShortcuts.Name?

	@State private var currentShortcut: KeyboardShortcuts.Shortcut?
	private var isFocused: Bool { shortcutName == focused }
	@State private var isRecording = false
	@FocusState private var isTextFieldFocused: Bool
	@State private var isConflicting = false
	@State private var conflictReason = ""
	@State private var userDesiredIsEnabled: Bool = true
	@State private var isAppActive: Bool = NSApp.isActive

	public init(
		for name: KeyboardShortcuts.Name,
		label: String,
		focused: Binding<KeyboardShortcuts.Name?>,
		onInteraction: (() -> Void)? = nil,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
	) {
		self.shortcutName = name
		self.label = label
		self._focused = focused
		self.onInteraction = onInteraction
		self.onChange = onChange
	}

	public var body: some View {
		
		HStack {
			
			Toggle("", isOn: $userDesiredIsEnabled)
				.toggleStyle(.checkbox)
				.focusable(false)
				.focusEffectDisabled(true)
				.labelsHidden()
				.frame(width: 14, height: 14)
				.padding(.leading)
				.padding(.trailing, 7)
					.onChange(of: userDesiredIsEnabled) { _ in
						onInteraction?()
					}

				Text(label)
					.foregroundColor(isFocused && isAppActive ? .white : .primary)
					.font(.system(size: 13, weight: .regular))
				Spacer()

				ZStack {
					if isRecording {
						TextField("", text: .constant(""))
							.focused($isTextFieldFocused)
							.textFieldStyle(.plain)
							.multilineTextAlignment(.trailing)
							.frame(width: 100, height: 18, alignment: .trailing)
							.foregroundStyle(.clear)
							.tint(.blue)
							.onKeyPress { keyPress in
								handleKeyPress(keyPress)
								return .handled
							}
							.padding(.trailing, 4)
							.background(Rectangle().fill(Color.white))
							.frame(width: 100, height: 18)
						} else {
							HStack(spacing: 4) {
								Text(currentShortcut?.description ?? "none")
									.font(.system(size: currentShortcut == nil ? 10 : 13, weight: .regular))
									.foregroundColor(
									currentShortcut == nil
									? (isFocused && isAppActive ? .white : .secondary)
									: (isFocused && isAppActive ? .white : .primary)
								)
						}
						.frame(width: 100, height: 18, alignment: .trailing)
					}
				}
				.contentShape(Rectangle())
						.onTapGesture {
							if isFocused {
								isRecording = true
							} else {
								focused = shortcutName
								onInteraction?()
							}
						}
			if isConflicting && userDesiredIsEnabled {
				Image(systemName: "exclamationmark.triangle")
					.foregroundColor(isFocused ? .white : .secondary)
					.help(conflictReason)
				}
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 4)
			.frame(minWidth: 300, maxWidth: .infinity, minHeight: 18, maxHeight: .infinity, alignment: .center)
			.focusEffectDisabled(true)
			.background(
				Group {
					if isFocused {
						Rectangle()
							.fill(isAppActive ? Color(nsColor: .selectedContentBackgroundColor) : Color.secondary.opacity(0.2))
							.padding(.horizontal, -10)
					}
				}
			)
			.contentShape(Rectangle())
					.onTapGesture {
						focused = shortcutName
						onInteraction?()
					}
		.onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
			isAppActive = true
		}
		.onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
			isAppActive = false
		}
		.onAppear {
			currentShortcut = KeyboardShortcuts.getShortcut(for: shortcutName)
			updateConflictStatus(for: currentShortcut)
		}
		.onChange(of: currentShortcut) { _, newValue in
			KeyboardShortcuts.setShortcut(newValue, for: shortcutName)
			updateConflictStatus(for: newValue)
			onChange?(newValue)
		}
		.onChange(of: isRecording) { _, newValue in
			KeyboardShortcuts.isPaused = newValue
			isTextFieldFocused = newValue
		}
			.onChange(of: focused) { _, newValue in
				if newValue != shortcutName {
					isRecording = false
				}
			}
		}

	private func handleKeyPress(_ keyPress: SwiftUI.KeyPress) {
		if keyPress.key == .escape {
			isRecording = false
			focused = nil
			return
		}

		if keyPress.key == .delete || keyPress.key == .deleteForward {
			currentShortcut = nil
			isRecording = false
			focused = nil
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
		focused = nil
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
