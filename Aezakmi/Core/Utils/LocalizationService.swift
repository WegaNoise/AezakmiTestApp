//
//  LocalizationService.swift
//  Aezakmi
//
//  Created by petar on 05.02.2026.
//

import Foundation

enum LocalizationService {
  static func localizedString(_ key: String, comment: String = "") -> String {
    NSLocalizedString(key, comment: comment)
  }
}

extension String {
  var localized: String {
    NSLocalizedString(self, comment: "")
  }
  
  func localized(_ arguments: CVarArg...) -> String {
    let format = NSLocalizedString(self, comment: "")
    return String(format: format, arguments: arguments)
  }
}
