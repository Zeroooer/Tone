//
//  ToneNote.swift
//  Tone
//
//  Created by Hisen on 2017/7/6.
//  Copyright © 2017年 Hisen. All rights reserved.
//

import Foundation
import RealmSwift

class ToneNote: Object {
    
    dynamic var title = ""
    dynamic var fileName = ""
    dynamic var duration = 0
    dynamic var createDate = NSDate()
    
    //read-only property automatically ignored
    var toneNoteDesc : String {
        return "ToneNote {\n\ttitle = \(title)\n\tfileName = \(fileName)\n\tduration = \(duration)\n\tcreatedAt = \(createDate)\n}"
    }
    
// Specify properties to ignore (Realm won't persist these)
//  override static func ignoredProperties() -> [String] {
//  }
}
