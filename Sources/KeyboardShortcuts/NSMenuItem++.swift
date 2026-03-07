#if os(macOS)
import AppKit

extension NSMenuItem {
	private final class WeakReference<T: AnyObject>: @unchecked Sendable {
		weak var value: T?

		init(_ value: T) {
			self.value = value
		}
	}

	private struct FallbackShortcut: Sendable {
		let keyEquivalent: String
		let modifierMask: NSEvent.ModifierFlags
	}

	private enum AssociatedKeys {
		static let observer = ObjectAssociation<NSObjectProtocol>()
		static let fallback = ObjectAssociation<FallbackShortcut>()
	}

	private func clearShortcut() {
		keyEquivalent = ""
		keyEquivalentModifierMask = []

		if #available(macOS 12, *) {
			allowsAutomaticKeyEquivalentLocalization = true
		}
	}

	private func restoreShortcut() {
		if let fallback = AssociatedKeys.fallback[self] {
			keyEquivalent = fallback.keyEquivalent
			keyEquivalentModifierMask = fallback.modifierMask

			if #available(macOS 12, *) {
				allowsAutomaticKeyEquivalentLocalization = true
			}
		} else {
			clearShortcut()
		}
	}

	/**
	Show a recorded keyboard shortcut in a `NSMenuItem`.

	The menu item will automatically be kept up to date with changes to the keyboard shortcut.

	Pass in `nil` to clear the keyboard shortcut.

	This method overrides `.keyEquivalent` and `.keyEquivalentModifierMask`. The original values are preserved and restored when the global shortcut is cleared.
	*/
	@MainActor
	public func setShortcut(for name: KeyboardShortcuts.Name?) {
		guard let name else {
			restoreShortcut()
			AssociatedKeys.fallback[self] = nil
			NotificationCenter.default.removeObserver(AssociatedKeys.observer[self] as Any)
			AssociatedKeys.observer[self] = nil
			return
		}

		if let existingObserver = AssociatedKeys.observer[self] {
			NotificationCenter.default.removeObserver(existingObserver)
			AssociatedKeys.observer[self] = nil
		} else {
			AssociatedKeys.fallback[self] = FallbackShortcut(
				keyEquivalent: keyEquivalent,
				modifierMask: keyEquivalentModifierMask
			)
		}

		let shortcut = KeyboardShortcuts.Shortcut(name: name)
		if let shortcut {
			setShortcut(shortcut)
		} else {
			restoreShortcut()
		}

		let menuItemReference = WeakReference(self)
		AssociatedKeys.observer[self] = NotificationCenter.default.addObserver(forName: .shortcutByNameDidChange, object: nil, queue: .main) { notification in
			guard
				let nameInNotification = notification.keyboardShortcutsName,
				nameInNotification == name
			else {
				return
			}

			MainActor.assumeIsolated {
				guard let menuItem = menuItemReference.value else {
					return
				}

				let shortcut = KeyboardShortcuts.Shortcut(name: name)
				if let shortcut {
					menuItem.setShortcut(shortcut)
				} else {
					menuItem.restoreShortcut()
				}
			}
		}
	}

	/**
	Add a keyboard shortcut to a `NSMenuItem`.

	This method is only recommended for dynamic shortcuts. In general, it's preferred to create a static shortcut name and use `NSMenuItem.setShortcut(for:)` instead.

	Pass in `nil` to clear the keyboard shortcut.

	This method overrides `.keyEquivalent` and `.keyEquivalentModifierMask`.
	*/
	@_disfavoredOverload
	@MainActor
	public func setShortcut(_ shortcut: KeyboardShortcuts.Shortcut?) {
		guard let shortcut else {
			clearShortcut()
			return
		}

		keyEquivalent = shortcut.nsMenuItemKeyEquivalent ?? ""
		keyEquivalentModifierMask = shortcut.nsEventModifiers

		if #available(macOS 12, *) {
			allowsAutomaticKeyEquivalentLocalization = false
		}
	}
}

private extension Notification {
	var keyboardShortcutsName: KeyboardShortcuts.Name? {
		userInfo?["name"] as? KeyboardShortcuts.Name
	}
}
#endif
