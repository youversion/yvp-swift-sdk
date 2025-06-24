import Foundation

final class ThreadSafeDictionary<Key: Hashable, Value>: @unchecked Sendable {
    private var dictionary: [Key: Value] = [:]
    private let queue = DispatchQueue(label: "com.youversion.yvp.ThreadSafeDictionary.\(UUID().uuidString)",
                                      attributes: .concurrent)

    subscript(key: Key) -> Value? {
        get {
            queue.sync { // Synchronous read
                dictionary[key]
            }
        }
        set {
            queue.async(flags: .barrier) { // Asynchronous write with barrier
                // If newValue is nil, remove the key, otherwise set it.
                if let value = newValue {
                    self.dictionary[key] = value
                } else {
                    self.dictionary.removeValue(forKey: key)
                }
            }
        }
    }

    func getValue(forKey key: Key) -> Value? {
        queue.sync {
            dictionary[key]
        }
    }

    func setValue(_ value: Value?, forKey key: Key) {
        queue.async(flags: .barrier) {
            if let value = value {
                self.dictionary[key] = value
            } else {
                self.dictionary.removeValue(forKey: key)
            }
        }
    }

    func removeValue(forKey key: Key) {
        queue.async(flags: .barrier) {
            self.dictionary.removeValue(forKey: key)
        }
    }

    func removeAll() {
        queue.async(flags: .barrier) {
            self.dictionary.removeAll()
        }
    }

    var count: Int {
        queue.sync {
            dictionary.count
        }
    }

    var isEmpty: Bool {
        queue.sync {
            dictionary.isEmpty
        }
    }
}
