import SwiftUI
import Carbon.HIToolbox

public struct KeyboardShortcutRecorder: View {
	public let shortcutName: KeyboardShortcuts.Name
	public let label: String
	public let onChange: ((KeyboardShortcuts.Shortcut?) -> Void)?
	@Binding public var focused: KeyboardShortcuts.Name?

	@State private var currentShortcut: KeyboardShortcuts.Shortcut?
	private var isFocused: Bool { shortcutName == focused }
	@State private var isRecording = false
	@FocusState private var isTextFieldFocused: Bool
	@State private var isConflicting = false
	@State private var conflictReason = ""
	@State private var userDesiredIsEnabled: Bool = true
	@State private var isAppActive: Bool = NSApp.isActive
	@Environment(\.colorScheme) var colorScheme

	public init(
		for name: KeyboardShortcuts.Name,
		label: String,
		focused: Binding<KeyboardShortcuts.Name?>,
		onChange: ((KeyboardShortcuts.Shortcut?) -> Void)? = nil
	) {
		self.shortcutName = name
		self.label = label
		self._focused = focused
		self.onChange = onChange
	}

	public var body: some View {
		
		HStack {
			
			AppKitCheckbox(isOn: $userDesiredIsEnabled, isAppActive: isAppActive)
				.frame(width: 14, height: 14)
				.contrast(!userDesiredIsEnabled && colorScheme != .dark ? 1.4 : 1)
				.padding(.leading)
				.padding(.trailing, 6)
				.overlay {
					if colorScheme != .dark && !userDesiredIsEnabled || !isAppActive && userDesiredIsEnabled && colorScheme != .dark {
						RoundedRectangle(cornerRadius: 3.5)
							.strokeBorder(Color(nsColor: .tertiaryLabelColor), lineWidth: 1)
							.frame(width: 14, height: 14)
							.offset(x : 6)
							
					}
				}

				Text(label)
					.foregroundColor(isFocused && isAppActive ? .white : .primary)
					.font(.system(size: 12, weight: .medium))
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
								.font(.system(size: 12, weight: .medium))
								.foregroundColor(isFocused && isAppActive ? .white : .primary)
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

struct AppKitCheckbox: NSViewRepresentable {
	@Binding var isOn: Bool
	var isAppActive: Bool
	@Environment(\.colorScheme) var colorScheme
	
	func makeNSView(context: Context) -> NSButton {
		let checkbox = NSButton()
		checkbox.setButtonType(.switch)
		checkbox.title = ""
		checkbox.target = context.coordinator
		checkbox.action = #selector(Coordinator.toggled)
		checkbox.focusRingType = .none
		checkbox.wantsLayer = true
		checkbox.contentTintColor = .controlAccentColor
		return checkbox
	}
	
	func updateNSView(_ nsView: NSButton, context: Context) {
		nsView.state = isOn ? .on : .off
		let isDarkMode = NSApp.effectiveAppearance.isDarkMode
		
		if isAppActive {
			nsView.contentTintColor = nil
		} else {
			if !isOn && !isDarkMode {
				nsView.contentTintColor = nil 
			} else {
				nsView.contentTintColor = isDarkMode ? .white : .black
			}
		}
	
		nsView.layer?.filters = nil
		
		if !isAppActive && isOn && !isDarkMode {
			let invertFilter = CIFilter(name: "CIColorInvert")
			invertFilter?.setDefaults()
			nsView.layer?.filters = [invertFilter].compactMap { $0 }
		}
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(isOn: $isOn)
	}
	
	class Coordinator {
		@Binding var isOn: Bool
		
		init(isOn: Binding<Bool>) {
			_isOn = isOn
		}
		
		@objc func toggled(_ sender: NSButton) {
			isOn = sender.state == .on
		}
	}
}

extension NSAppearance {
    var isDarkMode: Bool {
		return bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}
