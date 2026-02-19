[logo-light]: Resources/logo-light.png#gh-light-mode-only
[logo-dark]: Resources/logo-dark.png#gh-dark-mode-only
[Screenshot]:	Resources/Screenshot.png
[ScreenshotExample]:	Resources/ScreenshotExample.png
[ScreenshotConflict]:	Resources/ScreenshotConflict.png
[ScreenshotEdit]:	Resources/ScreenshotEdit.png

<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="Resources/logo-dark.png">
    <img src="Resources/logo-light.png" alt="Logo">
  </picture>
</div>

<div align="center">

![Logo light][logo-light]
![Logo dark][logo-dark]
	
**This is a native-styled fork of KeyboardShortcuts.**

[Installation](#install) • [Usage](#usage) • [API](#api) • [Tips](#tips)
</div>

---
![Screenshot][Screenshot]
![ScreenshotExample][ScreenshotExample]
![ScreenshotConflict][ScreenshotConflict]
![ScreenshotEdit][ScreenshotEdit]
___

This package lets you add support for user-customizable global keyboard shortcuts to your macOS app in minutes. It's fully sandboxed and Mac App Store compatible.

This fork focuses on a native-styled recorder UI and app-settings table behavior while keeping the core keyboard-shortcut APIs compatible with upstream usage.

## Requirements

macOS 14+

## Install

Add `https://github.com/Ailogeneous/KeyboardShortcutsNative` in the [“Swift Package Manager” tab in Xcode](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

## Usage

For a full, fork-aligned implementation, see: https://github.com/Ailogeneous/KeyboardShortcutsNative/blob/main/Example/KeyboardShortcutsExample/MainScreen.swift

First, register a name for the keyboard shortcut.

`Constants.swift`

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let toggleUnicornMode = Self("toggleUnicornMode")
}
```

You can then refer to this strongly-typed name in other places.

You will want to make a view where the user can choose a keyboard shortcut.

`SettingsScreen.swift`

```swift
import SwiftUI
import KeyboardShortcuts

struct SettingsScreen: View {
	@State private var selectedField: KeyboardShortcuts.Name?

	var body: some View {
		VStack(spacing: 0) {
			KeyboardShortcutRecorder(
				for: .toggleUnicornMode,
				label: "Toggle Unicorn Mode",
				focused: $selectedField
			)
		}
	}
}
```

`KeyboardShortcutRecorder` stores the shortcut in `UserDefaults` and warns when the chosen shortcut conflicts with the system or app menu.

Add a listener for when the user presses their chosen keyboard shortcut.

`App.swift`

```swift
import SwiftUI
import KeyboardShortcuts

@main
struct YourApp: App {
	@State private var appState = AppState()

	var body: some Scene {
		WindowGroup {
			// …
		}
		Settings {
			SettingsScreen()
		}
	}
}

final class AppState {
	init() {
		KeyboardShortcuts.onKeyUp(for: .toggleUnicornMode) {
			print("toggleUnicornMode released")
		}
	}
}
```

*You can also listen for key-down with `KeyboardShortcuts.onKeyDown(for:action:)`.*

**That's all.**

For a complete, fork-aligned implementation, use the example app in this repository: `Example/KeyboardShortcutsExample`.

#### Cocoa

This fork currently provides the SwiftUI `KeyboardShortcutRecorder` API only.

## Localization

This package supports [localizations](/Sources/KeyboardShortcuts/Localization). PRs welcome for more!

1. Fork the repo.
2. Create a directory that has a name that uses an [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) language code and optional designators, followed by the `.lproj` suffix. [More here.](https://developer.apple.com/documentation/swift_packages/localizing_package_resources)
3. Create a file named `Localizable.strings` under the new language directory and then copy the contents of `Sources/KeyboardShortcuts/Localization/en.lproj/Localizable.strings` into it.
4. Localize and make sure to review your localization multiple times. Check for typos.
5. Try to find someone that speaks your language to review the translation.
6. Submit a PR.

## API

The API surface stays close to upstream `KeyboardShortcuts`, with fork-specific recorder UI behavior.

Most-used APIs:
- `KeyboardShortcutRecorder(for:label:focused:onInteraction:onChange:)`
- `KeyboardShortcuts.onKeyDown(for:action:)` / `KeyboardShortcuts.onKeyUp(for:action:)`
- `KeyboardShortcuts.events(for:)` and `KeyboardShortcuts.events(_:for:)`
- `KeyboardShortcuts.getShortcut(for:)` / `KeyboardShortcuts.setShortcut(_:for:)`
- `KeyboardShortcuts.reset(_:)` / `KeyboardShortcuts.resetAll()`
- `KeyboardShortcuts.enable(_:)` / `KeyboardShortcuts.disable(_:)` / `KeyboardShortcuts.isEnabled(for:)`

Note: Hosted API docs on Swift Package Index currently point to upstream and may not reflect fork-specific UI behavior exactly.

## Tips

#### Show a recorded keyboard shortcut in an `NSMenuItem`

This fork does not include upstream's `NSMenuItem` helper extension, but you can wire it directly:

```swift
if let shortcut = KeyboardShortcuts.getShortcut(for: .toggleUnicornMode) {
	var modifierMask = NSEvent.ModifierFlags()
	if shortcut.modifiers.contains(.command) { modifierMask.insert(.command) }
	if shortcut.modifiers.contains(.option) { modifierMask.insert(.option) }
	if shortcut.modifiers.contains(.shift) { modifierMask.insert(.shift) }
	if shortcut.modifiers.contains(.control) { modifierMask.insert(.control) }

	menuItem.keyEquivalent = shortcut.nsMenuItemKeyEquivalent ?? ""
	menuItem.keyEquivalentModifierMask = modifierMask
} else {
	menuItem.keyEquivalent = ""
	menuItem.keyEquivalentModifierMask = []
}
```

#### Dynamic keyboard shortcuts

Your app might need keyboard shortcuts for user-defined actions. Normally, you statically register names in `extension KeyboardShortcuts.Name {}`. That is optional and mainly for dot-syntax convenience when calling APIs (for example, `KeyboardShortcuts.onKeyDown(for: .unicornMode) {}`). You can also create `KeyboardShortcuts.Name` values dynamically and store them yourself.

#### Default keyboard shortcuts

Setting a default keyboard shortcut can be useful if you're migrating from a different package or just making something for yourself. However, please do not set this for a publicly distributed app. Users find it annoying when random apps steal their existing keyboard shortcuts. It’s generally better to show a welcome screen on the first app launch that lets the user set the shortcut.

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let toggleUnicornMode = Self("toggleUnicornMode", default: .init(.k, modifiers: [.command, .option]))
}
```

#### Get all keyboard shortcuts

To get all keyboard shortcut names, conform `KeyboardShortcuts.Name` to `CaseIterable`.

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let foo = Self("foo")
	static let bar = Self("bar")
}

extension KeyboardShortcuts.Name: CaseIterable {
	public static let allCases: [Self] = [
		.foo,
		.bar
	]
}

// …

print(KeyboardShortcuts.Name.allCases)
```

And to get all names with a configured shortcut:

```swift
print(KeyboardShortcuts.Name.allCases.filter { $0.shortcut != nil })
```

#### Convert modifier flags to symbols

You can get a symbolic representation of modifier flags like this:

```swift
import KeyboardShortcuts

let modifiers = NSEvent.ModifierFlags([.command, .shift])
print(modifiers.ks_symbolicRepresentation)
//=> "⇧⌘"

// Also works with shortcuts:
if let shortcut = KeyboardShortcuts.getShortcut(for: .toggleUnicornMode) {
	print(shortcut.modifiers.description)
	//=> "⌘⌥"
}
```

## FAQ

#### How is it different from [`MASShortcut`](https://github.com/shpakovski/MASShortcut)?

This package:
- Written in Swift with a swifty API.
- More native-looking UI component.
- SwiftUI component included.
- Support for listening to key down, not just key up.
- Swift Package Manager support.
- Works when [`NSMenu` is open](https://github.com/sindresorhus/KeyboardShortcuts/issues/1) (e.g. menu bar apps).

`MASShortcut`:
- More mature.
- More localizations.

#### How is it different from [`HotKey`](https://github.com/soffes/HotKey)?

`HotKey` is good for adding hard-coded keyboard shortcuts, but it doesn't provide any UI component for the user to choose their own keyboard shortcuts.

#### Why is this package importing `Carbon`? Isn't that deprecated?

Most of the Carbon APIs were deprecated years ago, but there are some left that Apple never shipped modern replacements for. This includes registering global keyboard shortcuts. However, you should not need to worry about this. Apple will for sure ship new APIs before deprecating the Carbon APIs used here.

#### Does this package cause any permission dialogs?

No.

#### How can I add an app-specific keyboard shortcut that is only active when the app is?

That is outside the scope of this package. You can either use [`NSEvent.addLocalMonitorForEvents`](https://developer.apple.com/documentation/appkit/nsevent/1534971-addlocalmonitorforevents), [`NSMenuItem` with keyboard shortcut](https://developer.apple.com/documentation/appkit/nsmenuitem/2880316-allowskeyequivalentwhenhidden) (it can even be hidden), or SwiftUI's [`View#keyboardShortcut()` modifier](https://developer.apple.com/documentation/swiftui/form/keyboardshortcut(_:)).

#### Does it support media keys?

No, since it would not work for sandboxed apps. If your app is not sandboxed, you can use [`MediaKeyTap`](https://github.com/nhurden/MediaKeyTap).

#### Can I listen to the Caps Lock key?

No, Caps Lock is a modifier key and cannot be directly listened to using this package's standard event methods. If you need to detect Caps Lock events, you'll need to use lower-level APIs like [`CGEvent.tapCreate`](https://developer.apple.com/documentation/coregraphics/cgevent/1454426-tapcreate).

#### Can you support CocoaPods or Carthage?

No. However, there is nothing stopping you from using Swift Package Manager for just this package even if you normally use CocoaPods or Carthage.

## Related

- [KeyboardShortcuts (upstream)](https://github.com/sindresorhus/KeyboardShortcuts)
- [Example app in this fork](./Example/KeyboardShortcutsExample)
