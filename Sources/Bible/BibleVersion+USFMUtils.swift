import Foundation

extension BibleVersion {
    
    public func reference(with usfm: String) -> BibleReference? {
        guard isReady else {
            return nil
        }

        let trimmedUSFM = usfm.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmedUSFM.count >= 3 else {
            return nil
        }

        // if there's a range indicated with + characters, return the first valid range:
        let subUSFMs = trimmedUSFM.split(separator: "+")
        if subUSFMs.count > 1 {
            let refs = subUSFMs.compactMap { reference(with: String($0)) }
            let merged = BibleReference.referencesByMerging(references: refs.compactMap { $0 })
            return merged.first
        }
        
        guard let reference = BibleReference.unvalidatedReference(with: usfm, versionId: id),
              isBookUSFMValid(reference.bookUSFM) else {
            return nil
        }
        return reference
        // TODO: check that the chapter and verse numbers are valid for this version.
    }
}
