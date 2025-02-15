import Vapor
import WebSocketKit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


func apiV1(_ app: Application) throws {
    
    
    //Serving template for private games: superghost/private/*
    app.get("superghost", "private", "*"){req async throws in
        try await req.fileio.asyncStreamFile(at: app.directory.publicDirectory.appending("joinGameInSuperghostApp"))
    }
    
    //MARK: API

    app.post("superghost", "game", "create") { req async throws -> Game in
        let newGame = try req.content.decode(Game.self)
            let game = await SuperGameService.shared.createGame(player1Id: newGame.player1Id, isPrivate: !newGame.player2Id.isEmpty)
            return game
    }
    app.get("superghost", "game", "findEmptyPlayer2Id") { req -> Game in
        // Iterate through games to find the first game where player2Id is empty
        if let game = await SuperGameService.shared.getEmptyGame(){
            return game
        }
        throw Abort(.notFound)

    }

    app.post("superghost", "game", "join", ":gameId") { req async throws -> Game in
        let userId = try req.content.decode(String.self)
            guard let gameId = req.parameters.get("gameId"), var game = await SuperGameService.shared.getGame(by: gameId) else {
                throw Abort(.notFound)
            }

        game.player2Id = userId
            game.blockMoveForPlayerId = userId
            await SuperGameService.shared.updateGame(game)
            return game
    }

    app.put("superghost", "game") { req async throws -> Game in
        let game = try req.content.decode(Game.self)
            await SuperGameService.shared.updateGame(game)
            return game
    }
    app.get("superghost", "game", ":gameId") { req async throws -> Game in
        guard let gameId = req.parameters.get("gameId"), let game = await SuperGameService.shared.getGame(by: gameId) else {
            throw Abort(.notFound)
        }
        return game
    }

    app.delete("superghost", "game", ":gameId") { req -> HTTPStatus in
        guard let gameId = req.parameters.get("gameId") else {
            throw Abort(.notFound)
        }
        await SuperGameService.shared.deleteGame(by: gameId)
            return .ok
    }
    app.webSocket("superghost", "subscribe", "game", ":gameId") { req, ws in
        Task{@SuperGameService in
            guard let gameId = req.parameters.get("gameId") else {
                _ = try await ws.close()
                    return
            }

            await SuperGameService.shared.addSocket(ws, forGameId: gameId)
                ws.onClose.whenComplete { _ in
                    Task{@SuperGameService in
                        await SuperGameService.shared.deleteGame(by: gameId)
                    }
                }
        }
    }

    //MARK: ghost routes

    app.post("ghost", "game", "create") { req async throws -> Game in
        let newGame = try req.content.decode(Game.self)
            let game = await LowGameService.shared.createGame(player1Id: newGame.player1Id, isPrivate: !newGame.player2Id.isEmpty)
            return game
    }
    app.get("ghost", "game", "findEmptyPlayer2Id") { req -> Game in
        // Iterate through games to find the first game where player2Id is empty
        if let game = await LowGameService.shared.getEmptyGame(){
            return game
        }
        throw Abort(.notFound)

    }

    app.post("ghost", "game", "join", ":gameId") { req async throws -> Game in
        let userId = try req.content.decode(String.self)
            guard let gameId = req.parameters.get("gameId"), var game = await LowGameService.shared.getGame(by: gameId) else {
                throw Abort(.notFound)
            }

        game.player2Id = userId
            game.blockMoveForPlayerId = userId
            await LowGameService.shared.updateGame(game)
            return game
    }

    app.put("ghost", "game") { req async throws -> Game in
        let game = try req.content.decode(Game.self)
            await LowGameService.shared.updateGame(game)
            return game
    }
    app.get("ghost", "game", ":gameId") { req async throws -> Game in
        guard let gameId = req.parameters.get("gameId"), let game = await LowGameService.shared.getGame(by: gameId) else {
            throw Abort(.notFound)
        }
        return game
    }

    app.delete("ghost", "game", ":gameId") { req -> HTTPStatus in
        guard let gameId = req.parameters.get("gameId") else {
            throw Abort(.notFound)
        }
        await LowGameService.shared.deleteGame(by: gameId)
            return .ok
    }
    app.webSocket("ghost", "subscribe", "game", ":gameId") { req, ws in
        Task{@SuperGameService in
            guard let gameId = req.parameters.get("gameId") else {
                _ = try await ws.close()
                    return
            }

            LowGameService.shared.addSocket(ws, forGameId: gameId)
                ws.onClose.whenComplete { _ in
                    Task{@SuperGameService in
                        LowGameService.shared.deleteGame(by: gameId)
                    }
                }
        }
    }
}
