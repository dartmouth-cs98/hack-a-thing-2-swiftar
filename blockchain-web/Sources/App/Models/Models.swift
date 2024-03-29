//
//  Models.swift
//  App
//
//  Created by Andy Yoon on 10/1/19.
//

import Cocoa
import Vapor

final class BlockchainNode : Content {
    var address :String
    init(address :String) {
        self.address = address
    }
}

final class Transaction : Content {
    var from :String
    var to :String
    var amount :Double
    
    init(from :String, to :String, amount :Double) {
        self.from = from
        self.to = to
        self.amount = amount
    }
}

final class Block : Content {
    var index :Int = 0
    var previousHash :String = ""
    var hash :String!
    var nonce :Int
    
    private (set) var transactions :[Transaction] = [Transaction]()

    var key :String {
        get {
            
            let transactionsData = try! JSONEncoder().encode(self.transactions)
            let transactionsJSONString = String(data: transactionsData, encoding: .utf8)
            
            return String(self.index) + self.previousHash + String(self.nonce) + transactionsJSONString!
        }
    }
    
    func addTransaction(transaction :Transaction) {
        self.transactions.append(transaction)
    }
    
    init() {
        self.nonce = 0
    }
}

final class Blockchain : Content {
    
    private (set) var blocks = [Block]()
    private (set) var nodes = [BlockchainNode]()
    
    init(genesisBlock :Block) {
        addBlock(genesisBlock)
    }
    
    func registerNodes(nodes: [BlockchainNode]) -> [BlockchainNode]{
        self.nodes.append(contentsOf: nodes)
        return self.nodes
    }
    
    func addBlock(_ block :Block) {
        if self.blocks.isEmpty {
            block.previousHash = "000000000000000"
            block.hash = generateHash(for :block)
        }

        self.blocks.append(block)
    }
    
    func getNextBlock(transactions :[Transaction]) -> Block {
        let block = Block()
        transactions.forEach { transaction in
            block.addTransaction(transaction: transaction)
        }
        
        let previousBlock = getPreviousBlock()
        block.index = self.blocks.count
        block.previousHash = previousBlock.hash
        block.hash = generateHash(for: block)
        return block
    }
    
    private func getPreviousBlock() -> Block {
        return self.blocks[self.blocks.count - 1]
    }
    
    func generateHash(for block :Block) -> String {
        var hash = block.key.sha1Hash()
        
        while (!hash.hasPrefix("00")) {
            block.nonce += 1
            hash = block.key.sha1Hash()
            print(hash)
        }
        return hash
        
    }
    
}

// String Extension
extension String {
    
    func sha1Hash() -> String {
        
        let task = Process()
        task.launchPath = "/usr/bin/shasum"
        task.arguments = []
        
        let inputPipe = Pipe()
        
        inputPipe.fileHandleForWriting.write(self.data(using: String.Encoding.utf8)!)
        
        inputPipe.fileHandleForWriting.closeFile()
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardInput = inputPipe
        task.launch()
        
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let hash = String(data: data, encoding: String.Encoding.utf8)!
        return hash.replacingOccurrences(of: "  -\n", with: "")
    }
}

//
//
//
//let genesisBlock = Block()
//let blockchain = Blockchain(genesisBlock: genesisBlock)
//
//let transaction = Transaction(from: "Mary", to: "John", amount: 10, transactionType :.domestic)
//print("-----------------------")
//let block = blockchain.getNextBlock(transactions: [transaction])
//blockchain.addBlock(block)
//
//let data = try! JSONEncoder().encode(blockchain)
//let blockchainJSON = String(data: data, encoding: .utf8)
//
//print(blockchainJSON!)
