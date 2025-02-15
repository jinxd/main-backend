import Foundation
import Vapor
import WebSocketKit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct Move: Codable, Equatable {
    let isPlayer1: Bool
        let word: String
}

struct Game: Content, Codable, Equatable {
    var id: String
        var player1Id: String
        var player2Id = ""
        var blockMoveForPlayerId: String
        var winningPlayerId: String = ""
        var challengingUserId: String = ""
        var rematchPlayerId: [String]
        var moves: [Move]
        var createdAt: String = {
            let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                return formatter.string(from: Date())
        }()
}

@globalActor
actor SuperGameService: GlobalActor {
    static let shared = SuperGameService()
        private var games: [String: Game] = [:]
        private var sockets: [String: [WebSocket]] = [:]
        private let logger = Logger(label: "super.ghost.gameservice")
        private init() {}

    func getEmptyGame() -> Game? {
        return games.values.first(where: { $0.player2Id.isEmpty })
    }

    func createGame(player1Id: String, isPrivate: Bool = false) -> Game {
        let gameId = UUID().uuidString
            let game = Game(
                    id: gameId,
                    player1Id: player1Id,
                    player2Id: isPrivate ? "privateGame" : "",
                    blockMoveForPlayerId: player1Id,
                    rematchPlayerId: [],
                    moves: []
                    )
            games[gameId] = game
            notifyGameChanged(game: game)

            // Start a timer to add bot if no player joins in 4 seconds
            Task {
                try await Task.sleep(nanoseconds: 4 * 1_000_000_000)
                    await self.addBotToGameIfEmpty(gameId: gameId)
            }

        return game
    }

    func addBotToGameIfEmpty(gameId: String) async {
        guard var game = games[gameId], game.player2Id.isEmpty else { return }
        game.player2Id = "botPlayer"
            game.blockMoveForPlayerId = "botPlayer"
            games[gameId] = game
            notifyGameChanged(game: game)
    }

    func getGame(by id: String) -> Game? {
        return games[id]
    }

    func updateGame(_ game: Game) {
        games[game.id] = game
            notifyGameChanged(game: game)

            // Call makeMove if player2Id is "botPlayer" and blockMoveForPlayerId is not "botPlayer"
            if game.player2Id == "botPlayer" && game.blockMoveForPlayerId != "botPlayer" {
                Task {
                    try? await makeMove(for: game)
                }
            }
    }

    func deleteGame(by id: String) {
        games.removeValue(forKey: id)
            sockets[id]?.forEach { _ = $0.close() }
        sockets.removeValue(forKey: id)
    }

    func addSocket(_ socket: WebSocket, forGameId id: String) {
        if sockets[id] != nil {
            sockets[id]?.append(socket)
        } else {
            sockets[id] = [socket]
        }
        if let game = games[id] {
            notifyGameChanged(game: game)
        }
    }

    func notifyGameChanged(game: Game) {
        if let notifyingSockets = sockets[game.id] {
            if let data = try? JSONEncoder().encode(game).base64EncodedString() {
                notifyingSockets.forEach { $0.send(data) }
            }
        }
    }

    func makeMove(for game: Game) async throws {
        // Implement bot's move logic here
        guard game.winningPlayerId.isEmpty else {return}
        
        var updatedGame = game
            guard let word = game.moves.last?.word.uppercased() else {
                throw APIError.wordEmpty
            }
        let words = try await searchWordsContaining(string: word)
            let abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map({String($0)}).shuffled()
            var wordOfNextMove : String? = nil

            //When challenged:
            if !updatedGame.challengingUserId.isEmpty && updatedGame.challengingUserId != "botPlayer"{
                for possibleWord in words {
                    if (try await isWord(possibleWord)) && possibleWord.localizedCaseInsensitiveContains(word) {
                        let botMove = Move(isPlayer1: false, word: possibleWord)
                            updatedGame.moves.append(botMove)
                            updatedGame.winningPlayerId = "botPlayer"
                            updateGame(updatedGame)
                            break
                    }
                }
                if updatedGame.winningPlayerId != "botPlayer"{
                    updatedGame.winningPlayerId = updatedGame.player1Id
                    updateGame(updatedGame)
                }
                return
            }

        //when not challenged
        for char in abc {
            var testWord = word.appending(char)
                if try await !isWord(testWord) && words.contains(where: {$0.localizedCaseInsensitiveContains(testWord)}) {
                    wordOfNextMove = testWord
                        break
                }
            testWord = "\(char)\(word)"
                if try await !isWord(testWord) && words.contains(where: {$0.localizedCaseInsensitiveContains(testWord)}) {
                    wordOfNextMove = testWord
                        break
                }
        }
        if let wordOfNextMove{
            let botMove = Move(isPlayer1: false, word: wordOfNextMove)
                updatedGame.moves.append(botMove)
                updatedGame.blockMoveForPlayerId = "botPlayer"
        } else {
            for char in abc {
                var testWord = word.appending(char)
                    if words.contains(where: {$0.localizedCaseInsensitiveContains(testWord)}) {
                        wordOfNextMove = testWord
                            break
                    }
                testWord = "\(char)\(word)"
                    if words.contains(where: {$0.localizedCaseInsensitiveContains(testWord)}) {
                        wordOfNextMove = testWord
                            break
                    }
            }
            if let wordOfNextMove{
                let botMove = Move(isPlayer1: false, word: wordOfNextMove)
                    updatedGame.moves.append(botMove)
                    updatedGame.winningPlayerId = updatedGame.blockMoveForPlayerId
            } else {
                updatedGame.challengingUserId = "botPlayer"
            }
            updatedGame.blockMoveForPlayerId = "botPlayer"
        }
        updateGame(updatedGame)
    }
}

@SuperGameService
class LowGameService {
    static let shared = LowGameService()
        private var games: [String: Game] = [:]
        private var sockets: [String: [WebSocket]] = [:]
        private init() {}

    func getEmptyGame() -> Game? {
        return games.values.first(where: { $0.player2Id.isEmpty })
    }

    func createGame(player1Id: String, isPrivate: Bool = false) -> Game {
        let gameId = UUID().uuidString
            let game = Game(
                    id: gameId,
                    player1Id: player1Id,
                    player2Id: isPrivate ? "privateGame" : "",
                    blockMoveForPlayerId: player1Id,
                    rematchPlayerId: [],
                    moves: []
                    )
            games[gameId] = game
            notifyGameChanged(game: game)

            // Start a timer to add bot if no player joins in 4 seconds
            Task {
                try await Task.sleep(nanoseconds: 4 * 1_000_000_000)
                    await self.addBotToGameIfEmpty(gameId: gameId)
            }

        return game
    }

    func addBotToGameIfEmpty(gameId: String) async {
        guard var game = games[gameId], game.player2Id.isEmpty else { return }
        game.player2Id = "botPlayer"
            game.blockMoveForPlayerId = "botPlayer"
            games[gameId] = game
            notifyGameChanged(game: game)
    }

    func getGame(by id: String) -> Game? {
        return games[id]
    }

    func updateGame(_ game: Game) {
        games[game.id] = game
            notifyGameChanged(game: game)

            // Call makeMove if player2Id is "botPlayer" and blockMoveForPlayerId is not "botPlayer"
            if game.player2Id == "botPlayer" && game.blockMoveForPlayerId != "botPlayer" {
                Task {
                    try? await makeMove(for: game)
                }
            }
    }

    func deleteGame(by id: String) {
        games.removeValue(forKey: id)
            sockets[id]?.forEach { _ = $0.close() }
        sockets.removeValue(forKey: id)
    }

    func addSocket(_ socket: WebSocket, forGameId id: String) {
        if sockets[id] != nil {
            sockets[id]?.append(socket)
        } else {
            sockets[id] = [socket]
        }
        if let game = games[id] {
            notifyGameChanged(game: game)
        }
    }

    func notifyGameChanged(game: Game) {
        if let notifyingSockets = sockets[game.id] {
            if let data = try? JSONEncoder().encode(game).base64EncodedString() {
                notifyingSockets.forEach { $0.send(data) }
            }
        }
    }

    func makeMove(for game: Game) async throws {
        // Implement bot's move logic here

        
        guard game.winningPlayerId.isEmpty else {return}
        var updatedGame = game
            
            guard let word = game.moves.last?.word.uppercased() else {
                throw APIError.wordEmpty
            }
        let words = try await searchWordsContaining(string: word)
            let abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map({String($0)}).shuffled()
            var wordOfNextMove : String? = nil

            //When challenged:
            if !updatedGame.challengingUserId.isEmpty && updatedGame.challengingUserId != "botPlayer"{
                for possibleWord in words {
                    if (try await isWord(possibleWord)) && possibleWord.localizedCaseInsensitiveContains(word) {
                        let botMove = Move(isPlayer1: false, word: possibleWord)
                            updatedGame.moves.append(botMove)
                            updatedGame.winningPlayerId = "botPlayer"
                            updateGame(updatedGame)
                            break
                    }
                }

                if updatedGame.winningPlayerId != "botPlayer"{
                    updatedGame.winningPlayerId = updatedGame.player1Id
                    updateGame(updatedGame)
                }
                return
            }
        
        for char in abc {
            let testWord = word.appending(char)
                if try await !isWord(testWord) && words.contains(where: {$0.localizedCaseInsensitiveContains(testWord)}) {
                    wordOfNextMove = testWord
                        break
                }
        }
        if let wordOfNextMove{
            let botMove = Move(isPlayer1: false, word: wordOfNextMove)
                updatedGame.moves.append(botMove)
                updatedGame.blockMoveForPlayerId = "botPlayer"
        } else {
            for char in abc {
                let testWord = word.appending(char)
                    if words.contains(where: {$0.localizedCaseInsensitiveContains(testWord)}) {
                        wordOfNextMove = testWord
                            break
                    }
            }
            if let wordOfNextMove{
                let botMove = Move(isPlayer1: false, word: wordOfNextMove)
                    updatedGame.moves.append(botMove)
                    updatedGame.winningPlayerId = updatedGame.blockMoveForPlayerId
            } else {
                updatedGame.challengingUserId = "botPlayer"
            }
            updatedGame.blockMoveForPlayerId = "botPlayer"
        }
        updateGame(updatedGame)
    }
}
func isWord(_ word: String) async throws -> Bool {
    if word.count < 3 {return false}

    let (data, _) = try await URLSession.shared.data(from: URL(string:"https://api.dictionaryapi.dev/api/v2/entries/en/\(word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "hbib")") ?? URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/hjihre")!)

    if let _ = try? JSONDecoder().decode([WordEntry].self, from: data){
        return true
    }
    let responseString = String(data: data, encoding: .utf8) ?? "none"
    if responseString == #"{"title":"No Definitions Found","message":"Sorry pal, we couldn't find definitions for the word you were looking for.","resolution":"You can try the search again at later time or head to the web instead."}"# {
        return false
    } else if responseString.contains(word) {
    	return true
    }
    
    Logger(label: "game.isword").info("isWord failed sleeping ten seconds for word: \(word) response: \(responseString)")
    try await Task.sleep(nanoseconds: 10*1_000_000_000)
    return try await isWord(word)
}

struct WordEntry: Codable, Hashable {
    let word: String
        let phonetic: String?
        let phonetics: [Phonetic]
        let origin: String?
        let meanings: [Meaning]
}

struct Phonetic: Codable, Hashable {
    let text: String?
	let audio: String?
}

struct Meaning: Codable, Hashable {
    let partOfSpeech: String
    let definitions: [Definition]
}

struct Definition: Codable, Hashable {
    let definition: String
        let example: String?
        let synonyms: [String]
        let antonyms: [String]
}

enum APIError: Error {
    case invalidURL
        case requestFailed
        case invalidResponse
        case decodingError
        case wordEmpty
}

struct DatamuseWord : Decodable {
    let word: String
}

func searchWordsContaining(string: String) async throws -> [String] {
    let urlString = "https://api.datamuse.com/words?sp=\(string)*"

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

    let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()

        do {
            let response = try decoder.decode([DatamuseWord].self, from: data)
                return response.map { $0.word }
        } catch {
            throw APIError.decodingError
        }
}
