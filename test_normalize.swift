import Foundation

let cal = Calendar.current
let now = Date()

print("Now:", now)

let datePickerDate = cal.date(from: DateComponents(year: 2026, month: 6, day: 25, hour: 12, minute: 30))!
print("DatePicker Date:", datePickerDate)

let normalizedDate = cal.startOfDay(for: datePickerDate)
print("Normalized Date:", normalizedDate)

let targetDate = cal.date(from: DateComponents(year: 2026, month: 6, day: 25))!
let targetDayStart = cal.startOfDay(for: targetDate)
print("Target Day Start:", targetDayStart)

let targetComponents = cal.dateComponents([.year, .month, .day, .weekday], from: targetDayStart)
let targetYMD = targetComponents.year! * 10000 + targetComponents.month! * 100 + targetComponents.day!

let startComponents = cal.dateComponents([.year, .month, .day, .weekday], from: normalizedDate)
let startYMD = startComponents.year! * 10000 + startComponents.month! * 100 + startComponents.day!

print("Target YMD:", targetYMD)
print("Start YMD:", startYMD)

if targetYMD == startYMD {
    print("MATCHES!")
} else {
    print("NO MATCH!")
}

