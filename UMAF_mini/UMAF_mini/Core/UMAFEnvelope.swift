//
//  UMAFEnvelope.swift
//  UMAF_mini
//
//  Created by JP Sweeney on 11/18/25.
//

import Foundation

/// Lightweight view of the UMAF Mini envelope.
/// Fields are optional because older/newer versions may add/remove keys.
struct UMAFEnvelope: Decodable {
    let version: String?
    let docTitle: String?
    let docId: String?
    let createdAt: String?
    let sourceHash: String?
    let sourcePath: String?
    let mediaType: String?
    let encoding: String?
    let sizeBytes: Int?
    let lineCount: Int?

    let sections: [Section]?
    let bullets: [Bullet]?
    let frontMatter: [FrontMatterItem]?
    let tables: [Table]?
    let codeBlocks: [CodeBlock]?

    struct Section: Decodable {
        let heading: String?
        let level: Int?
    }

    struct Bullet: Decodable {
        let text: String?
    }

    struct FrontMatterItem: Decodable {
        let key: String?
        let value: String?
    }

    struct Table: Decodable {
        let startLineIndex: Int?
        let header: [String]?
        let rows: [[String]]?
    }

    struct CodeBlock: Decodable {
        let startLineIndex: Int?
        let language: String?
    }
}
