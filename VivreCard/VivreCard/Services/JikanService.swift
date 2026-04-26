import Foundation
import Combine

// MARK: - Jikan API Models
struct JikanCharacterResponse: Codable {
    let data: [JikanCharacterEntry]
}

struct JikanCharacterEntry: Codable {
    let character: JikanCharacter
    let role: String
}

struct JikanCharacter: Codable, Identifiable {
    let malId: Int
    let name: String
    let images: JikanImages

    var id: Int { malId }

    enum CodingKeys: String, CodingKey {
        case malId = "mal_id"
        case name
        case images
    }
}

struct JikanImages: Codable {
    let jpg: JikanImageURL
}

struct JikanImageURL: Codable {
    let imageUrl: String

    enum CodingKeys: String, CodingKey {
        case imageUrl = "image_url"
    }
}

// MARK: - Jikan Service
class JikanService: ObservableObject {

    // Explicit API URL — fetches One Piece characters from MyAnimeList via Jikan
    private let apiURL = "https://api.jikan.moe/v4/anime/21/characters"

    @Published var famousPirates: [FamousPirate] = []
    @Published var isLoading = false
    @Published var error: String?

    // Known bounties — keys match Jikan API name format exactly
    private let bounties: [String: String] = [
        "Luffy":                "3,000,000,000",
        "Monkey D. Luffy":      "3,000,000,000",
        "Zoro":                 "1,111,000,000",
        "Roronoa Zoro":         "1,111,000,000",
        "Sanji":                "1,032,000,000",
        "Vinsmoke Sanji":       "1,032,000,000",
        "Nami":                 "366,000,000",
        "Usopp":                "500,000,000",
        "Chopper":              "1,000",
        "Tony Tony Chopper":    "1,000",
        "Robin":                "930,000,000",
        "Nico Robin":           "930,000,000",
        "Franky":               "394,000,000",
        "Brook":                "383,000,000",
        "Jinbe":                "1,100,000,000",
        "Jimbei":               "1,100,000,000",
        "Law":                  "3,000,000,000",
        "Trafalgar Law":        "3,000,000,000",
        "Trafalgar D. Water Law": "3,000,000,000",
        "Kid":                  "3,000,000,000",
        "Eustass Kid":          "3,000,000,000",
        "Eustass \"Captain\" Kid": "3,000,000,000",
        "Shanks":               "4,048,900,000",
        "Blackbeard":           "2,247,600,000",
        "Marshall D. Teach":    "2,247,600,000",
        "Mihawk":               "3,590,000,000",
        "Dracule Mihawk":       "3,590,000,000",
        "Hancock":              "1,659,000,000",
        "Boa Hancock":          "1,659,000,000",
        "Buggy":                "3,189,000,000",
        "Buggy the Clown":      "3,189,000,000",
        "Whitebeard":           "5,046,000,000",
        "Edward Newgate":       "5,046,000,000",
        "Roger":                "5,564,800,000",
        "Gol D. Roger":         "5,564,800,000",
    ]

    func fetchFamousPirates() {
        guard famousPirates.isEmpty else { return }
        isLoading = true
        error = nil

        guard let url = URL(string: apiURL) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(JikanCharacterResponse.self, from: data)
                let bounties = self.bounties

                // Print all main character names so we can match them
                response.data.filter { $0.role == "Main" }.forEach {
                    print("Jikan character: \($0.character.name)")
                }

                let pirates: [FamousPirate] = response.data
                    .filter { $0.role == "Main" }
                    .compactMap { entry in
                        guard let bounty = bounties[entry.character.name] else { return nil }
                        return FamousPirate(
                            id: entry.character.malId,
                            name: entry.character.name,
                            imageURL: entry.character.images.jpg.imageUrl,
                            bounty: bounty
                        )
                    }
                    .sorted { a, b in
                        let aVal = Int(a.bounty.replacingOccurrences(of: ",", with: "")) ?? 0
                        let bVal = Int(b.bounty.replacingOccurrences(of: ",", with: "")) ?? 0
                        return aVal > bVal
                    }

                await MainActor.run {
                    self.famousPirates = pirates
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load pirates"
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Famous Pirate Model
struct FamousPirate: Identifiable {
    let id: Int
    let name: String
    let imageURL: String
    let bounty: String
}
