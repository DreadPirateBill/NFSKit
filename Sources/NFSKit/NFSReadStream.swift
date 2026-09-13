//
//  NFSReadStream.swift
//  NFSKit
//
//  A file held open for random-access reads — the primitive a media player's demuxer needs (open once, positioned reads, close), which the
//  whole-file `contents(atPath:)` family doesn't offer. Sprocket Player fork addition.
//

import Foundation

/// A read-only file kept open on the client's mounted export. Reads are synchronous; the caller serialises them (one reader thread, e.g. a demuxer).
/// Give the stream a client of its own rather than one shared with directory listings.
public final class NFSReadStream: @unchecked Sendable {
    private let file: NFSFileHandle

    /// File size at open time.
    public let size: Int64

    /// The largest single read the mount allows; `read` chunks longer requests by this.
    public var maxReadSize: Int { file.optimizedReadSize }

    init(file: NFSFileHandle, size: Int64) {
        self.file = file
        self.size = size
    }

    /// Reads up to `length` bytes starting at `offset`. Returns fewer bytes only at end of file, and an empty `Data` at or past it.
    public func read(offset: Int64, length: Int) throws -> Data {
        guard offset >= 0, offset < size, length > 0 else { return Data() }
        let end = min(size, offset + Int64(length))
        var out = Data()
        out.reserveCapacity(Int(end - offset))
        var position = offset
        while position < end {
            let chunk = Int(min(Int64(max(file.optimizedReadSize, 1)), end - position))
            let data = try file.pread(offset: UInt64(position), length: chunk)
            guard !data.isEmpty else { break }
            out.append(data)
            position += Int64(data.count)
        }
        return out
    }

    /// Closes the underlying handle. Safe to call once; later reads throw.
    public func close() {
        file.close()
    }
}
