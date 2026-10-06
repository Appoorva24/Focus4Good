import Foundation

struct DummyData {

    static let currentUser = User(
        id: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F") ?? UUID(),
        fullName: "Appoorva Khajuria",
        email: "appoorva2025@gmail.com",
        profileImageUrl: nil,
        authProvider: "email",
        focusPoints: 0,
        currentLevel: 1,
        bestStreak: 0,
        currentStreak: 0
    )

    // No pre-loaded tasks — user adds their own
    static let tasks: [UserTask] = []

    static let ngos: [NGO] = [
        NGO(
            id: UUID(),
            name: "Sondhara Welfare Trust",
            location: "Maharashtra, India",
            mission: "Empowering communities through sustainable development, education, and welfare programs.",
            founderName: "Sondhara Trust",
            founderPhone: "+91-00000-00000",
            imageName: "sondhara_logo",
            studentCount: 38000,
            yearsActive: 15,
            projectCount: 12,
            isVerified: true,
            galleryImages: ["ngo", "ngo", "ngo", "ngo"]
        )
    ]

    static func volunteerEvents(for ngoId: UUID) -> [VolunteerEvent] {
        [
            VolunteerEvent(
                id: UUID(),
                ngoId: ngoId,
                title: "Teaching Drive — South Delhi",
                location: "South Delhi",
                eventDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                participantCount: 24
            ),
            VolunteerEvent(
                id: UUID(),
                ngoId: ngoId,
                title: "Community Awareness Walk",
                location: "Connaught Place, Delhi",
                eventDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
                participantCount: 50
            )
        ]
    }



    static let onboardingPages: [(title: String, subtitle: String, imageName: String)] = [
        ("Struggling with ADHD?", "Easily distracted? Overwhelmed by simple tasks?\nDon't worry. We got you!", "o1"),
        ("Plan Your Day", "Easily create tasks and manage your daily schedule with smart pomodoro sessions", "o2"),
        ("Master Hyperactivity", "Access smart sensory tools, guided meditation and relaxation tools to help with your hyperactivity", "o4"),
        ("You Are Not Alone", "Connect with people who suffer from ADHD, and find your safe space", "o5")
    ]
}
