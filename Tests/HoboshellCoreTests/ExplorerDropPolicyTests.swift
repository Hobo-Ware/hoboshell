import Foundation
import Testing
@testable import HoboshellCore

@Suite struct ExplorerDropPolicyTests {
    @Test func sameVolumeMoves() {
        #expect(ExplorerDropPolicy.operation(sameVolume: true, optionDown: false) == .move)
    }

    @Test func otherVolumeCopies() {
        #expect(ExplorerDropPolicy.operation(sameVolume: false, optionDown: false) == .copy)
    }

    @Test func optionForcesACopyOnTheSameVolume() {
        #expect(ExplorerDropPolicy.operation(sameVolume: true, optionDown: true) == .copy)
    }

    @Test func folderCannotGoIntoItself() {
        let folder = URL(fileURLWithPath: "/a/b")
        #expect(!ExplorerDropPolicy.canTransfer(folder, into: folder))
    }

    @Test func folderCannotGoIntoItsOwnDescendant() {
        #expect(!ExplorerDropPolicy.canTransfer(URL(fileURLWithPath: "/a/b"), into: URL(fileURLWithPath: "/a/b/c/d")))
    }

    @Test func siblingWithTheSamePrefixIsAllowed() {
        #expect(ExplorerDropPolicy.canTransfer(URL(fileURLWithPath: "/a/b"), into: URL(fileURLWithPath: "/a/bc")))
    }

    @Test func fileIntoAnotherFolderIsAllowed() {
        #expect(ExplorerDropPolicy.canTransfer(URL(fileURLWithPath: "/a/x.txt"), into: URL(fileURLWithPath: "/z")))
    }

    @Test func itemInTheDestinationAlreadyIsDetected() {
        #expect(ExplorerDropPolicy.isAlreadyIn(URL(fileURLWithPath: "/a/x.txt"), folder: URL(fileURLWithPath: "/a")))
        #expect(!ExplorerDropPolicy.isAlreadyIn(URL(fileURLWithPath: "/a/b/x.txt"), folder: URL(fileURLWithPath: "/a")))
    }
}
