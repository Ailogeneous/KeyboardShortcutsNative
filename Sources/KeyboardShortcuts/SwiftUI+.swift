import SwiftUI
import Carbon.HIToolbox

extension SwiftUI.EventModifiers {
    /// The Carbon-based modifier flags.
    var carbon: Int {
        var carbonModifiers: Int = 0
        if contains(.capsLock) {
            carbonModifiers |= alphaLock
        }
        if contains(.shift) {
            carbonModifiers |= shiftKey
        }
        if contains(.control) {
            carbonModifiers |= controlKey
        }
        if contains(.option) {
            carbonModifiers |= optionKey
        }
        if contains(.command) {
            carbonModifiers |= cmdKey
        }
        return carbonModifiers
    }

    /// Creates a set of modifier flags from Carbon-based modifier flags.
    init(carbon: Int) {
        self.init()
        if carbon & alphaLock != 0 {
            insert(.capsLock)
        }
        if carbon & shiftKey != 0 {
            insert(.shift)
        }
        if carbon & controlKey != 0 {
            insert(.control)
        }
        if carbon & optionKey != 0 {
            insert(.option)
        }
        if carbon & cmdKey != 0 {
            insert(.command)
        }
    }
}

extension SwiftUI.EventModifiers: @retroactive CustomStringConvertible {
	public var description: String {
		var description = ""

		if contains(.control) {
			description += "⌃"
		}

		if contains(.option) {
			description += "⌥"
		}

		if contains(.shift) {
			description += "⇧"
		}

		if contains(.command) {
			description += "⌘"
		}
        
        // SwiftUI.EventModifiers does not have a function case.
        // if contains(.function) {
        //     description += "🌐︎"
        // }

		return description
	}
}
