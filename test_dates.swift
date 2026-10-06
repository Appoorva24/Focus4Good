import Foundation

let cal = Calendar.current
let targetDate = cal.date(from: DateComponents(year: 2026, month: 6, day: 20))!

let startDate = cal.date(from: DateComponents(year: 2026, month: 6, day: 20))!
let endDate = cal.date(from: DateComponents(year: 2026, month: 6, day: 22))!

let targetComponents = cal.dateComponents([.year, .month, .day, .weekday], from: targetDate)
let targetYMD = targetComponents.year! * 10000 + targetComponents.month! * 100 + targetComponents.day!

let startComponents = cal.dateComponents([.year, .month, .day, .weekday], from: startDate)
let startYMD = startComponents.year! * 10000 + startComponents.month! * 100 + startComponents.day!

print("Target YMD: \(targetYMD)")
print("Start YMD: \(startYMD)")

if targetYMD < startYMD {
    print("Filter: target < start -> false")
}

let endComponents = cal.dateComponents([.year, .month, .day], from: endDate)
let endYMD = endComponents.year! * 10000 + endComponents.month! * 100 + endComponents.day!
print("End YMD: \(endYMD)")
if targetYMD > endYMD {
    print("Filter: target > end -> false")
}

print("Filter returns true!")

