//
//  HelperDateFormatter.swift
//  MVCNotebook
//
//  Created by Gustavo A Ramírez Franco on 6/2/21.
//

import Foundation

enum HerlperDateFormatter {
    
    static var format: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    static func textFrom(date: Date) -> String {
        return format.string(from: date)
    }
}
