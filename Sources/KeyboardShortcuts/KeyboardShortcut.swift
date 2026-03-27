#if os(macOS)
import SwiftUI
import Carbon.HIToolbox

public struct KeyboardShortcutToggle: View {
	private let enabledName: KeyboardShortcuts.Name
	public let label: String
	public let onInteraction: (() -> Void)?

	@State private var userDesiredIsEnabled: Bool = true

	public init(for name: KeyboardShortcuts.Name, label: String, onInteraction: (() -> Void)? = nil) {
		self.enabledName = name
		self.label = label
		self.onInteraction = onInteraction
	}

	public var body: some View {
		HStack {
			Toggle("", isOn: $userDesiredIsEnabled)
				.toggleStyle(.checkbox)
				.focusable(false)
				.focusEffectDisabled(true)
				.labelsHidden()
				.frame(width: 14, height: 14)
				.padding(.trailing, 10)

			Text(label)
				.font(.system(size: 13, weight: .regular))
		}
		.onAppear {
			userDesiredIsEnabled = loadEnabledPreference()
			applyEnabledState(userDesiredIsEnabled)
		}
		.onChange(of: userDesiredIsEnabled) { _, newValue in
			persistEnabledPreference(newValue)
			applyEnabledState(newValue)
			onInteraction?()
		}
	}

	private var enabledDefaultsKey: String {
		"KeyboardShortcutsEnabled_\(enabledName.rawValue)"
	}

	private func loadEnabledPreference() -> Bool {
		guard UserDefaults.standard.object(forKey: enabledDefaultsKey) != nil else { return true }
		return UserDefaults.standard.bool(forKey: enabledDefaultsKey)
	}

	private func persistEnabledPreference(_ isEnabled: Bool) {
		UserDefaults.standard.set(isEnabled, forKey: enabledDefaultsKey)
	}

	private func applyEnabledState(_ isEnabled: Bool) {
		if isEnabled {
			KeyboardShortcuts.enable(enabledName)
		} else {
			KeyboardShortcuts.disable(enabledName)
		}
	}
}

public struct KeyboardShortcutRecorder: View {
	@Binding public var focused: KeyboardShortcuts.Name?
	public let onChange: ((KeyboardShortcuts.Shortcut?) -> Void)?
	public let onInteraction: (() -> Void)?

	private let shortcutStorageName: KeyboardShortcuts.Name?
	private let focusName: KeyboardShortcuts.Name?
	private let shortcutBinding: Binding<KeyboardShortcuts.Shortcut?>?

	@State private var currentShortcut: KeyboardShortcuts.Shortcut?
	@State private var isRecording = false
	@State private var isLocallyFocused = false
	@FocusState private var isTextFieldFocused: Bool
	@State private var isConflicting = false
	@State private var conflictReason = ""

	private var isFocused: Bool {
		if let focusName {
			return focusName == focused
		}
		return isLocallyFocused
	}

	public init(
		for name: KeyboardShortcuts.Name,
		focused: Binding<KeyboardShortcuts.Name?>,
		onInteraction: (() -> Void)? = nil,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
	) {
		self.shortcutStorageName = name
		self.focusName = name
		self.shortcutBinding = nil
		self._focused = focused
		self.onInteraction = onInteraction
		self.onChange = onChange
	}

	public init(
		shortcut: Binding<KeyboardShortcuts.Shortcut?>,
		focused: Binding<KeyboardShortcuts.Name?>,
		focusID: KeyboardShortcuts.Name,
		onInteraction: (() -> Void)? = nil,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
	) {
		self.shortcutStorageName = nil
		self.focusName = focusID
		self.shortcutBinding = shortcut
		self._focused = focused
		self.onInteraction = onInteraction
		self.onChange = onChange
	}

	public init(
		shortcut: Binding<KeyboardShortcuts.Shortcut?>,
		onInteraction: (() -> Void)? = nil,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
	) {
		self.shortcutStorageName = nil
		self.focusName = nil
		self.shortcutBinding = shortcut
		self._focused = .constant(nil)
		self.onInteraction = onInteraction
		self.onChange = onChange
	}

	public var body: some View {
		let conflictOffset: CGFloat = isConflicting ? -16 : 0

		ZStack(alignment: .trailing) {
			Image(systemName: "exclamationmark.triangle")
				.renderingMode(.template)
				.opacity(isConflicting ? 1 : 0)
				.padding(.trailing, 2)
				.help(conflictReason)
				.allowsHitTesting(false)

			Group {
				if isRecording {
					TextField("", text: .constant(""))
						.focused($isTextFieldFocused)
						.textFieldStyle(.plain)
						.multilineTextAlignment(.trailing)
						.tint(.blue)
						.onKeyPress { keyPress in
							handleKeyPress(keyPress)
							return .handled
						}
				} else {
					Text(currentShortcut?.description ?? "none")
						.font(.system(size: currentShortcut == nil ? 10 : 13, weight: .regular))
						.foregroundStyle(currentShortcut == nil ? .secondary : .primary)
				}
			}
			.frame(maxWidth: .infinity, alignment: .trailing)
			.offset(x: conflictOffset)
		}
		.frame(maxWidth: .infinity, minHeight: 20, maxHeight: 26)
		.contentShape(Rectangle())
		.onTapGesture {
			guard !isRecording else { return }
			activateFocus()
			isRecording = true
		}
		.onAppear {
			if let shortcutStorageName {
				currentShortcut = KeyboardShortcuts.getShortcut(for: shortcutStorageName)
			} else {
				currentShortcut = shortcutBinding?.wrappedValue
			}
			updateConflictStatus(for: currentShortcut)
		}
		.onChange(of: currentShortcut) { _, newValue in
			if let shortcutStorageName {
				KeyboardShortcuts.setShortcut(newValue, for: shortcutStorageName)
			} else {
				shortcutBinding?.wrappedValue = newValue
			}
			updateConflictStatus(for: newValue)
			onChange?(newValue)
		}
		.onChange(of: isRecording) { _, newValue in
			KeyboardShortcuts.isPaused = newValue
			isTextFieldFocused = newValue
		}
		.onChange(of: focused) { _, newValue in
			guard let focusName else { return }
			if newValue != focusName {
				isRecording = false
			}
		}
		.onChange(of: shortcutBinding?.wrappedValue) { _, newValue in
			guard shortcutStorageName == nil else { return }
			if currentShortcut != newValue {
				currentShortcut = newValue
			}
		}
	}

	private func activateFocus() {
		if let focusName {
			focused = focusName
		} else {
			isLocallyFocused = true
		}
		onInteraction?()
	}

	private func handleKeyPress(_ keyPress: SwiftUI.KeyPress) {
		if keyPress.key == .escape {
			isRecording = false
			focused = nil
			isLocallyFocused = false
			return
		}

		if keyPress.key == .delete || keyPress.key == .deleteForward {
			currentShortcut = nil
			isRecording = false
			focused = nil
			isLocallyFocused = false
			return
		}

		guard
			let key = KeyboardShortcuts.Key(keyPress: keyPress),
			!keyPress.modifiers.isEmpty || key.isSpecialKey
		else {
			return
		}

		currentShortcut = KeyboardShortcuts.Shortcut(key, modifiers: keyPress.modifiers)
		isRecording = false
		focused = nil
		isLocallyFocused = false
		return
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
#endif
