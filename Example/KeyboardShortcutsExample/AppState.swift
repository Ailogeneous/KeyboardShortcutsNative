import SwiftUI

@MainActor
final class AppState {
	static let shared = AppState()

	private init() {}
	
	// No longer creating menus programmatically with AppKit.
	// SwiftUI menus are typically defined declaratively in the View hierarchy.
}