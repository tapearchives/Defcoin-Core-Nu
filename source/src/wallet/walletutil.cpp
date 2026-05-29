// Copyright (c) 2017-2019 The Bitcoin Core developers
// Distributed under the MIT software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include <wallet/walletutil.h>

#include <chainparams.h>
#include <key_io.h>
#include <logging.h>
#include <util/system.h>

#include <boost/version.hpp>

#include <cassert>
#include <stdexcept>

bool ExistsBerkeleyDatabase(const fs::path& path);
#ifdef USE_SQLITE
bool ExistsSQLiteDatabase(const fs::path& path);
#else
#   define ExistsSQLiteDatabase(path)  (false)
#endif

namespace {
int WalletDirIteratorDepth(const fs::recursive_directory_iterator& it)
{
#if BOOST_VERSION >= 107200
    return it.depth();
#else
    return it.level();
#endif
}

void DisableWalletDirRecursion(fs::recursive_directory_iterator& it)
{
#if BOOST_VERSION >= 107200
    it.disable_recursion_pending();
#else
    it.no_push();
#endif
}
} // namespace

fs::path GetWalletDir()
{
    fs::path path;

    if (gArgs.IsArgSet("-walletdir")) {
        path = gArgs.GetArg("-walletdir", "");
        if (!fs::is_directory(path)) {
            // If the path specified doesn't exist, we return the deliberately
            // invalid empty string.
            path = "";
        }
    } else {
        path = GetDataDir();
        // If a wallets directory exists, use that, otherwise default to GetDataDir
        if (fs::is_directory(path / "wallets")) {
            path /= "wallets";
        }
    }

    return path;
}

std::vector<fs::path> ListWalletDir()
{
    const fs::path wallet_dir = GetWalletDir();
    const size_t offset = wallet_dir.string().size() + 1;
    std::vector<fs::path> paths;
    boost::system::error_code ec;

    for (auto it = fs::recursive_directory_iterator(wallet_dir, ec); it != fs::recursive_directory_iterator(); it.increment(ec)) {
        if (ec) {
            LogPrintf("%s: %s %s\n", __func__, ec.message(), it->path().string());
            continue;
        }

        try {
            // Get wallet path relative to walletdir by removing walletdir from the wallet path.
            // This can be replaced by boost::filesystem::lexically_relative once boost is bumped to 1.60.
            const fs::path path = it->path().string().substr(offset);

            if (it->status().type() == fs::directory_file &&
                (ExistsBerkeleyDatabase(it->path()) || ExistsSQLiteDatabase(it->path()))) {
                // Found a directory which contains wallet.dat btree file, add it as a wallet.
                paths.emplace_back(path);
            } else if (WalletDirIteratorDepth(it) == 0 && it->symlink_status().type() == fs::regular_file && ExistsBerkeleyDatabase(it->path())) {
                if (it->path().filename() == "wallet.dat") {
                    // Found top-level wallet.dat btree file, add top level directory ""
                    // as a wallet.
                    paths.emplace_back();
                } else {
                    // Found top-level btree file not called wallet.dat. Current bitcoin
                    // software will never create these files but will allow them to be
                    // opened in a shared database environment for backwards compatibility.
                    // Add it to the list of available wallets.
                    paths.emplace_back(path);
                }
            }
        } catch (const std::exception& e) {
            LogPrintf("%s: Error scanning %s: %s\n", __func__, it->path().string(), e.what());
            DisableWalletDirRecursion(it);
        }
    }

    return paths;
}

WalletDescriptor GenerateWalletDescriptor(const CExtPubKey& master_key, const OutputType& addr_type, bool internal)
{
    const int64_t creation_time = GetTime();
    const std::string xpub = EncodeExtPubKey(master_key);

    std::string desc_prefix;
    std::string desc_suffix = "/*)";
    switch (addr_type) {
    case OutputType::LEGACY: {
        desc_prefix = "pkh(" + xpub + "/44h";
        break;
    }
    case OutputType::P2SH_SEGWIT: {
        desc_prefix = "sh(wpkh(" + xpub + "/49h";
        desc_suffix += ")";
        break;
    }
    case OutputType::BECH32: {
        desc_prefix = "wpkh(" + xpub + "/84h";
        break;
    }
    case OutputType::MWEB: {
        desc_prefix = "mweb(" + xpub + "/100h";
        break;
    }
    } // no default case, so the compiler can warn about missing cases
    assert(!desc_prefix.empty());

    // Preserve the existing Litecoin-derived Defcoin descriptor path: mainnet
    // uses coin type 2h, while test chains use 1h. This helper mirrors Bitcoin
    // Core's descriptor scaffold but keeps Defcoin's current derivation policy.
    desc_prefix += Params().IsTestChain() ? "/1h" : "/2h";

    const std::string internal_path = internal ? "/1" : "/0";
    const std::string desc_str = desc_prefix + "/0h" + internal_path + desc_suffix;

    FlatSigningProvider keys;
    std::string error;
    std::unique_ptr<Descriptor> desc = Parse(desc_str, keys, error, false);
    if (!desc) {
        throw std::runtime_error("Error parsing generated wallet descriptor: " + error);
    }
    return WalletDescriptor(std::move(desc), creation_time, 0, 0, 0);
}

bool IsFeatureSupported(int wallet_version, int feature_version)
{
    return wallet_version >= feature_version;
}

WalletFeature GetClosestWalletFeature(int version)
{
    const std::array<WalletFeature, 8> wallet_features{{FEATURE_LATEST, FEATURE_PRE_SPLIT_KEYPOOL, FEATURE_NO_DEFAULT_KEY, FEATURE_HD_SPLIT, FEATURE_HD, FEATURE_COMPRPUBKEY, FEATURE_WALLETCRYPT, FEATURE_BASE}};
    for (const WalletFeature& wf : wallet_features) {
        if (version >= wf) return wf;
    }
    return static_cast<WalletFeature>(0);
}
