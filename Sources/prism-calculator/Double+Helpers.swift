//
//  File.swift
//  
//
//  Created by Nisse Bergman on 2023-01-04.
//

import Foundation


precedencegroup ExponentiativePrecedence {
    associativity: right
    higherThan: MultiplicationPrecedence
}

infix operator ^: ExponentiativePrecedence

func ^ (num: Double, power: Double) -> Double {
    return pow(num, power)
}

extension Double {
    var degrees: Double {
        self * 360 / (.pi * 2)
    }

    var radians: Double {
        self * .pi * 2 / 360
    }
}

extension Double {
    func toFixed(fractions: ClosedRange<Int> = 2 ... 4) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en-US")
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        formatter.minimumFractionDigits = fractions.lowerBound
        formatter.maximumFractionDigits = fractions.upperBound

        return formatter.string(for: self) ?? "N/A"
    }
}
