//
//  AOC6.swift
//  AOC2023
//
//  Created by Patrizia Heer on 06.12.2023.
//

import Foundation

class AOC6 {

    func run() {

        var sum = 1
        var sums: [Int] = []

        let lines = input.components(separatedBy: "\n")
        if lines.count == 2 {

            let times = lines.first!.components(separatedBy: " ").filter { !$0.isEmpty }
            let records = lines.last!.components(separatedBy: " ").filter { !$0.isEmpty }

            for i in 0..<times.count {
                if let time = Int(times[i]), let record = Int(records[i]) {
                    sums.append(calculatePossibilities(time: time, record: record))
                }
            }
        }

        sums.forEach { sum = sum * $0 }

        print("sum: \(sum)")

    }

    func calculatePossibilities(time: Int, record: Int) -> Int {

        var possibilites = 0

        for i in 1..<time {

            let drivingTime = time - i
            let distanceDrived = drivingTime * i

            if distanceDrived > record {
                possibilites += 1
            } else if possibilites > 0 {
                break
            }

        }


        return possibilites
    }


    var input = """
59707878
430121812131276
"""
}
