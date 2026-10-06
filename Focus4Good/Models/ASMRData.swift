import Foundation

struct ASMRData {
    static let playlists: [ASMRPlaylist] = [
        ASMRPlaylist(
            title: "ADHD Focus Mode",
            subtitle: "Boost Concentration",
            purpose: "Helps users concentrate during studying, coding, reading, or work.",
            coverImageName: "adhd_focus",
            placeholderColorHex: "FF3B30",
            sounds: [
                AsmrSound(name: "Brown Noise", description: "Deep and consistent", category: "Noise", audioUrl: "", imageUrl: "brown_noise", durationSeconds: 600),
                AsmrSound(name: "Deep White Noise", description: "Full spectrum", category: "Noise", audioUrl: "", imageUrl: "white_noise", durationSeconds: 600),
                AsmrSound(name: "Pink Noise", description: "Balanced and soft", category: "Noise", audioUrl: "", imageUrl: "pink_noise", durationSeconds: 600),
                AsmrSound(name: "Soft Fan Noise", description: "Steady breeze", category: "Ambient", audioUrl: "", imageUrl: "soft_fan", durationSeconds: 600),
                AsmrSound(name: "Airplane Cabin Hum", description: "In-flight ambience", category: "Ambient", audioUrl: "", imageUrl: "airplane_noise", durationSeconds: 600),
                AsmrSound(name: "Coffee Shop Ambience", description: "Gentle chatter", category: "Ambient", audioUrl: "", imageUrl: "coffeeshop_asmr", durationSeconds: 600),
                AsmrSound(name: "Library Ambience", description: "Quiet and studious", category: "Ambient", audioUrl: "", imageUrl: "library_ambience", durationSeconds: 600),
                AsmrSound(name: "Gentle Keyboard Typing", description: "Mechanical clicks", category: "Ambient", audioUrl: "", imageUrl: "keyboard_typing", durationSeconds: 600),
                AsmrSound(name: "Soft Rain", description: "Cozy focus", category: "Mix", audioUrl: "", imageUrl: "soft rain", durationSeconds: 600),
                AsmrSound(name: "Distant Train Ambience", description: "Rhythmic movement", category: "Ambient", audioUrl: "", imageUrl: "distant_rain", durationSeconds: 600)
            ]
        ),
        ASMRPlaylist(
            title: "Calm an Overstimulated Mind",
            subtitle: "Find your peace",
            purpose: "For when the user feels overwhelmed, overstimulated, or mentally exhausted.",
            coverImageName: "stress",
            placeholderColorHex: "34C759",
            sounds: [
                AsmrSound(name: "Gentle Rain", description: "Light drizzle", category: "Nature", audioUrl: "", imageUrl: "gentle_rain", durationSeconds: 600),
                AsmrSound(name: "Ocean Waves", description: "Rhythmic waves", category: "Nature", audioUrl: "", imageUrl: "ocean_waves", durationSeconds: 600),
                AsmrSound(name: "Forest Birds", description: "Morning chorus", category: "Nature", audioUrl: "", imageUrl: "forest_birds", durationSeconds: 600),
                AsmrSound(name: "Mountain Stream", description: "Flowing water", category: "Nature", audioUrl: "", imageUrl: "mountain_stream", durationSeconds: 600),
                AsmrSound(name: "Wind Through Trees", description: "Soft rustling", category: "Nature", audioUrl: "", imageUrl: "wind_through_trees", durationSeconds: 600),
                AsmrSound(name: "Fireplace Crackling", description: "Warm and cozy", category: "Nature", audioUrl: "", imageUrl: "fireplace_crackling", durationSeconds: 600),
                AsmrSound(name: "Waterfall", description: "Continuous rush", category: "Nature", audioUrl: "", imageUrl: "waterfall", durationSeconds: 600),
                AsmrSound(name: "Light Thunderstorm", description: "Distant rumbles", category: "Nature", audioUrl: "", imageUrl: "light_thunderstorm", durationSeconds: 600),
                AsmrSound(name: "Bamboo Wind Chimes", description: "Gentle tones", category: "Ambient", audioUrl: "", imageUrl: "bamboo_wind_chimes", durationSeconds: 600),
                AsmrSound(name: "Soft River Flow", description: "Tranquil stream", category: "Nature", audioUrl: "", imageUrl: "soft_river_flow", durationSeconds: 600)
            ]
        ),
        ASMRPlaylist(
            title: "Anxiety & Emotional Regulation",
            subtitle: "Soothe your soul",
            purpose: "Helps during anxiety, panic, emotional dysregulation, or after a stressful event.",
            coverImageName: "anxiety",
            placeholderColorHex: "007AFF",
            sounds: [
                AsmrSound(name: "Slow Ocean Waves", description: "Calm and steady", category: "Nature", audioUrl: "", imageUrl: "slow_ocean_waves", durationSeconds: 600),
                AsmrSound(name: "Soft Rain on Window", description: "Gentle pitter-patter", category: "Nature", audioUrl: "", imageUrl: "soft_rain_on_window", durationSeconds: 600),
                AsmrSound(name: "Deep Brown Noise", description: "Grounding and deep", category: "Noise", audioUrl: "", imageUrl: "deep_brown_noise", durationSeconds: 600),
                AsmrSound(name: "Gentle Breathing Sound", description: "Inhale and exhale", category: "Ambient", audioUrl: "", imageUrl: "gentle_breathing_sound", durationSeconds: 600),
                AsmrSound(name: "Singing Bowls", description: "Resonant tones", category: "Ambient", audioUrl: "", imageUrl: "singing_bowls", durationSeconds: 600),
                AsmrSound(name: "Calm Wind", description: "Soft breeze", category: "Nature", audioUrl: "", imageUrl: "calm_wind", durationSeconds: 600),
                AsmrSound(name: "Heartbeat Rhythm", description: "Steady and reassuring", category: "Ambient", audioUrl: "", imageUrl: "heartbeat_rhythm", durationSeconds: 600),
                AsmrSound(name: "Soft Ambient Pads", description: "Ethereal synths", category: "Ambient", audioUrl: "", imageUrl: "soft_ambient_pads", durationSeconds: 600),
                AsmrSound(name: "Crackling Campfire", description: "Warm embers", category: "Nature", audioUrl: "", imageUrl: "ChatGPT Image Jul 5, 2026 at 11_03_37 PM", durationSeconds: 600),
                AsmrSound(name: "Night Nature Sounds", description: "Crickets and owls", category: "Nature", audioUrl: "", imageUrl: "night_nature_sounds", durationSeconds: 600)
            ]
        ),
        ASMRPlaylist(
            title: "ADHD Sleep Support",
            subtitle: "Drift off easily",
            purpose: "Helps users who struggle to turn off their thoughts before sleep.",
            coverImageName: "sleep",
            placeholderColorHex: "5856D6",
            sounds: [
                AsmrSound(name: "Brown Noise for Sleep", description: "Deep masking", category: "Noise", audioUrl: "", imageUrl: "brown_noise_for_sleep", durationSeconds: 600),
                AsmrSound(name: "Pink Noise", description: "Gentle masking", category: "Noise", audioUrl: "", imageUrl: "pink_noise_for_sleep", durationSeconds: 600),
                AsmrSound(name: "Heavy Rain", description: "Continuous downpour", category: "Nature", audioUrl: "", imageUrl: "heavy_rain", durationSeconds: 600),
                AsmrSound(name: "Fan Noise", description: "Steady mechanical hum", category: "Ambient", audioUrl: "", imageUrl: "fan_noise", durationSeconds: 600),
                AsmrSound(name: "Ocean at Night", description: "Dark and rhythmic", category: "Nature", audioUrl: "", imageUrl: "ocean_at_night", durationSeconds: 600),
                AsmrSound(name: "Crickets at Night", description: "Summer evening", category: "Nature", audioUrl: "", imageUrl: "cricket_at_night", durationSeconds: 600),
                AsmrSound(name: "Soft Wind", description: "Gentle midnight breeze", category: "Nature", audioUrl: "", imageUrl: "soft_wind", durationSeconds: 600),
                AsmrSound(name: "Rain on Tent", description: "Cozy camping", category: "Nature", audioUrl: "", imageUrl: "rain_on_tent", durationSeconds: 600),
                AsmrSound(name: "Fireplace at Night", description: "Subtle crackles", category: "Nature", audioUrl: "", imageUrl: "fireplace_at_night", durationSeconds: 600),
                AsmrSound(name: "Air Conditioner Hum", description: "Cool and steady", category: "Ambient", audioUrl: "", imageUrl: "air_conditioner_hum", durationSeconds: 600)
            ]
        ),
        ASMRPlaylist(
            title: "Dopamine & Flow Sessions",
            subtitle: "Stay engaged",
            purpose: "Keeps the brain engaged just enough during repetitive or boring tasks without becoming distracting.",
            coverImageName: "flow",
            placeholderColorHex: "FF9500",
            sounds: [
                AsmrSound(name: "Café + Rain Mix", description: "Perfect balance", category: "Mix", audioUrl: "", imageUrl: "cafe_rainmix", durationSeconds: 600),
                AsmrSound(name: "Forest Stream + Birds", description: "Lively nature", category: "Nature", audioUrl: "", imageUrl: "forest_stream", durationSeconds: 600),
                AsmrSound(name: "Soft Mechanical Hum", description: "Machine room", category: "Ambient", audioUrl: "", imageUrl: "soft_mechanical_hum", durationSeconds: 600),
                AsmrSound(name: "Train Journey", description: "Rhythmic tracks", category: "Ambient", audioUrl: "", imageUrl: "train_journey", durationSeconds: 600),
                AsmrSound(name: "Brown Noise + Keyboard", description: "Working ambience", category: "Mix", audioUrl: "", imageUrl: "brownnoise+keyboard", durationSeconds: 600),
                AsmrSound(name: "Cozy Study Room Ambience", description: "Pages turning", category: "Ambient", audioUrl: "", imageUrl: "cozy_room", durationSeconds: 600),
                AsmrSound(name: "Rain + Thunder (Light)", description: "Dynamic weather", category: "Nature", audioUrl: "", imageUrl: "rain+thunder", durationSeconds: 600),
                AsmrSound(name: "Gentle Vinyl Crackle", description: "Vintage warmth", category: "Ambient", audioUrl: "", imageUrl: "vinyl_crackle", durationSeconds: 600),
                AsmrSound(name: "Spacecraft Cabin Ambience", description: "Sci-fi focus", category: "Ambient", audioUrl: "", imageUrl: "spacecraft", durationSeconds: 600),
                AsmrSound(name: "Cozy Cabin Fireplace", description: "Wood crackling", category: "Nature", audioUrl: "", imageUrl: "cabin_fireplace", durationSeconds: 600)
            ]
        )
    ]
}
