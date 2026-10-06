import sys

file_path = "/Users/gu/Desktop/Focus4Good-ios/Focus4Good/Focus4Good/Views/Home/HomeView.swift"

with open(file_path, "r") as f:
    lines = f.readlines()

# Replace lines 91 to 157 (0-indexed 91 to 156) with new plannerCard
new_planner_card = """    @ViewBuilder
    private func plannerCard(height: CGFloat, width: CGFloat) -> some View {
        Button {
            navigationPath.append(HomeDestination.schedule)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(hex: "FFF3EB"))

                HStack(spacing: 0) {
                    // Left: text content
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Let's plan\\nyour day")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color(.label))

                        Text("Create a plan, stay focused\\nand get things done.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(.secondaryLabel))
                            .lineSpacing(2)

                        Spacer(minLength: 8)

                        // CTA
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.orange)
                            }
                            Text("Let's plan")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.trailing, 8)
                        }
                        .padding(.leading, 8)
                        .padding(.trailing, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF9C54"), Color(hex: "FF7A33")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                    }
                    .padding(.leading, 24)
                    .padding(.vertical, 22)
                    .frame(width: width * 0.55, alignment: .leading)

                    Spacer(minLength: 0)

                    // Right: Image asset
                    Image("planner")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width * 0.45, height: height * 0.9)
                        .padding(.trailing, 8)
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(HomeCardButtonStyle())
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }
"""

# Find indices
start_idx_planner = None
end_idx_planner = None

for i, line in enumerate(lines):
    if line.strip() == "private func plannerCard(height: CGFloat, width: CGFloat) -> some View {":
        start_idx_planner = i - 1 # include @ViewBuilder
    if line.strip() == "// MARK: - Stats Row":
        end_idx_planner = i - 1

start_idx_shapes = None
end_idx_shapes = None

for i, line in enumerate(lines):
    if line.strip() == "// MARK: - Planner Illustration (SwiftUI-drawn)":
        start_idx_shapes = i - 1
    if line.strip() == "// MARK: - Leaf Decoration (Focus Points card)":
        end_idx_shapes = i - 1

if start_idx_planner is not None and end_idx_planner is not None and start_idx_shapes is not None and end_idx_shapes is not None:
    # Delete shapes first to not mess up earlier indices
    del lines[start_idx_shapes:end_idx_shapes]
    
    # Replace plannerCard
    lines[start_idx_planner:end_idx_planner] = [new_planner_card]
    
    with open(file_path, "w") as f:
        f.writelines(lines)
    print("Success")
else:
    print(f"Failed to find boundaries: planner={start_idx_planner},{end_idx_planner} shapes={start_idx_shapes},{end_idx_shapes}")

