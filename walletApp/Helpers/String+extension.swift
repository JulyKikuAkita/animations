//
//  String+extension.swift
//  animation

public extension String {
    func group(_ character: Character, count: Int) -> String {
        var modifiedString = self.replacingOccurrences(of: String(character), with: "")
        
        for index in 0..<modifiedString.count {
            if index % count == 0 && index != 0 {
                let groupCharactersCount = modifiedString.count(where: { $0 == character })
                let stringIndex = modifiedString.index(
                    modifiedString.startIndex,
                    offsetBy: index + groupCharactersCount
                )
                modifiedString.insert(character, at: stringIndex)
            }
        }
        
        return modifiedString
    }
    
    func dummyText(_ character: Character, count: Int) -> String {
        var tmpText = self.replacingOccurrences(of: String(character), with: "")
        let remaining = min(max(count - tmpText.count, 0), count)
        
        if remaining > 0 {
            tmpText.append(String(repeating: character, count: remaining))
        }
        
        return tmpText
    }
}
