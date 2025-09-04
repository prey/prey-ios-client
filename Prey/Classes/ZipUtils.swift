//
//  ZipUtils.swift
//  Prey
//
//  Minimal ZIP builder utilities for bundling logs or small payloads.
//

import Foundation

// Minimal ZIP builder (store, no compression) for one or more entries
enum ZipBuilder {
    private static let lfhSignature: UInt32 = 0x04034b50
    private static let cdfhSignature: UInt32 = 0x02014b50
    private static let eocdSignature: UInt32 = 0x06054b50

    static func build(entries: [(name: String, data: Data)]) -> Data {
        var local = Data()
        var central = Data()
        var offset: UInt32 = 0
        var count: UInt16 = 0
        for (name, data) in entries {
            guard let nameData = name.data(using: .utf8) else { continue }
            let crc = crc32(data)
            let compSize = UInt32(data.count) // store method
            let uncompSize = compSize
            let nameLen = UInt16(nameData.count)
            let modTime: UInt16 = 0
            let modDate: UInt16 = 0

            // Local File Header
            local.append(u32(lfhSignature))
            local.append(u16(20)) // version needed
            local.append(u16(0))  // flags
            local.append(u16(0))  // method = store
            local.append(u16(modTime))
            local.append(u16(modDate))
            local.append(u32(crc))
            local.append(u32(compSize))
            local.append(u32(uncompSize))
            local.append(u16(nameLen))
            local.append(u16(0))  // extra len
            local.append(nameData)
            local.append(data)

            // Central Directory File Header
            central.append(u32(cdfhSignature))
            central.append(u16(20)) // version made by
            central.append(u16(20)) // version needed
            central.append(u16(0))  // flags
            central.append(u16(0))  // method store
            central.append(u16(modTime))
            central.append(u16(modDate))
            central.append(u32(crc))
            central.append(u32(compSize))
            central.append(u32(uncompSize))
            central.append(u16(nameLen))
            central.append(u16(0))  // extra len
            central.append(u16(0))  // comment len
            central.append(u16(0))  // disk number start
            central.append(u16(0))  // internal attrs
            central.append(u32(0))  // external attrs
            central.append(u32(offset)) // relative offset
            central.append(nameData)

            offset = UInt32(local.count)
            count &+= 1
        }

        var out = Data()
        out.append(local)
        let cdOffset = UInt32(out.count)
        out.append(central)
        let cdSize = UInt32(central.count)
        out.append(u32(eocdSignature))
        out.append(u16(0)) // disk number
        out.append(u16(0)) // start disk
        out.append(u16(count))
        out.append(u16(count))
        out.append(u32(cdSize))
        out.append(u32(cdOffset))
        out.append(u16(0)) // comment length
        return out
    }

    private static func u16(_ v: UInt16) -> Data { var x = v.littleEndian; return Data(bytes: &x, count: 2) }
    private static func u32(_ v: UInt32) -> Data { var x = v.littleEndian; return Data(bytes: &x, count: 4) }

    // CRC32 (IEEE 802.3) for ZIP
    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for b in data { let idx = Int((crc ^ UInt32(b)) & 0xFF); crc = (crc >> 8) ^ table[idx] }
        return crc ^ 0xFFFF_FFFF
    }
    private static let table: [UInt32] = {
        (0..<256).map { i in
            var c = UInt32(i)
            for _ in 0..<8 { c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1) }
            return c
        }
    }()
}

