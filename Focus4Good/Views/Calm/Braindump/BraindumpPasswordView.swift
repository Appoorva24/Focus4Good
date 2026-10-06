import SwiftUI

struct BraindumpPasswordView: View {

    @State private var enteredPin = ""
    @State private var isUnlocked = false
    @State private var storedPin = UserDefaults.standard.string(forKey: "braindump_pin")
    @State private var isSettingPin = false
    @State private var confirmPin = ""
    @State private var showError = false

    private let pinLength = 4

    var body: some View {
        if isUnlocked {
            BraindumpHomeView()
        } else {
            pinEntryScreen
        }
    }

    private var currentPin: String {
        isSettingPin && !confirmPin.isEmpty ? confirmPin : enteredPin
    }

    private var screenTitle: String {
        if storedPin == nil && !isSettingPin { return "Set PIN" }
        if isSettingPin && enteredPin.count == pinLength { return "Confirm PIN" }
        if isSettingPin { return "Create a PIN" }
        return "Enter PIN"
    }

    private var screenSubtitle: String {
        if isSettingPin && enteredPin.count == pinLength {
            return "Re-enter your 4-digit PIN to confirm"
        }
        return isSettingPin
            ? "Set a 4-digit PIN to protect your entries"
            : "Enter your 4-digit PIN to unlock"
    }

    private var errorMessage: String {
        isSettingPin ? "PINs didn't match. Try again." : "Incorrect PIN. Try again."
    }

    // MARK: - PIN Entry Screen

    private var pinEntryScreen: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text(screenTitle)
                .font(.title3)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                ForEach(0..<pinLength, id: \.self) { index in
                    Circle()
                        .fill(index < currentPin.count ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 16, height: 16)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: currentPin.count)

            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            Spacer()

            numberPad.padding(.bottom, 40)
        }
        .padding(.horizontal, 40)
        .navigationTitle("Braindump")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            storedPin = UserDefaults.standard.string(forKey: "braindump_pin")
            if storedPin == nil { isSettingPin = true }
        }
    }

    // MARK: - Number Pad

    private var numberPadRows: [[String]] {
        [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", "delete"]]
    }

    private var numberPad: some View {
        VStack(spacing: 16) {
            ForEach(numberPadRows, id: \.self) { row in
                HStack(spacing: 24) {
                    ForEach(row, id: \.self) { key in
                        numberKey(key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func numberKey(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(width: 72, height: 72)
        } else if key == "delete" {
            Button { deleteDigit() } label: {
                Image(systemName: "delete.left")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 72, height: 72)
            }
        } else {
            Button { addDigit(key) } label: {
                Text(key)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(Color(.systemGray6)))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - PIN Logic

    private func addDigit(_ digit: String) {
        showError = false

        if isSettingPin && enteredPin.count == pinLength {
            guard confirmPin.count < pinLength else { return }
            confirmPin += digit
            if confirmPin.count == pinLength { validateNewPin() }
            return
        }

        guard enteredPin.count < pinLength else { return }
        enteredPin += digit

        if enteredPin.count == pinLength && !isSettingPin {
            validateExistingPin()
        }
    }

    private func deleteDigit() {
        if isSettingPin && enteredPin.count == pinLength && !confirmPin.isEmpty {
            confirmPin = String(confirmPin.dropLast())
        } else {
            enteredPin = String(enteredPin.dropLast())
        }
        showError = false
    }

    private func validateNewPin() {
        if enteredPin == confirmPin {
            UserDefaults.standard.set(enteredPin, forKey: "braindump_pin")
            storedPin = enteredPin
            withAnimation { isUnlocked = true }
        } else {
            withAnimation { showError = true }
            enteredPin = ""
            confirmPin = ""
        }
    }

    private func validateExistingPin() {
        if enteredPin == storedPin {
            withAnimation { isUnlocked = true }
        } else {
            withAnimation { showError = true }
            enteredPin = ""
        }
    }
}

#Preview {
    NavigationStack {
        BraindumpPasswordView()
    }
}
