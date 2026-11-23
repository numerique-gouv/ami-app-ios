// Generated from full-cases.env — do not edit

import Foundation

// swiftlint:disable all
// swiftformat:disable all

nonisolated enum Secrets {
    static let intValue = 42
    static let negativeValue = -7
    static let doubleValue = 3.14
    static let boolValue = true
    static let stringValue = "hello"
    static let emptyString = ""
    static let expressionValue = 40.0 + 2.0
    static let concatenation = "sub" + ".example.org"
    static let scalarWithComment = 42 // the answer
    static let noSpaces = "tight"
    static let spacedKey = "spaced"
    static let tabIndented = "tabs"
    static let mixedcaseKey = "every part is lowercased first"
    static let doubleUnderscore = "empty parts are skipped"
    static let keyWithDigits2fa = "digits"
    static let equalsInValue = "a=b&c=d"
    static let afterBackslashComment = "still parsed"
    static let urlWithSlashes = "https://example.org/path" // a real comment
    static let bracketsInString = "[not] a list"
    static let stringStartingWithBracket = "[x]"
    static let escapedQuotes = "say \"hi\"" // comment with \"quotes\"
    static let backslashes = "C:\\Users\\me"
    static let regex = "^(.+\\.)?app\\.example\\.org$"
    static let hashInString = "#not-a-comment"
    static let unicode = "café ☕️"
    static let stringAcrossLines = "abcdef"
    static let expressionAcrossLines = 40.0 + 2.0
    static let valueOnNextLine = "value on next line"
    static let escapedBackslashAtBreak = "end\\tail"
    static let commentAcrossLines = "value" // first part second part of the same comment
    static let commentMarkerSplit = "value" // split comment marker
    static let commaInsideString = "abcd,efghi" // comment with , (comma) // and a second marker
    static let inlineList = [
        "a",
        "b",
        "c"
    ]
    static let inlineListTrailingComma = [
        1,
        2,
        3,
    ]
    static let inlineListWithComment = [
        1,
        2
    ] // trailing comment
    static let multilineList = [
        "one",
        "two",
        "three"
    ]
    static let multilineTrailingComma = [
        "one",
        "two",
    ]
    static let itemsWithComments = [
        "a", // after a
        "b" // after b, with a comma
    ]
    static let commentsOnOwnLines = [
        // leading comment
        "a",
        // between items
        "b",
    ]
    static let quotesInComments = [
        "a", // see "b", "c"
        "d", // weird \"x"
        "e"
    ]
    static let closingBracketInside = [
        "]x", // has ]
        "y"
    ]
    static let commaInStringItem = [
        "a,b",
        "c"
    ]
    static let expressionItems = [
        "sub4" + ".example.org",
        "sub5.example.org",
    ]
    static let numberItems = [
        1 + 2,
        40.0
    ]
    static let stringItemAcrossLines = [
        "long-value",
        "short"
    ]
    static let commentAfterClosingSameLine = [
        "a",
        "b"
    ] // same-line tail
    static let commentAfterClosingNextLine = [
        "a",
        "b"
    ] // next-line tail
    static let listOnNextLine = [
        "a", // after a
        "b"
    ]
    static let inlineListOnNextLine = [
        "x",
        "y"
    ]
    static let valueAfterEmptyContinuation = "after an empty continuation line"
    static let nestedInline = [[1, 2], [3]]
    static let listPlusList = [1, 2] + [3]
    static let notAListMultiline = [ "a", "b" ] + ["c"]
    static let lastLineContinued = "end"
}

// swiftformat:enable all
// swiftlint:enable all
