//
//  SampeData.swift
//  UMAF_mini
//
//  Created by JP Sweeney on 11/18/25.
//

import Foundation

let sampleMarkdown = """
# Example Document

This is sample text to transform into a UMAF Mini envelope.
"""

let normalizedOutput = """
# Example Document

This is sample text to transform into a UMAF Mini envelope.
"""

let sampleEnvelope = """
{
  "version": "umaf-mini-0.4.1",
  "docTitle": "Example Document",
  "mediaType": "text/markdown",
  "encoding": "utf-8",
  "lineCount": 3,
  "normalized": "..."
}
"""
