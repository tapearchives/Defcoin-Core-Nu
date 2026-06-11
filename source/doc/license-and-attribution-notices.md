# License And Attribution Notices

Defcoin Core Nu is derived from Litecoin Core and Bitcoin Core. The source
code is distributed under the MIT software license unless a file explicitly
states otherwise. See `COPYING` in the repository root for the complete MIT
license text.

## Core Copyright

- Copyright (c) 2014-2026 The Defcoin Core developers
- Copyright (c) 2011-2026 The Litecoin Core developers
- Copyright (c) 2009-2021 The Bitcoin Core developers
- Copyright (c) 2009-2021 Bitcoin Developers

Individual source files may carry more specific file-level notices. Those
notices remain authoritative for those files and should be preserved.

## Primary Dependencies

Defcoin Core Nu uses the same dependency family as the base Litecoin Core
wallet and node, plus the Qt Quick runtime used by the Nu interface.

- Qt: LGPLv3 / GPLv3 / commercial licensing, depending on distribution terms.
- Berkeley DB 4.8: Oracle Berkeley DB license, used for legacy wallet storage.
- SQLite: public domain, used for descriptor wallet database support.
- Boost: Boost Software License 1.0.
- OpenSSL/libcrypto: Apache License 2.0 or platform dependency terms.
- libevent: BSD-style license.
- LevelDB: BSD-style license.
- secp256k1 and secp256k1-zkp code: MIT license.
- CRC32C: BSD-style license.
- Unbound: BSD-style license when enabled by the dependency environment.
- QRencode: LGPLv2.1+.
- zlib, libpng, and related image libraries: zlib/libpng-style licenses.
- Trippy (`trip`): Apache License 2.0. Nu uses it only when the optional
  peer traceroute binary is installed or bundled; otherwise Nu falls back to
  the operating system traceroute utility.

Distribution packages should preserve the license notices required by the
linked dependency set for that platform.

## Artwork, Marks, And Attribution

The software license does not grant rights to use third-party trademarks,
wordmarks, design marks, or artwork outside their documented permission.

The DEFCON and "Smiling Jack" wordmarks, design marks, and associated logos
are registered trademarks of Def Con Communications, Inc. (Canadian Reg. No.
TMA917353; US Reg. No. 4582595). Coin image utilized under a long-standing
non-commercial permission agreement. This project is an independent creation
and is not affiliated with, sponsored by, or endorsed by Def Con
Communications, Inc. Def Con Communications, Inc. reserves all rights to the
exclusive use of its registered trademarks and design marks.

Upstream Bitcoin and Litecoin origin icons, translations, documentation, and
user-interface assets retain their upstream notices and licensing. Defcoin
branding assets included in this tree are provided for the Defcoin Core Nu
project and should not be treated as general-purpose open branding.
