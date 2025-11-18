//
//  FileObserver.swift
//  UMAF_mini
//
//  Created by JP Sweeney on 11/18/25.
//

import Foundation

final class FileObserver {
    private var source: DispatchSourceFileSystemObject?

    func watch(url: URL, onChange: @escaping () -> Void) {
        stop()

        let fd = open(url.path, O_EVTONLY)
        guard fd != -1 else { return }

        let queue = DispatchQueue.global(qos: .utility)
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: queue
        )

        src.setEventHandler(handler: onChange)
        src.setCancelHandler { close(fd) }
        src.resume()
        source = src
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    deinit {
        stop()
    }
}
