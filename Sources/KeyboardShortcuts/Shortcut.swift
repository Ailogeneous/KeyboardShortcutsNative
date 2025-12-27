import SwiftUI
import Carbon.HIToolbox

extension KeyboardShortcuts {
	/**
	A keyboard shortcut.
	*/
	public struct Shortcut: Hashable, Codable, Sendable {
		/**
		Carbon modifiers are not always stored as the same number.
		For example, the system has `⌃F2` stored with the modifiers number `135168`, but if you press the keyboard shortcut, you get `4096`.
		*/
		private static func normalizeModifiers(_ carbonModifiers: Int) -> Int {
			// We need to use `NSEvent` here, not `SwiftUI.EventModifiers`, as the latter is not exhaustive.
			NSEvent.ModifierFlags(carbon: carbonModifiers).carbon
		}

		/**
		The keyboard key of the shortcut.
		*/
		public var key: Key? { Key(rawValue: carbonKeyCode) }

		/**
		The modifier keys of the shortcut.
		*/
		public var modifiers: SwiftUI.EventModifiers { SwiftUI.EventModifiers(carbon: carbonModifiers) }

		/**
		The modifier keys of the shortcut as an `NSEvent.ModifierFlags`.
		This is used for the menu-searching logic.
		*/
		var nsEventModifiers: NSEvent.ModifierFlags { NSEvent.ModifierFlags(carbon: carbonModifiers) }

		/**
		Low-level representation of the key.
		You most likely don't need this.
		*/
		public let carbonKeyCode: Int

		/**
		Low-level representation of the modifier keys.
		You most likely don't need this.
		*/
		public let carbonModifiers: Int

		/**
		Initialize from a strongly-typed key and modifiers.
		*/
		public init(_ key: Key, modifiers: SwiftUI.EventModifiers = []) {
			self.init(
				carbonKeyCode: key.rawValue,
				carbonModifiers: modifiers.carbon
			)
		}

		/**
		Initialize from a key press.
		*/
		public init?(keyPress: SwiftUI.KeyPress) {
			guard
				let key = Key(keyPress: keyPress)
			else {
				return nil
			}

			self.init(
				key,
				modifiers: keyPress.modifiers
			)
		}

		/**
		Initialize from a keyboard shortcut stored by `Recorder`.
		*/
		public init?(name: Name) {
			guard let shortcut = getShortcut(for: name) else {
				return nil
			}

			self = shortcut
		}



		/**
		Initialize from a key code number and modifier code.
		You most likely don't need this.
		*/
		public init(carbonKeyCode: Int, carbonModifiers: Int = 0) {
			self.carbonKeyCode = carbonKeyCode
			self.carbonModifiers = Self.normalizeModifiers(carbonModifiers)
		}
	}
}

enum Constants {
	static let isSandboxed = ProcessInfo.processInfo.environment.hasKey("APP_SANDBOX_CONTAINER_ID")
}

extension KeyboardShortcuts.Shortcut {
	/**
	System-defined keyboard shortcuts.
	*/
	static var system: [Self] {
		CarbonKeyboardShortcuts.system
	}

	/**
	Check whether the keyboard shortcut is disallowed.
	*/
	var isDisallowed: Bool {
		false
	}

	/**
	Check whether the keyboard shortcut is already taken by the system or the app's main menu.
	*/
	@MainActor
	var isTaken: Bool {
		if
			let key,
			key == .f12,
			modifiers.isEmpty
		{
			return false
		}

		if Self.system.contains(self) {
			return true
		}

		if takenByMainMenu != nil {
			return true
		}

		return false
	}
}

// MARK: - Menu Bar Conflict Resolution
extension KeyboardShortcuts.Shortcut {
	/**
	Recursively finds a menu item in the given menu that has a matching key equivalent and modifier.
	*/
	@MainActor
	private func menuItemWithMatchingShortcut(in menu: NSMenu) -> NSMenuItem? {
		for item in menu.items {
			// AppKit replaces `Delete` with `Backspace` in menus.
			var keyEquivalent = item.keyEquivalent
			var keyEquivalentModifierMask = item.keyEquivalentModifierMask

			if
				nsEventModifiers.contains(.shift),
				keyEquivalent.lowercased() != keyEquivalent
			{
				keyEquivalent = keyEquivalent.lowercased()
				keyEquivalentModifierMask.insert(.shift)
			}

			if
				nsMenuItemKeyEquivalent == keyEquivalent,
				nsEventModifiers == keyEquivalentModifierMask
			{
				return item
			}

			if
				let submenu = item.submenu,
				let menuItem = menuItemWithMatchingShortcut(in: submenu)
			{
				return menuItem
			}
		}

		return nil
	}

	/**
	Returns a menu item in the app's main menu that has a matching key equivalent and modifier.
	*/
	@MainActor
	var takenByMainMenu: NSMenuItem? {
		guard
			let mainMenu = NSApp.mainMenu
		else {
			return nil
		}

		return menuItemWithMatchingShortcut(in: mainMenu)
	}
}


private enum SpecialKey {
	case `return`
	case delete
	case deleteForward
	case end
	case escape
	case help
	case home
	case space
	case tab
	case pageUp
	case pageDown
	case upArrow
	case rightArrow
	case downArrow
	case leftArrow
	case f1
	case f2
	case f3
	case f4
	case f5
	case f6
	case f7
	case f8
	case f9
	case f10
	case f11
	case f12
	case f13
	case f14
	case f15
	case f16
	case f17
	case f18
	case f19
	case f20
	case keypad0
	case keypad1
	case keypad2
	case keypad3
	case keypad4
	case keypad5
	case keypad6
	case keypad7
	case keypad8
	case keypad9
	case keypadClear
	case keypadDecimal
	case keypadDivide
	case keypadEnter
	case keypadEquals
	case keypadMinus
	case keypadMultiply
	case keypadPlus
}

private let keyToSpecialKeyMapping: [KeyboardShortcuts.Key: SpecialKey] = [
	.return: .return,
	.delete: .delete,
	.deleteForward: .deleteForward,
	.end: .end,
	.escape: .escape,
	.help: .help,
	.home: .home,
	.space: .space,
	.tab: .tab,
	.pageUp: .pageUp,
	.pageDown: .pageDown,
	.upArrow: .upArrow,
	.rightArrow: .rightArrow,
	.downArrow: .downArrow,
	.leftArrow: .leftArrow,
	.f1: .f1,
	.f2: .f2,
	.f3: .f3,
	.f4: .f4,
	.f5: .f5,
	.f6: .f6,
	.f7: .f7,
	.f8: .f8,
	.f9: .f9,
	.f10: .f10,
	.f11: .f11,
	.f12: .f12,
	.f13: .f13,
	.f14: .f14,
	.f15: .f15,
	.f16: .f16,
	.f17: .f17,
	.f18: .f18,
	.f19: .f19,
	.f20: .f20,
	.keypad0: .keypad0,
	.keypad1: .keypad1,
	.keypad2: .keypad2,
	.keypad3: .keypad3,
	.keypad4: .keypad4,
	.keypad5: .keypad5,
	.keypad6: .keypad6,
	.keypad7: .keypad7,
	.keypad8: .keypad8,
	.keypad9: .keypad9,
	.keypadClear: .keypadClear,
	.keypadDecimal: .keypadDecimal,
	.keypadDivide: .keypadDivide,
	.keypadEnter: .keypadEnter,
	.keypadEquals: .keypadEquals,
	.keypadMinus: .keypadMinus,
	.keypadMultiply: .keypadMultiply,
	.keypadPlus: .keypadPlus
]

extension SpecialKey {
	fileprivate var presentableDescription: String {
		switch self {
		case .return:
			"↩"
		case .delete:
			"⌫"
		case .deleteForward:
			"⌦"
		case .end:
			"↘"
		case .escape:
			"⎋"
		case .help:
			"?⃝"
		case .home:
			"↖"
		case .space:
			"space_key".localized.capitalized
		case .tab:
			"⇥"
		case .pageUp:
			"⇞"
		case .pageDown:
			"⇟"
		case .upArrow:
			"↑"
		case .rightArrow:
			"→"
		case .downArrow:
			"↓"
		case .leftArrow:
			"←"
		case .f1:
			"F1"
		case .f2:
			"F2"
		case .f3:
			"F3"
		case .f4:
			"F4"
		case .f5:
			"F5"
		case .f6:
			"F6"
		case .f7:
			"F7"
		case .f8:
			"F8"
		case .f9:
			"F9"
		case .f10:
			"F10"
		case .f11:
			"F11"
		case .f12:
			"F12"
		case .f13:
			"F13"
		case .f14:
			"F14"
		case .f15:
			"F15"
		case .f16:
			"F16"
		case .f17:
			"F17"
		case .f18:
			"F18"
		case .f19:
			"F19"
		case .f20:
			"F20"
		case .keypad0:
			"0\u{20e3}"
		case .keypad1:
			"1\u{20e3}"
		case .keypad2:
			"2\u{20e3}"
		case .keypad3:
			"3\u{20e3}"
		case .keypad4:
			"4\u{20e3}"
		case .keypad5:
			"5\u{20e3}"
		case .keypad6:
			"6\u{20e3}"
		case .keypad7:
			"7\u{20e3}"
		case .keypad8:
			"8\u{20e3}"
		case .keypad9:
			"9\u{20e3}"
		case .keypadClear:
			"☒\u{20e3}"
		case .keypadDecimal:
			".\u{20e3}"
		case .keypadDivide:
			"/\u{20e3}"
		case .keypadEnter:
			"↩\u{20e3}"
		case .keypadEquals:
			"=\u{20e3}"
		case .keypadMinus:
			"-\u{20e3}"
		case .keypadMultiply:
			"*\u{20e3}"
		case .keypadPlus:
			"+\u{20e3}"
		}
	}

	fileprivate var appKitMenuItemKeyEquivalent: Character? {
		switch self {
		case .return:
			"\r"
		case .delete:
			"\u{7f}"
		case .deleteForward:
			Character(unicodeScalarValue: 0xF728)
		case .end:
			Character(unicodeScalarValue: 0xF72B)
		case .escape:
			"\u{1b}"
		case .help:
			Character(unicodeScalarValue: 0xF746)
		case .home:
			Character(unicodeScalarValue: 0xF729)
		case .space:
			" "
		case .tab:
			"\t"
		case .pageUp:
			Character(unicodeScalarValue: 0xF72C)
		case .pageDown:
			Character(unicodeScalarValue: 0xF72D)
		case .upArrow:
			Character(unicodeScalarValue: 0xF700)
		case .rightArrow:
			Character(unicodeScalarValue: 0xF703)
		case .downArrow:
			Character(unicodeScalarValue: 0xF701)
		case .leftArrow:
			Character(unicodeScalarValue: 0xF702)
		case .f1:
			Character(unicodeScalarValue: NSF1FunctionKey)
		case .f2:
			Character(unicodeScalarValue: NSF2FunctionKey)
		case .f3:
			Character(unicodeScalarValue: NSF3FunctionKey)
		case .f4:
			Character(unicodeScalarValue: NSF4FunctionKey)
		case .f5:
			Character(unicodeScalarValue: NSF5FunctionKey)
		case .f6:
			Character(unicodeScalarValue: NSF6FunctionKey)
		case .f7:
			Character(unicodeScalarValue: NSF7FunctionKey)
		case .f8:
			Character(unicodeScalarValue: NSF8FunctionKey)
		case .f9:
			Character(unicodeScalarValue: NSF9FunctionKey)
		case .f10:
			Character(unicodeScalarValue: NSF10FunctionKey)
		case .f11:
			Character(unicodeScalarValue: NSF11FunctionKey)
		case .f12:
			Character(unicodeScalarValue: NSF12FunctionKey)
		case .f13:
			Character(unicodeScalarValue: NSF13FunctionKey)
		case .f14:
			Character(unicodeScalarValue: NSF14FunctionKey)
		case .f15:
			Character(unicodeScalarValue: NSF15FunctionKey)
		case .f16:
			Character(unicodeScalarValue: NSF16FunctionKey)
		case .f17:
			Character(unicodeScalarValue: NSF17FunctionKey)
		case .f18:
			Character(unicodeScalarValue: NSF18FunctionKey)
		case .f19:
			Character(unicodeScalarValue: NSF19FunctionKey)
		case .f20:
			Character(unicodeScalarValue: NSF20FunctionKey)
		case .keypad0:
			"0"
		case .keypad1:
			"1"
		case .keypad2:
			"2"
		case .keypad3:
			"3"
		case .keypad4:
			"4"
		case .keypad5:
			"5"
		case .keypad6:
			"6"
		case .keypad7:
			"7"
		case .keypad8:
			"8"
		case .keypad9:
			"9"
		case .keypadClear:
			Character(unicodeScalarValue: 0xF739)
		case .keypadDecimal:
			"."
		case .keypadDivide:
			"/"
		case .keypadEnter:
			"\r"
		case .keypadEquals:
			"="
		case .keypadMinus:
			"-"
		case .keypadMultiply:
			"*"
		case .keypadPlus:
			"+"
		}
	}
}


extension KeyboardShortcuts.Shortcut {
	@MainActor // `TISGetInputSourceProperty` crashes if called on a non-main thread.
	fileprivate func keyToCharacter() -> Character? {
		guard
			let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
			let layoutDataPointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
		else {
			return nil
		}

		guard key.flatMap({ keyToSpecialKeyMapping[$0] }) == nil else {
			assertionFailure("Special keys should get special treatment and should not be translated using keyToCharacter()")
			return nil
		}

		let layoutData = unsafeBitCast(layoutDataPointer, to: CFData.self)
		let keyLayout = unsafeBitCast(CFDataGetBytePtr(layoutData), to: UnsafePointer<CoreServices.UCKeyboardLayout>.self)
		var deadKeyState: UInt32 = 0
		let maxLength = 4
		var length = 0
		var characters = [UniChar](repeating: 0, count: maxLength)

		let error = CoreServices.UCKeyTranslate(
			keyLayout,
			UInt16(carbonKeyCode),
			UInt16(CoreServices.kUCKeyActionDisplay),
			0, // No modifiers
			UInt32(LMGetKbdType()),
			OptionBits(CoreServices.kUCKeyTranslateNoDeadKeysBit),
			&deadKeyState,
			maxLength,
			&length,
			&characters
		)

		guard error == noErr else {
			return nil
		}

		let string = String(utf16CodeUnits: characters, count: length)
		if string.count == 1 {
			return string.first
		}

		return nil
	}

	/**
	Key equivalent string in `NSMenuItem` format.
	This can be used to show the keyboard shortcut in a `NSMenuItem` by assigning it to `NSMenuItem#keyEquivalent`.
	- Note: Don't forget to also pass ``Shortcut/modifiers`` to `NSMenuItem#keyEquivalentModifierMask`.
	*/
	@MainActor
	public var nsMenuItemKeyEquivalent: String? {
		if
			let key,
			let specialKey = keyToSpecialKeyMapping[key]
		{
			if let keyEquivalent = specialKey.appKitMenuItemKeyEquivalent {
				return String(keyEquivalent)
			}
		} else if let character = keyToCharacter() {
			return String(character).lowercased()
		}

		return nil
	}
}

extension KeyboardShortcuts.Shortcut: CustomStringConvertible {
	/**
	The string representation of the keyboard shortcut.
	```swift
	print(KeyboardShortcuts.Shortcut(.a, modifiers: [.command]))
	//=> "⌘A"
	```
	*/
	@MainActor
	var presentableDescription: String {
		if
			let key,
			let specialKey = keyToSpecialKeyMapping[key]
		{
			return modifiers.description + specialKey.presentableDescription
		}

		return modifiers.description + (keyToCharacter().map(String.init)?.capitalized ?? "")
	}

	@MainActor
	public var description: String {
		// TODO: `description` needs to be `nonisolated`
		presentableDescription
	}
}
