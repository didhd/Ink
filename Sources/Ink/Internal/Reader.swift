internal struct Reader {
    private let string: String
    private(set) var currentIndex: String.Index
    
    init(string: String) {
        self.string = string
        self.currentIndex = string.startIndex
    }
}

extension Reader {
    struct Error: Swift.Error {}
    
    var didReachEnd: Bool { currentIndex >= endIndex }
    var previousCharacter: Character? { lookBehindAtPreviousCharacter() }
    var currentCharacter: Character {
        guard currentIndex < endIndex else {
            return "\0" // Null character as a sentinel value
        }
        return string[currentIndex]
    }
    var nextCharacter: Character? { lookAheadAtNextCharacter() }
    var endIndex: String.Index { string.endIndex }
    
    func characters(in range: Range<String.Index>) -> Substring {
        return string[range]
    }
    
    mutating func read(_ character: Character) throws {
        guard !didReachEnd else { throw Error() }
        guard currentCharacter == character else { throw Error() }
        advanceIndex()
    }
    
    @discardableResult
    mutating func read(until character: Character,
                       required: Bool = true,
                       allowWhitespace: Bool = true,
                       allowLineBreaks: Bool = false,
                       balanceAgainst balancingCharacter: Character? = nil) throws -> Substring {
        let startIndex = currentIndex
        var characterBalance = 0
        
        while !didReachEnd {
            guard currentCharacter != character || characterBalance > 0 else {
                let result = string[startIndex..<currentIndex]
                advanceIndex()
                return result
            }
            
            if !allowWhitespace, currentCharacter.isSameLineWhitespace {
                break
            }
            
            if !allowLineBreaks, currentCharacter.isNewline {
                break
            }
            
            if let balancingCharacter = balancingCharacter {
                if currentCharacter == balancingCharacter {
                    characterBalance += 1
                }
                
                if currentCharacter == character {
                    characterBalance -= 1
                }
            }
            
            advanceIndex()
        }
        
        if required { throw Error() }
        return string[startIndex..<currentIndex]
    }
    
    mutating func readCount(of character: Character) -> Int {
        var count = 0
        
        while !didReachEnd && currentCharacter == character {
            count += 1
            advanceIndex()
        }
        
        return count
    }
    
    @discardableResult
    mutating func readCharacters(matching keyPath: KeyPath<Character, Bool>,
                                 max maxCount: Int = Int.max) throws -> Substring {
        let startIndex = currentIndex
        var count = 0
        
        while !didReachEnd && count < maxCount && currentCharacter[keyPath: keyPath] {
            advanceIndex()
            count += 1
        }
        
        guard startIndex != currentIndex else {
            throw Error()
        }
        
        return string[startIndex..<currentIndex]
    }
    
    @discardableResult
    mutating func readCharacter(in set: Set<Character>) throws -> Character {
        guard !didReachEnd else { throw Error() }
        guard currentCharacter.isAny(of: set) else { throw Error() }
        defer { advanceIndex() }
        
        return currentCharacter
    }
    
    @discardableResult
    mutating func readWhitespaces() throws -> Substring {
        try readCharacters(matching: \.isSameLineWhitespace)
    }
    
    mutating func readUntilEndOfLine() -> Substring {
        let startIndex = currentIndex
        
        while !didReachEnd && !currentCharacter.isNewline {
            advanceIndex()
        }
        
        let result = string[startIndex..<currentIndex]
        if !didReachEnd && currentCharacter.isNewline {
            advanceIndex()
        }
        return result
    }
    
    mutating func discardWhitespaces() {
        while !didReachEnd && currentCharacter.isSameLineWhitespace {
            advanceIndex()
        }
    }
    
    mutating func discardWhitespacesAndNewlines() {
        while !didReachEnd && currentCharacter.isWhitespace {
            advanceIndex()
        }
    }
    
    mutating func advanceIndex(by offset: Int = 1) {
        let newIndex = string.index(currentIndex, offsetBy: offset, limitedBy: endIndex) ?? endIndex
        currentIndex = newIndex
    }
    
    mutating func rewindIndex() {
        guard currentIndex > string.startIndex else { return }
        currentIndex = string.index(before: currentIndex)
    }
    
    mutating func moveToIndex(_ index: String.Index) {
        currentIndex = min(max(index, string.startIndex), string.endIndex)
    }
}

private extension Reader {
    func lookBehindAtPreviousCharacter() -> Character? {
        guard currentIndex > string.startIndex else { return nil }
        let previousIndex = string.index(before: currentIndex)
        return string[previousIndex]
    }
    
    func lookAheadAtNextCharacter() -> Character? {
        guard currentIndex < string.index(before: endIndex) else { return nil }
        let nextIndex = string.index(after: currentIndex)
        return string[nextIndex]
    }
}
