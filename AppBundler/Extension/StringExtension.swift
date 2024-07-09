import Foundation

extension String {
    func removePathExtension() -> String {
        let fileComponents = self.split(separator: ".")
        if fileComponents.count < 2 {
            return self
        }
        
        return String(fileComponents[0])
    }
    
    func isNotEmpty() -> Bool {
        return !self.isEmpty
    }
}

extension Substring {
    func toString() -> String {
        return String(self)
    }
}
