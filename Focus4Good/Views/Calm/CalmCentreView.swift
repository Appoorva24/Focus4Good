import SwiftUI

struct CalmCentreView: View {

    @State private var showBraindump = false
    @State private var showBreathe = false
    @State private var showJPMR = false
    @State private var showASMR = false
    @State private var showDeepFocus = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Button { showBraindump = true } label: { braindumpCard }
                        .buttonStyle(.plain)

                    relaxationToolsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
            .scrollDisabled(true)
            .background(AppTheme.appGradient.ignoresSafeArea())
            .navigationTitle("Calm Centre")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showBraindump) { BraindumpHomeView() }
            .navigationDestination(isPresented: $showBreathe) { BreatheSessionView() }
            .navigationDestination(isPresented: $showJPMR) { JPMRSessionView() }
            .navigationDestination(isPresented: $showASMR) { SensorySootheView() }
            .navigationDestination(isPresented: $showDeepFocus) { DeepFocusBrowseView() }
        }
    }

    // MARK: - Subviews

    private var braindumpCard: some View {
        Image("BRAINDUMPCARD")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Braindump")
                        .font(.system(.title3, design: .default, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("Get the noise out\nof your head.")
                        .font(.system(.caption2, design: .default, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    
                    Spacer().frame(height: 2)
                    
                    HStack(spacing: 4) {
                        Text("Start Dumping")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                    }
                    .font(.system(.caption, design: .default, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(Capsule())
                }
                .padding(.leading, 18)
                .padding(.trailing, 160)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var relaxationToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Relaxation Tools")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            LazyVGrid(columns: columns, spacing: 16) {
                breatheCard
                jpmrCard
                asmrCard
                deepFocusCard
            }
        }
    }

    private var breatheCard: some View {
        Button { showBreathe = true } label: {
            VStack(spacing: 0) {
                Image("breathe")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(1.15)
                    .offset(x: -15, y: 12)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 130, maxHeight: 130)
                    .clipped()
                
                VStack(alignment: .center) {
                    Text("4-7-8 Breathing Technique")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(height: 44)
                .background(Color(.secondarySystemGroupedBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var jpmrCard: some View {
        Button { showJPMR = true } label: {
            VStack(spacing: 0) {
                Image("JPMR")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(1.15)
                    .offset(y: 12)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 130, maxHeight: 130)
                    .clipped()
                
                VStack(alignment: .center) {
                    Text("Muscle Relaxation")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(height: 44)
                .background(Color(.secondarySystemGroupedBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var asmrCard: some View {
        Button { showASMR = true } label: {
            VStack(spacing: 0) {
                Image("ASMR")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                    .clipped()
                
                VStack(alignment: .center) {
                    Text("ASMR Sounds")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(height: 44)
                .background(Color(.secondarySystemGroupedBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var deepFocusCard: some View {
        Button { showDeepFocus = true } label: {
            VStack(spacing: 0) {
                Image("DEEPFOCUS")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(1.3)
                    .offset(x: 5, y: 0)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                    .clipped()
                
                VStack(alignment: .center) {
                    Text("Deep Focus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(height: 44)
                .background(Color(.secondarySystemGroupedBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CalmCentreView()
        .environment(CalmCentreStore.shared)
}
