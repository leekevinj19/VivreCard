import Foundation
import Combine

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

class JikanService: ObservableObject {
    private let jikanCharactersURL = URL(string: "https://api.jikan.moe/v4/anime/21/characters")!
    private let onePieceCharactersURL = URL(string: "https://onepieceapi.com/api/characters?limit=500")!

    @Published var famousPirates: [FamousPirate] = []
    @Published var isLoading = false
    @Published var error: String?

    func fetchFamousPirates(force: Bool = false) {
        if !force, !famousPirates.isEmpty {
            return
        }

        isLoading = true
        error = nil

        Task {
            do {
                async let jikanCharacters = fetchJikanCharacters()
                async let onePieceCharacters = fetchOnePieceCharacters()
                let (jikanEntries, bountyCharacters) = try await (jikanCharacters, onePieceCharacters)

                let pirates = makeFamousPirates(
                    jikanEntries: jikanEntries,
                    onePieceCharacters: bountyCharacters
                )

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

    private func fetchJikanCharacters() async throws -> [JikanCharacterEntry] {
        let data = try await fetchData(from: jikanCharactersURL)
        return try JSONDecoder().decode(JikanCharacterResponse.self, from: data).data
    }

    private func fetchOnePieceCharacters() async throws -> [OnePieceCharacter] {
        let data = try await fetchData(from: onePieceCharactersURL)
        return try JSONDecoder().decode([OnePieceCharacter].self, from: data)
    }

    private func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return data
    }

    private func makeFamousPirates(
        jikanEntries: [JikanCharacterEntry],
        onePieceCharacters: [OnePieceCharacter]
    ) -> [FamousPirate] {
        let imagesByName = jikanEntries.reduce(into: [String: JikanCharacter]()) { result, entry in
            result[entry.character.name.normalizedPirateName] = entry.character
        }

        return onePieceCharacters
            .compactMap { character -> FamousPirate? in
                guard let name = character.displayName,
                      let bounty = character.currentBounty,
                      let jikanCharacter = imagesByName[name.normalizedPirateName] else {
                    return nil
                }

                return FamousPirate(
                    id: jikanCharacter.malId,
                    name: name,
                    imageURL: jikanCharacter.images.jpg.imageUrl,
                    bounty: bounty
                )
            }
            .sorted { $0.bounty > $1.bounty }
    }
}

struct FamousPirate: Identifiable {
    let id: Int
    let name: String
    let imageURL: String
    let bounty: Int
}

struct OnePieceCharacter: Decodable {
    let id: String
    let name: LocalizedName?
    let bounties: [OnePieceBounty]

    var displayName: String? {
        name?.en ?? name?.romaji ?? name?.jp
    }

    var currentBounty: Int? {
        let activeBounties = bounties.filter(\.isActive).compactMap(\.amount)
        return activeBounties.max() ?? bounties.compactMap(\.amount).max()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bounties
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(LocalizedName.self, forKey: .name)
        bounties = try container.decodeIfPresent([OnePieceBounty].self, forKey: .bounties) ?? []
    }
}

struct LocalizedName: Decodable {
    let en: String?
    let jp: String?
    let romaji: String?

    enum CodingKeys: String, CodingKey {
        case en
        case jp
        case romaji
    }

    init(from decoder: Decoder) throws {
        if let singleValue = try? decoder.singleValueContainer(),
           let name = try? singleValue.decode(String.self) {
            en = name
            jp = nil
            romaji = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        en = try container.decodeIfPresent(String.self, forKey: .en)
        jp = try container.decodeIfPresent(String.self, forKey: .jp)
        romaji = try container.decodeIfPresent(String.self, forKey: .romaji)
    }
}

struct OnePieceBounty: Decodable {
    let amount: Int?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case amount
        case isActive = "is_active"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let amount = try? container.decodeIfPresent(Int.self, forKey: .amount) {
            self.amount = amount
        } else if let amount = try? container.decodeIfPresent(String.self, forKey: .amount) {
            self.amount = Int(amount.filter(\.isNumber))
        } else {
            self.amount = nil
        }

        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
    }
}

private extension String {
    var normalizedPirateName: String {
        lowercased()
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "captain", with: "")
            .replacingOccurrences(of: "theclown", with: "")
            .replacingOccurrences(of: "thestarclown", with: "")
    }
}
