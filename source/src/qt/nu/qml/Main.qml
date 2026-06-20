import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Basic 2.15 as Basic
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Defcoin.Nu 1.0

import "Shell"
import "Theme"
import "Components"

ApplicationWindow {
    id: root
    visible: true
    width: 1440
    height: 820
    minimumWidth: 1240
    minimumHeight: 680
    title: NuService.walletSelected ? "Defcoin Core Nu - " + NuService.walletDisplayName(NuService.currentWalletName) : "Defcoin Core Nu"
    color: NuTokens.backgroundBase
    property alias currentRoute: frame.currentRoute
    property alias nodeInitialTab: frame.nodeInitialTab
    property alias peerInitialView: frame.peerInitialView
    property string buildVersion: NuBuildVersion
    property string buildId: NuBuildId
    property string buildTimestamp: NuBuildTimestamp
    property string gitCommit: NuGitCommit
    property bool quitRequested: false
    property bool helpEnabled: NuHelpEnabled
    property bool recoveryProgressDismissed: false
    property bool recoveryWasActive: false
    property bool syncProgressHiddenThisLaunch: false
    property bool shutdownInProgress: false
    property int shutdownStepIndex: 0
    readonly property var shutdownSteps: [
        qsTr("Preparing shutdown..."),
        qsTr("Stopping background network and helper tasks..."),
        qsTr("Closing wallet and database handles..."),
        qsTr("Asking the backend to stop cleanly...")
    ]
    readonly property string releaseCodeName: "Core Memories"
    readonly property string trademarkNotice: "The DEFCON and 'Smiling Jack' wordmarks, design marks, and associated logos are registered trademarks of Def Con Communications, Inc. (Canadian Reg. No. TMA917353; US Reg. No. 4582595). Coin image utilized under a long-standing non-commercial permission agreement. This project is an independent creation and is not affiliated with, sponsored by, or endorsed by Def Con Communications, Inc. Def Con Communications, Inc. reserves all rights to the exclusive use of its registered trademarks and design marks."
    palette.window: NuTokens.panelBase
    palette.base: NuTokens.panelBase
    palette.alternateBase: NuTokens.backgroundBase
    palette.text: NuTokens.textPrimary
    palette.windowText: NuTokens.textPrimary
    palette.button: NuTokens.panelBase
    palette.buttonText: NuTokens.textPrimary
    palette.highlight: NuTokens.lineStrong
    palette.highlightedText: NuTokens.textInverse

    Component.onCompleted: Qt.callLater(root.refreshSyncProgressWindow)

    onClosing: function(close) {
        if (root.shutdownInProgress) {
            close.accepted = false
            root.show()
            root.raise()
            return
        }
        if (!root.quitRequested && NuService.backgroundCloseEnabled && NuPlatform.trayAvailable) {
            close.accepted = false
            root.hide()
            NuPlatform.showBackgroundNotice()
        } else if (!root.quitRequested) {
            close.accepted = false
            root.requestQuit()
        }
    }

    function openPreferences() {
        NuService.advancedToolsVisible = true
        frame.requestRoute("settings")
    }

    function closeMainWindow() {
        root.close()
    }

    function requestQuit() {
        if (root.shutdownInProgress) {
            root.show()
            root.raise()
            return
        }
        root.shutdownInProgress = true
        root.shutdownStepIndex = 0
        root.show()
        root.raise()
        shutdownTimer.restart()
        shutdownKickoffTimer.restart()
    }

    function refreshSyncProgressWindow() {
        if (NuService.syncing && !root.syncProgressHiddenThisLaunch) {
            if (!syncProgressWindow.visible)
                syncProgressWindow.show()
        } else if (!NuService.syncing && syncProgressWindow.visible) {
            syncProgressWindow.hide()
        }
    }

    function isCopyShortcut(event) {
        return event.key === Qt.Key_C
               && ((Qt.platform.os === "osx" && (event.modifiers & Qt.MetaModifier))
                   || (Qt.platform.os !== "osx" && (event.modifiers & Qt.ControlModifier)))
    }

    function isCutShortcut(event) {
        return event.key === Qt.Key_X
               && ((Qt.platform.os === "osx" && (event.modifiers & Qt.MetaModifier))
                   || (Qt.platform.os !== "osx" && (event.modifiers & Qt.ControlModifier)))
    }

    function isSensitiveClipboardShortcut(event) {
        return root.isCopyShortcut(event) || root.isCutShortcut(event)
    }

    function sensitiveCopyText(target) {
        if (!target)
            return ""
        if (target.selectedText !== undefined && String(target.selectedText).length > 0)
            return String(target.selectedText)
        if (target.text !== undefined)
            return String(target.text)
        if (target.editText !== undefined)
            return String(target.editText)
        if (target.currentText !== undefined)
            return String(target.currentText)
        if (target.displayText !== undefined)
            return String(target.displayText)
        return ""
    }

    function requestMnemonicClipboardCopy(target) {
        var text = root.sensitiveCopyText(target).replace(/\s+/g, " ").trim()
        if (text.length === 0)
            return
        mnemonicClipboardWarningDialog.pendingText = text
        mnemonicClipboardWarningDialog.open()
    }

    // qmllint disable missing-property
    function runEditAction(actionName) {
        var target = root.activeFocusItem
        if (!target)
            return
        while (target && target.parent
               && !(actionName === "undo" && target.undo)
               && !(actionName === "redo" && target.redo)
               && !(actionName === "cut" && (target.cut || target.mnemonicClipboardGuard))
               && !(actionName === "copy" && (target.copy || target.mnemonicClipboardGuard))
               && !(actionName === "paste" && target.paste))
            target = target.parent
        try {
            if (actionName === "undo" && target.undo) target.undo()
            else if (actionName === "redo" && target.redo) target.redo()
            else if (actionName === "cut" && target.mnemonicClipboardGuard) root.requestMnemonicClipboardCopy(target)
            else if (actionName === "cut" && target.cut) target.cut()
            else if (actionName === "copy" && target.mnemonicClipboardGuard) root.requestMnemonicClipboardCopy(target)
            else if (actionName === "copy" && target.copy) target.copy()
            else if (actionName === "paste" && target.paste) target.paste()
        } catch (e) {
        }
    }
    // qmllint enable missing-property

    function walletIsLoaded(walletName) {
        var loaded = NuService.loadedWallets
        for (var i = 0; i < loaded.length; ++i) {
            if (String(loaded[i]) === String(walletName))
                return true
        }
        return false
    }

    function walletLabel(walletName) {
        return NuService.walletDisplayName(String(walletName))
    }

    function walletMenuLabel(walletName) {
        var label = root.walletLabel(walletName)
        if (NuService.walletSelected && String(walletName) === NuService.currentWalletName)
            return label + qsTr(" (current)")
        if (root.walletIsLoaded(walletName))
            return label + qsTr(" (loaded)")
        return label
    }

    function chooseWallet(walletName) {
        if (root.walletIsLoaded(walletName))
            NuService.setCurrentWallet(walletName)
        else
            NuService.loadWallet(walletName)
    }

    function openNode() {
        NuService.advancedToolsVisible = true
        frame.requestRoute("node")
    }

    function openRpcConsole() {
        NuService.advancedToolsVisible = true
        frame.requestRoute("rpc")
    }

    function basicAboutText() {
        return "Defcoin Core Nu v" + root.buildVersion + " - " + root.releaseCodeName + ". New Qt Quick interface build. Backend derives from Litecoin Core v0.21.5.5 with Defcoin consensus and network parameters. Verify recipients, amounts, and backups carefully before use. © 2014-2026 The Defcoin Core developers. © 2011-2026 The Litecoin Core developers. © 2009-2021 The Bitcoin Core developers."
    }

    function showHelpPage(windowTitle, page) {
        if (!root.helpEnabled) {
            messageDialog.title = "Help not included"
            messageDialog.text = "Build notes are available from About in this build."
            messageDialog.open()
            return
        }
        if (Qt.platform.os === "osx") {
            NuService.openHelpManual(page)
        } else {
            root.openHelpWindow(windowTitle, NuService.helpManualHtml(page), "")
        }
    }

    function nuBuildDetailsHtml() {
        return "<h1>Defcoin Core Nu v" + root.buildVersion + "</h1>"
             + "<p><b>Codename:</b> Core Memories</p>"
             + "<p><b>Status:</b> Nu is a new Qt Quick interface for Defcoin Core. Its backend derives from Litecoin Core v0.21.5.5 and keeps Defcoin consensus parameters and the existing Defcoin data directory, while introducing a desktop shell inspired by Nothing Company product design and the Bitcoin Design Community.</p>"
             + "<h2>Build metadata</h2>"
             + "<ul>"
             + "<li><b>Release:</b> " + root.buildVersion + "</li>"
             + "<li><b>Codename:</b> Core Memories</li>"
             + "<li><b>Build ID:</b> " + (root.buildId.length > 0 ? root.buildId : "not recorded in this bundle") + "</li>"
             + "<li><b>Build time:</b> " + (root.buildTimestamp.length > 0 ? root.buildTimestamp : "not recorded in this bundle") + "</li>"
             + "<li><b>Source:</b> " + (root.gitCommit.length > 0 ? root.gitCommit : "not recorded in this bundle") + "</li>"
             + "</ul>"
             + "<h2>What went into Nu</h2>"
             + "<ul>"
             + "<li>Qt Quick interface organized around Home, Send, Receive, Transactions, Wallet, Mining, RPC Console, Metrics, and Settings. Explorer and Forensics analysis now live in the separate Defcoin Core Nu Explore app so Nu can stay wallet-first.</li>"
             + "<li>Visual system, copy, and interaction patterns are guided by Nothing-style restraint and Bitcoin Design Community wallet usability patterns.</li>"
             + "<li>Bundled backend autostart, RPC connection handling, launch diagnostics, and current-launch log viewing.</li>"
             + "<li><b>Enable LAN node discovery</b> is off by default. When enabled, macOS may ask for Local Network access so Nu can find Defcoin nodes on the same LAN, which can help another local wallet copy blockchain data faster. The permission does not grant access to wallet keys, passphrases, or private wallet data.</li>"
             + "<li><b>UDP fast sync</b> is an experimental transfer helper enabled by default. Nu can request checksum-protected raw block chunks over UDP port 10334 from connected Defcoin peers over IPv4 or IPv6; LAN discovery also enables local broadcast. Every received block is still passed to backend validation with normal TCP sync left active as the fallback.</li>"
             + "<li><b>Quick Clone</b> is the trusted-LAN/DCOL workflow for public blockchain data only. It never copies wallet files, private keys, passphrases, configuration, peers, bans, address books, or RPC cookies; final snapshot replacement is gated by manifests and hash verification.</li>"
             + "<li><b>Apple Silicon validation speedup:</b> Apple Silicon builds now use Bitcoin Core-derived ARM SHA2 intrinsics for SHA256 and SHA256D64. On the Mac Mini M4 Pro test machine, Nu's double-SHA256 batch path measured 1232.94 MiB/s versus 187.53 MiB/s for the generic path, a 6.6x improvement, with identical output checksums over a 1 GiB validation-style workload.</li>"
             + "<li>Dual-magic migration support for legacy <code>fbc0b6db</code> and Defcoin-specific <code>defc014e</code> P2P message headers.</li>"
             + "<li>Peer pollution filtering now happens at both the peer and address-relay layers: non-Defcoin-prefixed peers are disconnected before their address tables are accepted, and unvalidated relayed mainnet addresses are only stored when they advertise Defcoin service ports.</li>"
             + "<li>The address filter is endpoint-specific, not IP-wide. If the same host runs Litecoin Core on one port and Defcoin Core on another, Nu keeps the Defcoin endpoint eligible and can replace older same-IP non-Defcoin ports in addrman. Defcoin nodes on non-standard ports can still communicate and be retained after completing an actual Defcoin handshake.</li>"
             + "<li>Peer inspection with simple and detailed views, including actual per-peer magic bytes where reported by the backend.</li>"
             + "<li>Network metrics now include difficulty, 120-block network hashrate, chain-tip counts, sync progress, and top P2P message types where the backend reports them. [Thanks to packetloss404 / Ian S. Walmsley's v1.0.2 build.]</li>"
             + "<li>Defcoin Core Nu Explore carries the Explorer and Forensics surfaces from Nu, including irregular OP_RETURN scans, Holder Atlas analytics, movements, contacts, relationship graphs, and index controls. Nu can hand address and transaction inspections to Explore when the internal explorer mode is selected.</li>"
             + "<li>BIP39 recovery phrase creation and restore workflows for Nu/Core HD wallets, plus an advanced preview-gated external derivation scan with Defcoin WIF compatibility options.</li>"
             + "<li>Local mining setup can select an external cpuminer-compatible executable, build scrypt stratum arguments, and monitor miner output without bundling miner binaries into the wallet app.</li>"
             + "<li>Wallet basics including receive requests, transaction inspection, PSBT tools, message signing, wallet backup, encryption, and optional third-party explorer links.</li>"
             + "</ul>"
             + "<h2>How Nu differs from Defcoin 1.0.0 and 1.0.1</h2>"
             + "<ul>"
             + "<li>Nu keeps the Defcoin chain and wallet data directory shared, but replaces the classic Qt wallet surface with a new Qt Quick shell.</li>"
             + "<li>Nu includes explicit peer filtering and magic-byte migration controls intended to reduce Litecoin-family peer pollution.</li>"
             + "<li>Nu adds clearer metrics for backend startup, RPC readiness, network state, peers, logs, and traffic.</li>"
             + "<li>Nu runs a bundled <code>defcoind</code> backend as a managed child process, instead of keeping node, wallet, and UI work inside one classic Qt wallet process.</li>"
             + "<li>Nu's newer part is the desktop interface and packaging model; the chain rules, wallet data directory, and Litecoin-derived backend remain the Defcoin Core compatibility baseline.</li>"
             + "</ul>"
             + "<h2>Source</h2>"
             + "<p>Please contribute if you find Defcoin Core useful. Visit <a href=\"https://github.com/DefcoinCore/\">https://github.com/DefcoinCore/</a> for further information about the software.</p>"
             + "<p>The source code is available from <a href=\"https://github.com/DefcoinCore/Defcoin-Core-Nu\">https://github.com/DefcoinCore/Defcoin-Core-Nu</a>.</p>"
             + "<p>This is experimental software.</p>"
             + "<p>Distributed under the MIT software license, see the accompanying file COPYING or <a href=\"https://opensource.org/license/MIT\">https://opensource.org/license/MIT</a>.</p>"
             + "<h2>Acknowledgements</h2>"
             + "<p>Defcoin Core Nu was not created in a vacuum. It has been influenced and inspired by a community. The following people and projects helped bring Defcoin to where it is today. Special thanks and acknowledgements go out to those listed below and countless others who spent time experimenting and sharing. Apologies if we missed anyone. Please send corrections to /r/defcoin or the Discord.</p>"
             + "<h3>1. Code and tooling used inside Defcoin Core Nu</h3>"
             + "<ul>"
             + "<li>Litecoin Core v0.21.5.5 - Litecoin Core developers - <a href=\"https://github.com/litecoin-project/litecoin\">litecoin-project/litecoin</a> | Bitcoin Core architecture inherited through Litecoin Core - Bitcoin Core developers - <a href=\"https://github.com/bitcoin/bitcoin\">bitcoin/bitcoin</a></li>"
             + "<li>Qt and Qt Quick - The Qt Company and Qt Project - <a href=\"https://www.qt.io/\">qt.io</a> | QML, dialogs, table UI, native window integration, networking helpers, and application framework pieces used by Nu.</li>"
             + "<li>BIP-0039 mnemonic standard and English word list - BIP39 authors and contributors including Marek Palatinus, Pavol Rusnak, Aaron Voisine, and Sean Bowe - <a href=\"https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki\">BIP-0039</a> | used for phrase validation and recovery workflows.</li>"
             + "<li>libqrencode - Kentaro Fukuchi and contributors - <a href=\"https://fukuchi.org/works/qrencode/\">libqrencode</a> | QR generation inherited through the Core wallet stack.</li>"
             + "<li>liteaddress.org / bitaddress.org paper-wallet layout model - litecoin-project and bitaddress.org contributors - <a href=\"https://github.com/litecoin-project/liteaddress.org\">litecoin-project/liteaddress.org</a> | MIT-licensed paper-wallet controls and foldable print-layout reference adapted for Nu's native Defcoin key generation.</li>"
             + "<li>Defcoin Bulk paper wallet - @sibios - <a href=\"https://github.com/sibios/defcoin-bulk\">sibios/defcoin-bulk</a> | historical Defcoin two-page paper-wallet artwork and layout reference used by Nu Paper Wallet Design 5; Nu keeps key generation and QR creation in native Core/Nu code.</li>"
             + "<li>Velopack - Velopack project and contributors - <a href=\"https://velopack.io/\">velopack.io</a> | update-package metadata and installer update flow where enabled.</li>"
             + "<li>Trippy - fujiapple852 and contributors - <a href=\"https://github.com/fujiapple852/trippy\">fujiapple852/trippy</a> | Apache-2.0 licensed route tracing tool used when the <code>trip</code> binary is installed or bundled for peer route inspection.</li>"
             + "<li>Core dependency stack inherited through Litecoin Core depends/build systems - Berkeley DB 4.8 / Sleepycat and Oracle | Boost community | OpenSSL Project | libevent project | SQLite / D. Richard Hipp and contributors | miniupnpc / Thomas Bernard | ZeroMQ community | platform packaging and toolchain contributors.</li>"
             + "</ul>"
             + "<h3>2. Prior Defcoin codebases and ideas directly referenced</h3>"
             + "<ul>"
             + "<li>Defcoin-Qt v0.8.6.2 and early Defcoin source history - surviving reference tree: <a href=\"https://github.com/mspicer/Defcoin\">mspicer/Defcoin</a> | Defcoin Core v1.0.0 - @NaH012 / Michael Julander - <a href=\"https://github.com/mspicer/Defcoin/releases\">mspicer/Defcoin releases</a> | Defcoin Core v1.0.1 - @miketweaver / Mike T. Weaver - <a href=\"https://github.com/mspicer/Defcoin/releases\">mspicer/Defcoin releases</a> | Defcoin Core v1.0.2 - @packetloss404 / Ian S. Walmsley - <a href=\"https://github.com/packetloss404/Defcoin\">packetloss404/Defcoin</a></li>"
             + "<li>pycoin Defcoin-tooling discussions including dfcp/dfcv BIP32 prefix ideas - Richard Kiss / pycoin contributors and Defcoin community contributors.</li>"
             + "<li>Defcoin P2Pool references - @charlesrocket / <a href=\"https://github.com/charlesrocket/p2pool-defcoin\">charlesrocket/p2pool-defcoin</a> | @hellbyte / <a href=\"https://github.com/hellbyte/p2pool-defcoin\">hellbyte/p2pool-defcoin</a> | g4tekeep3r Defcoin P2Pool writeups - <a href=\"https://www.g4tekeep3r.com/?s=defcoin\">g4tekeep3r Defcoin posts</a> | defcoin.io long-running P2Pool operation - <a href=\"https://defcoin.io/\">defcoin.io</a></li>"
             + "<li>Ian Coleman BIP39 tool - Ian Coleman and contributors - <a href=\"https://iancoleman.io/bip39/\">iancoleman.io/bip39</a> and <a href=\"https://github.com/iancoleman/bip39\">iancoleman/bip39</a> | used as a compatibility reference for Coinomi-style phrase recovery and Defcoin WIF-prefix comparison.</li>"
             + "<li>Bitcoin Design Community wallet usability work - <a href=\"https://bitcoin.design/\">bitcoin.design</a> | Bitcoin Core App/QML design work as architecture reference | Nothing Design references as product-interface inspiration | JayDDee cpuminer-opt - <a href=\"https://github.com/JayDDee/cpuminer-opt\">JayDDee/cpuminer-opt</a>, which Nu can configure as an external Scrypt mining helper but does not bundle.</li>"
             + "</ul>"
             + "<h3>3. Wider Defcoin ecosystem inspirations and history</h3>"
             + "<ul>"
             + "<li>Coindroids and Defcoin culture - Joshua \"Josh\" McDougall / @Abstrct - <a href=\"https://github.com/Abstrct/docker-droid\">Abstrct/docker-droid</a> and Coindroids writings | DEF CON origin context - Dark Tangent / Jeff Moss and the DEF CON community.</li>"
             + "<li>Defcoin project and community sites - <a href=\"http://defcoin.org/\">defcoin.org</a> | <a href=\"https://defcoin-ng.org/\">defcoin-ng.org</a> | Defcoin Node Docker - Mike T. Weaver / @miketweaver - <a href=\"https://github.com/defcoin-ng/defcoin-node-docker\">defcoin-ng/defcoin-node-docker</a> | <a href=\"https://defcoin.io/\">defcoin.io</a> | <a href=\"https://wiki.defcoin.io/\">wiki.defcoin.io</a> | <a href=\"https://defcoin.dc903.org/\">defcoin.dc903.org</a> | <a href=\"https://www.defcoinstats.com/\">defcoinstats.com</a>.</li>"
             + "<li>Mobile wallets - Android Defcoin Wallet v1.07 - Justin Culbertson / @jjculber - <a href=\"https://github.com/jjculber/defcoin-wallet\">jjculber/defcoin-wallet</a> | BeerWallet for iOS - Michael Perklin / @mperklin - <a href=\"https://github.com/mperklin/beerwallet\">mperklin/beerwallet</a>.</li>"
             + "<li>Historical pool credits - defcoin.dc903.org P2Pool - <a href=\"https://defcoin.dc903.org/pool\">defcoin.dc903.org/pool</a> | defcoin.io P2Pool - <a href=\"https://defcoin.io/\">defcoin.io</a> | defcoin.host - <a href=\"https://defcoin.host/\">defcoin.host</a> | RedBaron Defcoin Pool - <a href=\"https://www.redbaron.us\">redbaron.us</a> | Subba Defcoin Pool - <a href=\"https://defcoin-pool.subba.net\">defcoin-pool.subba.net</a> | Chunky Pools - <a href=\"https://chunkypools.com/def\">chunkypools.com/def</a></li>"
             + "<li>More historical pool credits - Defcoin.us Pool / earlier Defcoin.io - <a href=\"https://defcoin.us/\">defcoin.us</a> | IPTron Pool - <a href=\"http://coin.iptron.net:13370\">coin.iptron.net:13370</a> | Beardpool Defcoin Pool / Acor - <a href=\"https://pool.acor.to\">pool.acor.to</a> | DefcoinPool - <a href=\"http://www.defcoinpool.com/\">defcoinpool.com</a> | Poltergeek's Pool - <a href=\"http://defcoin.cloudapp.net\">defcoin.cloudapp.net</a> | Cryptoheater - <a href=\"http://cryptoheater.com/\">cryptoheater.com</a> | SecDSM Defcoin Pool | Unknown Mining Pool | LAIW.</li>"
             + "<li>Historical utilities and archives - def.coindroids.com | defcointalk.org | defcoin.assmeow.org | defcoin.jculb.com | defcoinfaucet.com | beerwallet.org | wallet.ribbit.me | miningpoolstats.stream/defcoin | InfoConDB entry for The Making of Defcoin.</li>"
             + "</ul>"
             + "<h3>4. Everyone we forgot</h3>"
             + "<p>Apologies if we've left anyone out of this list and I am sure there are many. Also thanks to everyone who participated: the project is nothing without the community.</p>"
    }

    function openNuBuildDetails() {
        root.openHelpWindow("Defcoin Core Nu Build Notes", root.nuBuildDetailsHtml(), "")
    }

    function openDetailedAbout() {
        if (root.helpEnabled)
            root.showHelpPage("About Defcoin Core Nu", "details.html")
        else
            root.openNuBuildDetails()
    }

    function openHelpManual() {
        root.showHelpPage("Defcoin Core Nu Help Manual", "index.html")
    }

    function openAboutSummary() {
        aboutDialog.open()
    }

    function openHelpWindow(windowTitle, html, anchor) {
        helpWindow.title = windowTitle
        helpText.text = html
        helpWindow.show()
        helpWindow.raise()
        helpWindow.requestActivate()
        if (anchor && anchor.length > 0) {
            Qt.callLater(function() { root.scrollHelpToAnchor(anchor) })
        } else {
            Qt.callLater(function() {
                // qmllint disable missing-property
                if (helpScroll.contentItem && helpScroll.contentItem.contentY !== undefined)
                    helpScroll.contentItem.contentY = 0
                // qmllint enable missing-property
            })
        }
    }

    function scrollHelpToAnchor(anchor) {
        var anchors = {
            "home": "Home (Overview)",
            "send": "Send",
            "receive": "Receive",
            "activity": "Transactions",
            "wallet": "Wallet",
            "mining": "Mining",
            "diagnostics": "Metrics",
            "settings": "Settings",
            "psbt": "Partially signed transactions"
        }
        var title = anchors[anchor] || anchor
        var plain = helpText.getText(0, helpText.length)
        var pos = plain.indexOf(title)
        if (pos < 0)
            pos = plain.toLowerCase().indexOf(String(title).toLowerCase())
        if (pos < 0) return
        helpText.cursorPosition = pos
        var rect = helpText.positionToRectangle(pos)
        // qmllint disable missing-property
        if (helpScroll.contentItem && helpScroll.contentItem.contentY !== undefined) {
            helpScroll.contentItem.contentY = Math.max(0, rect.y - 24)
        }
        // qmllint enable missing-property
    }

    function openHelpLink(link) {
        var target = String(link)
        if (target.indexOf("http://") === 0 || target.indexOf("https://") === 0) {
            NuService.openExternalUrl(target)
            return
        }
        if (target.charAt(0) === "#") {
            root.scrollHelpToAnchor(target.substring(1))
            return
        }
        var clean = target.split("#")[0]
        var hashIndex = target.indexOf("#")
        var anchor = hashIndex >= 0 ? target.substring(hashIndex + 1) : ""
        if (clean.length === 0)
            clean = "index.html"
        if (clean.indexOf(".html") >= 0) {
            root.openHelpWindow(clean === "details.html" ? "About Defcoin Core Nu" : "Defcoin Core Nu Help Manual",
                                NuService.helpManualHtml(clean),
                                anchor)
        }
    }

    function uiSelfTestClosePopups() {
        messageDialog.close()
        quickClonePromptDialog.close()
        mnemonicClipboardWarningDialog.close()
        transactionDetailsDialog.close()
        openUriDialog.close()
        createWalletDialog.close()
        createRecoveryWalletDialog.close()
        restoreRecoveryWalletDialog.close()
        closeWalletDialog.close()
        closeAllWalletsDialog.close()
        deleteWalletDialog.close()
        signDialog.close()
        verifyDialog.close()
        updateAvailableDialog.close()
        updateProgressDialog.close()
        updateReadyDialog.close()
        aboutDialog.close()
        recoveryProgressDialog.hide()
        syncProgressWindow.hide()
        helpWindow.close()
    }

    function uiSelfTestOpenMenuDialog(name) {
        var target = String(name)
        if (target === "about") {
            root.openAboutSummary()
        } else if (target === "build-notes") {
            root.openDetailedAbout()
        } else if (target === "help") {
            root.openHelpManual()
        } else if (target === "create-wallet") {
            createWalletDialog.open()
        } else if (target === "create-recovery-wallet") {
            createRecoveryWalletDialog.open()
        } else if (target === "restore-recovery-wallet") {
            restoreRecoveryWalletDialog.open()
        } else if (target === "open-uri") {
            openUriDialog.open()
        } else if (target === "sign-message") {
            signDialog.open()
        } else if (target === "verify-message") {
            verifyDialog.open()
        }
    }

    function uiSelfTestOpenPaperWalletTab() {
        frame.uiSelfTestOpenPaperWalletTab()
    }

    function uiSelfTestOpenSettingsTab(tabName) {
        frame.uiSelfTestOpenSettingsTab(tabName)
    }

    menuBar: MenuBar {
        Menu {
            id: fileMenu
            title: qsTr("File")
            width: Math.max(implicitWidth, 460)
            NuMenuItem { text: qsTr("Create Wallet..."); onTriggered: createWalletDialog.open() }
            NuMenuItem { text: qsTr("Create Wallet with Recovery Phrase..."); onTriggered: createRecoveryWalletDialog.open() }
            NuMenuItem { text: qsTr("Restore Wallet from Recovery Phrase..."); onTriggered: restoreRecoveryWalletDialog.open() }
            Menu {
                id: openWalletMenu
                title: qsTr("Open Wallet")
                enabled: NuService.availableWallets.length > 0
                width: Math.max(implicitWidth, 480)
                leftPadding: 0
                rightPadding: 0
                Instantiator {
                    id: openWalletItems
                    model: NuService.availableWallets
                    delegate: NuMenuItem {
                        required property var modelData
                        property string walletName: String(modelData)
                        text: root.walletMenuLabel(walletName)
                        enabled: true
                        onTriggered: root.chooseWallet(walletName)
                    }
                    onObjectAdded: function(index, object) { openWalletMenu.insertItem(index, object) }
                    onObjectRemoved: function(index, object) { openWalletMenu.removeItem(object) }
                }
            }
            NuMenuItem { text: qsTr("Close Wallet..."); enabled: NuService.loadedWallets.length > 0; onTriggered: closeWalletDialog.open() }
            NuMenuItem { text: qsTr("Close All Wallets..."); enabled: NuService.loadedWallets.length > 0; onTriggered: closeAllWalletsDialog.open() }
            NuMenuItem { text: qsTr("Delete Wallet..."); enabled: NuService.availableWallets.length > 0; onTriggered: deleteWalletDialog.open() }
            MenuSeparator {}
            NuMenuItem { text: qsTr("Open URI..."); onTriggered: openUriDialog.open() }
            NuMenuItem { text: qsTr("Backup Wallet..."); onTriggered: NuService.backupWallet() }
            NuMenuItem { text: qsTr("Sign message..."); onTriggered: signDialog.open() }
            NuMenuItem { text: qsTr("Verify message..."); onTriggered: verifyDialog.open() }
            MenuSeparator {}
            NuMenuItem { text: qsTr("Load PSBT from file..."); onTriggered: NuService.loadPsbtFromFile() }
            NuMenuItem { text: qsTr("Load PSBT from clipboard..."); onTriggered: NuService.loadPsbtFromClipboard() }
            MenuSeparator {}
            NuMenuItem { text: Qt.platform.os === "osx" ? qsTr("Close Window") : qsTr("Exit"); shortcut: Qt.platform.os === "osx" ? "Meta+W" : "Alt+F4"; onTriggered: Qt.platform.os === "osx" ? root.closeMainWindow() : root.requestQuit() }
        }

        Menu {
            title: qsTr("Edit")
            NuMenuItem { text: qsTr("Undo"); shortcut: StandardKey.Undo; onTriggered: root.runEditAction("undo") }
            NuMenuItem { text: qsTr("Redo"); shortcut: StandardKey.Redo; onTriggered: root.runEditAction("redo") }
            MenuSeparator {}
            NuMenuItem { text: qsTr("Cut"); shortcut: StandardKey.Cut; onTriggered: root.runEditAction("cut") }
            NuMenuItem { text: qsTr("Copy"); shortcut: StandardKey.Copy; onTriggered: root.runEditAction("copy") }
            NuMenuItem { text: qsTr("Paste"); shortcut: StandardKey.Paste; onTriggered: root.runEditAction("paste") }
            MenuSeparator { visible: Qt.platform.os !== "osx"; height: visible ? implicitHeight : 0 }
            NuMenuItem {
                text: Qt.platform.os === "windows" ? qsTr("Settings") : qsTr("Preferences")
                shortcut: "Ctrl+,"
                visible: Qt.platform.os !== "osx"
                height: visible ? implicitHeight : 0
                onTriggered: root.openPreferences()
            }
        }

        Menu {
            title: qsTr("View")
            NuMenuItem { text: qsTr("Home"); shortcut: Qt.platform.os === "osx" ? "Meta+1" : "Ctrl+1"; onTriggered: frame.requestRoute("home") }
            NuMenuItem { text: qsTr("Send"); shortcut: Qt.platform.os === "osx" ? "Meta+2" : "Ctrl+2"; onTriggered: frame.requestRoute("send") }
            NuMenuItem { text: qsTr("Receive"); shortcut: Qt.platform.os === "osx" ? "Meta+3" : "Ctrl+3"; onTriggered: frame.requestRoute("receive") }
            NuMenuItem { text: qsTr("Transactions"); shortcut: Qt.platform.os === "osx" ? "Meta+4" : "Ctrl+4"; onTriggered: frame.requestRoute("activity") }
            NuMenuItem { text: qsTr("Wallet"); shortcut: Qt.platform.os === "osx" ? "Meta+5" : "Ctrl+5"; onTriggered: frame.requestRoute("wallet") }
            NuMenuItem {
                text: qsTr("Mining")
                shortcut: Qt.platform.os === "osx" ? "Meta+6" : "Ctrl+6"
                visible: NuService.advancedToolsVisible
                implicitHeight: visible ? Math.max(contentItem.implicitHeight + 14, 34) : 0
                onTriggered: {
                    NuService.advancedToolsVisible = true
                    frame.requestRoute("mining")
                }
            }
            NuMenuItem {
                text: qsTr("RPC Console")
                shortcut: Qt.platform.os === "osx" ? "Meta+7" : "Ctrl+7"
                visible: NuService.advancedToolsVisible
                implicitHeight: visible ? Math.max(contentItem.implicitHeight + 14, 34) : 0
                onTriggered: root.openRpcConsole()
            }
            NuMenuItem {
                text: qsTr("Metrics")
                shortcut: Qt.platform.os === "osx" ? "Meta+8" : "Ctrl+8"
                visible: NuService.advancedToolsVisible
                implicitHeight: visible ? Math.max(contentItem.implicitHeight + 14, 34) : 0
                onTriggered: root.openNode()
            }
        }

        Menu {
            id: macWindowMenu
            title: qsTr("Window")
            Component.onCompleted: {
                if (Qt.platform.os !== "osx") macWindowMenu.destroy()
            }
            NuMenuItem { text: qsTr("Minimize"); shortcut: "Meta+M"; onTriggered: root.showMinimized() }
            NuMenuItem {
                text: qsTr("Zoom")
                onTriggered: {
                    if (root.visibility === Window.Maximized)
                        root.showNormal()
                    else
                        root.showMaximized()
                }
            }
        }

        Menu {
            title: qsTr("Help")
            NuMenuItem {
                text: qsTr("Check for Updates...")
                visible: Qt.platform.os !== "osx"
                height: visible ? implicitHeight : 0
                onTriggered: NuService.checkForUpdates(true)
            }
            MenuSeparator { visible: Qt.platform.os !== "osx"; height: visible ? implicitHeight : 0 }
            NuMenuItem {
                text: qsTr("Developer Documentation")
                visible: Qt.platform.os === "osx"
                height: visible ? implicitHeight : 0
                onTriggered: NuService.openExternalUrl("https://github.com/DefcoinCore/Defcoin-Core-Nu/tree/main/doc")
            }
            NuMenuItem {
                text: qsTr("About Defcoin Core Nu")
                visible: Qt.platform.os !== "osx"
                height: visible ? implicitHeight : 0
                onTriggered: aboutDialog.open()
            }
            NuMenuItem {
                text: qsTr("About Qt")
                visible: Qt.platform.os !== "osx"
                height: visible ? implicitHeight : 0
                onTriggered: NuPlatform.showAboutQt()
            }
        }
    }

    AppFrame {
        id: frame
        anchors.fill: parent
        onAboutRequested: root.openAboutSummary()
        onCreateWalletRequested: createWalletDialog.open()
        onCreateRecoveryWalletRequested: createRecoveryWalletDialog.open()
        onRestoreRecoveryWalletRequested: restoreRecoveryWalletDialog.open()
    }

    Timer {
        id: shutdownTimer
        interval: 650
        repeat: true
        onTriggered: {
            if (root.shutdownStepIndex < root.shutdownSteps.length - 1) {
                root.shutdownStepIndex += 1
                return
            }
        }
    }

    Timer {
        id: shutdownKickoffTimer
        interval: 120
        repeat: false
        onTriggered: {
            NuService.prepareForApplicationQuit()
            shutdownTimer.stop()
            root.shutdownStepIndex = root.shutdownSteps.length - 1
            root.quitRequested = true
            NuPlatform.quitApplication()
        }
    }

    Rectangle {
        id: shutdownOverlay
        anchors.fill: parent
        visible: root.shutdownInProgress
        z: 10000
        color: Qt.rgba(0, 0, 0, 0.38)

        Rectangle {
            width: Math.min(620, parent.width - NuTokens.spaceXl * 2)
            height: shutdownLayout.implicitHeight + NuTokens.spaceXl * 2
            anchors.centerIn: parent
            radius: NuTokens.radiusLarge
            color: NuTokens.panelBase
            border.color: Qt.rgba(0.26, 0.10, 0.42, 0.62)
            border.width: 1

            ColumnLayout {
                id: shutdownLayout
                anchors.fill: parent
                anchors.margins: NuTokens.spaceXl
                spacing: NuTokens.spaceMd

                Label {
                    Layout.fillWidth: true
                    text: qsTr("Closing Defcoin Core Nu")
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBodyLarge
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }

                Label {
                    Layout.fillWidth: true
                    text: qsTr("Nu must close wallets, indexes, network services, and database files cleanly to prevent corruption. Do not force quit while shutdown is in progress.")
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontBody
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Basic.ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: Math.max(1, root.shutdownSteps.length - 1)
                    value: root.shutdownStepIndex
                }

                Label {
                    Layout.fillWidth: true
                    text: NuService.shutdownStatus.length > 0 ? NuService.shutdownStatus : root.shutdownSteps[root.shutdownStepIndex]
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontBody
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Connections {
        target: NuService
        function onUserMessage(title, message) {
            messageDialog.title = title
            messageDialog.text = message
            messageDialog.open()
        }
        function onQuickClonePromptRequested(title, message) {
            quickClonePromptDialog.title = title
            quickClonePromptDialog.text = message
            quickClonePromptDialog.open()
        }
        function onTransactionDetailsReady(title, html) {
            transactionDetailsDialog.title = title
            transactionDetailsText.text = html
            transactionDetailsDialog.open()
        }
        function onExplorerWindowRequested(title, html) {
            const explorerWindow = explorerWindowComponent.createObject(root, {
                "title": title,
                "explorerHtml": html
            })
            // qmllint disable missing-property
            if (explorerWindow) explorerWindow.show()
            // qmllint enable missing-property
        }
        function onUpdateAvailable(version, message) {
            updateAvailableDialog.version = version
            updateAvailableLabel.text = message
            updateAvailableDialog.open()
        }
        function onUpdateDownloaded(version, filePath, message) {
            updateProgressDialog.close()
            updateReadyDialog.version = version
            updateReadyDialog.filePath = filePath
            updateReadyLabel.text = message
            updateReadyDialog.open()
        }
        function onRecoveryPhrasePreviewReady(preview, message) {
            var previewData = preview || {}
            restoreRecoveryWalletDialog.previewData = previewData
            restoreRecoveryWalletDialog.previewRows = previewData.addresses || []
            restoreRecoveryWalletDialog.previewDetails = previewData.details || []
            restoreRecoveryPreviewMessage.text = message
        }
        function onRecoveryChanged() {
            if (NuService.recoveryActive && !root.recoveryWasActive) {
                root.recoveryProgressDismissed = false
                recoveryProgressDialog.show()
            } else if (NuService.recoveryActive && !root.recoveryProgressDismissed && !recoveryProgressDialog.visible) {
                recoveryProgressDialog.show()
            }
            root.recoveryWasActive = NuService.recoveryActive
        }
        function onStateChanged() {
            root.refreshSyncProgressWindow()
        }
    }

    Component {
        id: explorerWindowComponent

        Window {
            id: explorerWindow
            width: 920
            height: 700
            minimumWidth: 720
            minimumHeight: 520
            color: NuTokens.backgroundBase
            property string explorerHtml: ""

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NuTokens.spaceLg
                spacing: NuTokens.spaceMd

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        text: explorerWindow.title
                        color: NuTokens.textPrimary
                        font.pixelSize: NuTokens.fontTitle
                        font.weight: Font.DemiBold
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 2
                    }
                    NuActionButton {
                        text: qsTr("Close")
                        Layout.preferredWidth: 112
                        onClicked: explorerWindow.close()
                    }
                }

                Basic.ScrollView {
                    id: explorerScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
                    clip: true

                    TextEdit {
                        width: Math.max(1, explorerScroll.availableWidth)
                        readOnly: true
                        selectByMouse: true
                        persistentSelection: true
                        textFormat: TextEdit.RichText
                        wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                        text: explorerWindow.explorerHtml
                        color: NuTokens.textPrimary
                        selectedTextColor: NuTokens.textInverse
                        selectionColor: NuTokens.lineStrong
                        font.pixelSize: NuTokens.fontBody
                        onLinkActivated: NuService.openExplorerLink(link)
                    }
                }
            }
        }
    }

    NuDialog {
        id: messageDialog
        showCancel: false
        dialogWidth: 700
        property alias text: messageText.text

        TextEdit {
            id: messageText
            Layout.fillWidth: true
            Layout.preferredWidth: Math.max(1, messageDialog.availableWidth)
            width: Math.max(1, messageDialog.availableWidth)
            Layout.preferredHeight: Math.min(Math.max(contentHeight + NuTokens.spaceSm, 104), Math.max(160, root.height - 300))
            readOnly: true
            selectByMouse: true
            persistentSelection: true
            color: NuTokens.textPrimary
            selectedTextColor: NuTokens.textInverse
            selectionColor: NuTokens.lineStrong
            font.pixelSize: NuTokens.fontBody
            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
            textFormat: TextEdit.PlainText
        }
    }

    NuDialog {
        id: quickClonePromptDialog
        dialogWidth: 760
        acceptText: qsTr("Use Quick Clone")
        cancelText: qsTr("Keep normal sync")
        property alias text: quickClonePromptText.text
        beforeAccept: function() {
            NuService.acceptQuickClonePrompt()
            return true
        }
        onRejected: NuService.declineQuickClonePrompt()

        TextEdit {
            id: quickClonePromptText
            Layout.fillWidth: true
            Layout.preferredWidth: Math.max(1, quickClonePromptDialog.availableWidth)
            width: Math.max(1, quickClonePromptDialog.availableWidth)
            Layout.preferredHeight: Math.min(Math.max(contentHeight + NuTokens.spaceSm, 220), Math.max(240, root.height - 300))
            readOnly: true
            selectByMouse: true
            persistentSelection: true
            color: NuTokens.textPrimary
            selectedTextColor: NuTokens.textInverse
            selectionColor: NuTokens.lineStrong
            font.pixelSize: NuTokens.fontBody
            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
            textFormat: TextEdit.PlainText
        }
    }

    Menu {
        id: mnemonicCopyMenu
        property var sourceControl: null
        NuMenuItem {
            text: qsTr("Copy")
            enabled: mnemonicCopyMenu.sourceControl
                     && root.sensitiveCopyText(mnemonicCopyMenu.sourceControl).trim().length > 0
            onTriggered: root.requestMnemonicClipboardCopy(mnemonicCopyMenu.sourceControl)
        }
    }

    NuDialog {
        id: mnemonicClipboardWarningDialog
        title: qsTr("Clipboard warning")
        acceptText: qsTr("I Understand, Copy")
        cancelText: qsTr("Cancel")
        dialogWidth: 680
        property string pendingText: ""

        onAccepted: {
            NuService.copySensitiveTextAfterWarning(pendingText)
            pendingText = ""
        }
        onRejected: pendingText = ""

        Label {
            Layout.fillWidth: true
            text: qsTr("If a recovery phrase leaks during import, and it came from a multi-coin wallet such as Coinomi, every coin wallet derived from that phrase could be exposed. Keep the phrase private. Cloud clipboard, clipboard history, remote desktop, or syncing software may move copied text outside your control. If you are confident the machine, clipboard, and sync tools are not compromised, copying may be acceptable; otherwise type the phrase manually or use an offline or freshly trusted machine.")
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }
    }

    Window {
        id: recoveryProgressDialog
        title: NuService.recoveryFinished ? qsTr("Recovery complete") : qsTr("Recovering wallet")
        width: 760
        height: 560
        minimumWidth: 680
        minimumHeight: 460
        modality: Qt.NonModal
        flags: Qt.Window
        color: NuTokens.panelBase
        onClosing: function(close) {
            root.recoveryProgressDismissed = true
            if (NuService.recoveryActive) {
                close.accepted = false
                hide()
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: NuTokens.spaceLg
            spacing: NuTokens.spaceMd

            Label {
                Layout.fillWidth: true
                text: NuService.recoveryStatus
                color: NuTokens.textPrimary
                font.pixelSize: NuTokens.fontBody
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }

            Basic.ProgressBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 14
                from: 0
                to: 100
                value: Math.max(0, NuService.recoveryProgress)
                indeterminate: NuService.recoveryActive && NuService.recoveryProgress < 0
            }

            Label {
                Layout.fillWidth: true
                text: NuService.recoveryProgress < 0
                      ? qsTr("Progress: scanning blockchain data...")
                      : qsTr("Progress: ") + NuService.recoveryProgress + qsTr("%")
                color: NuTokens.textSecondary
                font.pixelSize: NuTokens.fontSmall
                wrapMode: Text.WordWrap
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: NuTokens.spaceLg
                rowSpacing: NuTokens.spaceSm

                Label {
                    text: qsTr("Processing")
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 150
                }
                Label {
                    Layout.fillWidth: true
                    text: NuService.recoveryCurrentMethod.length > 0
                          ? NuService.recoveryCurrentMethod
                          : (NuService.recoveryActive ? qsTr("Importing derived addresses and rescanning the chain.") : qsTr("Import and chain scan finished."))
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: qsTr("Elapsed")
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 150
                }
                Label {
                    Layout.fillWidth: true
                    text: NuService.recoveryElapsed
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: qsTr("ETA")
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 150
                }
                Label {
                    Layout.fillWidth: true
                    text: NuService.recoveryEta
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: qsTr("Coins found")
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 150
                }
                Label {
                    Layout.fillWidth: true
                    text: NuService.recoveryFoundAmount.length > 0 ? NuService.recoveryFoundAmount : qsTr("Checking after the chain rescan completes.")
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: qsTr("Addresses with coins")
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 150
                }
                Label {
                    Layout.fillWidth: true
                    text: NuService.recoveryFoundAddressCount
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: qsTr("Recent address coins found")
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 150
                }
                Label {
                    Layout.fillWidth: true
                    text: NuService.recoveryRecentFoundAddress.length > 0 ? NuService.recoveryRecentFoundAddress : qsTr("No address hits reported yet.")
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WrapAnywhere
                }

                Label {
                    text: qsTr("Detected method")
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 150
                }
                Label {
                    Layout.fillWidth: true
                    text: NuService.recoveryDetectedMethod.length > 0 ? NuService.recoveryDetectedMethod : qsTr("Checking recovery options.")
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WordWrap
                }
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("Recovery runs in the background. You can use the rest of the wallet while this window is open, or close the window and let recovery continue.")
                color: NuTokens.textSecondary
                font.pixelSize: NuTokens.fontSmall
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                NuActionButton {
                    text: qsTr("Cancel")
                    visible: NuService.recoveryActive
                    enabled: NuService.recoveryCancelable
                    onClicked: NuService.cancelRecovery()
                }
                NuActionButton {
                    text: qsTr("Close")
                    enabled: NuService.recoveryFinished || !NuService.recoveryActive
                    onClicked: {
                        root.recoveryProgressDismissed = true
                        recoveryProgressDialog.hide()
                    }
                }
            }
        }
    }

    Window {
        id: syncProgressWindow
        title: qsTr("Synchronizing blockchain")
        width: 660
        height: 380
        minimumWidth: 620
        minimumHeight: 340
        modality: Qt.NonModal
        flags: Qt.Dialog
        color: NuTokens.panelBase
        onClosing: function(close) {
            close.accepted = false
            root.syncProgressHiddenThisLaunch = true
            hide()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: NuTokens.spaceLg
            spacing: NuTokens.spaceMd

            Label {
                Layout.fillWidth: true
                text: qsTr("Synchronizing Defcoin blockchain")
                color: NuTokens.textPrimary
                font.pixelSize: NuTokens.fontTitle
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.fillWidth: true
                text: NuService.syncDetail
                color: NuTokens.textPrimary
                font.pixelSize: NuTokens.fontBody
                wrapMode: Text.WordWrap
            }

            Basic.ProgressBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 14
                from: 0
                to: 100
                value: Math.max(0, Math.min(100, NuService.syncProgressPercent))
                indeterminate: NuService.syncing && NuService.syncProgressPercent <= 0
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: NuTokens.spaceLg
                rowSpacing: NuTokens.spaceSm

                Label {
                    text: qsTr("Block")
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 130
                }
                Label {
                    Layout.fillWidth: true
                    text: NuService.blockHeight + qsTr(" of ") + NuService.headerHeight
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontSmall
                }

                Label {
                    text: qsTr("Progress")
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 130
                }
                Label {
                    Layout.fillWidth: true
                    text: NuService.syncProgressPercent + qsTr("%")
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontSmall
                }

                Label {
                    text: qsTr("Estimated time")
                    color: NuTokens.textSecondary
                    font.pixelSize: NuTokens.fontSmall
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 130
                }
                Label {
                    Layout.fillWidth: true
                    text: NuService.syncEta
                    color: NuTokens.textPrimary
                    font.pixelSize: NuTokens.fontSmall
                }
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("Hide this window while sync continues. The mast and Metrics > Status keep updating.")
                color: NuTokens.textSecondary
                font.pixelSize: NuTokens.fontSmall
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                NuActionButton {
                    text: qsTr("Hide")
                    Layout.preferredWidth: 120
                    onClicked: {
                        root.syncProgressHiddenThisLaunch = true
                        syncProgressWindow.hide()
                    }
                }
            }
        }
    }

    NuDialog {
        id: transactionDetailsDialog
        showCancel: false
        acceptText: qsTr("Close")
        dialogWidth: 760

        Basic.ScrollView {
            id: transactionDetailsScroll
            Layout.fillWidth: true
            contentWidth: availableWidth
            Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
            Layout.preferredHeight: Math.min(root.height - 220, 520)
            clip: true

            TextEdit {
                id: transactionDetailsText
                width: Math.max(1, transactionDetailsScroll.availableWidth)
                readOnly: true
                selectByMouse: true
                textFormat: TextEdit.RichText
                wrapMode: TextEdit.WordWrap
                font.pixelSize: NuTokens.fontBody
                color: NuTokens.textPrimary
                selectedTextColor: NuTokens.textInverse
                selectionColor: NuTokens.lineStrong
                onLinkActivated: NuService.openExplorerLink(link)
            }
        }
    }

    NuDialog {
        id: openUriDialog
        title: qsTr("Open URI")
        acceptText: qsTr("Open")
        dialogWidth: 620

        NuTextField {
            id: openUriField
            Layout.fillWidth: true
            placeholderText: qsTr("defcoin:<address>?amount=...")
            helpText: qsTr("Open a Defcoin payment URI in the Send screen for review before broadcast.")
        }

        onAccepted: {
            frame.openUri(openUriField.text)
            openUriField.text = ""
        }
        onRejected: openUriField.text = ""
        onClosed: if (!visible) openUriField.text = ""
    }

    NuDialog {
        id: createWalletDialog
        title: qsTr("Create Wallet")
        acceptText: qsTr("Create")
        dialogWidth: 620
        beforeAccept: function() {
            if (createWalletEncrypt.checked && createWalletPassphrase.text !== createWalletPassphraseConfirm.text) {
                messageDialog.title = qsTr("Wallet not created")
                messageDialog.text = qsTr("The passphrase and confirmation do not match.")
                messageDialog.open()
                return false
            }
            return true
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("Create and load a new wallet in the shared Defcoin data directory.")
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        NuTextField {
            id: createWalletName
            Layout.fillWidth: true
            placeholderText: qsTr("Wallet name")
            maximumLength: 128
            helpText: qsTr("Use up to 128 characters. Slashes, colons, control characters, path segments, backup suffixes, and copy labels are not accepted.")
            onAccepted: createWalletDialog.requestAccept()
            Keys.onReturnPressed: createWalletDialog.requestAccept()
            Keys.onEnterPressed: createWalletDialog.requestAccept()
        }

        NuCheckBox {
            id: createWalletEncrypt
            text: qsTr("Encrypt Wallet")
            helpText: qsTr("Encrypt the new wallet immediately with a passphrase.")
            enabled: !createWalletDisablePrivateKeys.checked
        }

        NuTextField {
            id: createWalletPassphrase
            Layout.fillWidth: true
            visible: createWalletEncrypt.checked
            enabled: visible
            echoMode: TextInput.Password
            placeholderText: qsTr("Passphrase")
            helpText: qsTr("Use at least 8 characters. This passphrase is required to spend from the wallet.")
            onAccepted: createWalletDialog.requestAccept()
            Keys.onReturnPressed: createWalletDialog.requestAccept()
            Keys.onEnterPressed: createWalletDialog.requestAccept()
        }

        NuTextField {
            id: createWalletPassphraseConfirm
            Layout.fillWidth: true
            visible: createWalletEncrypt.checked
            enabled: visible
            echoMode: TextInput.Password
            placeholderText: qsTr("Confirm passphrase")
            helpText: qsTr("Re-enter the passphrase to catch typing mistakes before the wallet is created.")
            onAccepted: createWalletDialog.requestAccept()
            Keys.onReturnPressed: createWalletDialog.requestAccept()
            Keys.onEnterPressed: createWalletDialog.requestAccept()
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("Advanced Options")
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: advancedWalletOptions.implicitHeight + NuTokens.spaceMd * 2
            color: NuTokens.backgroundBase
            border.color: NuTokens.lineSubtle
            radius: NuTokens.radiusSmall

            ColumnLayout {
                id: advancedWalletOptions
                anchors.fill: parent
                anchors.margins: NuTokens.spaceMd
                spacing: NuTokens.spaceXs

                NuCheckBox {
                    id: createWalletDisablePrivateKeys
                    text: qsTr("Watch-only wallet")
                    helpText: qsTr("Create a wallet for observing addresses without storing private keys. Use this for monitoring balances, imported public keys, or shared audit wallets that should not spend coins.")
                    onCheckedChanged: if (checked) createWalletEncrypt.checked = false
                }

                NuCheckBox {
                    id: createWalletBlank
                    text: qsTr("Start empty for imports")
                    helpText: createWalletSql.checked
                              ? qsTr("Create an empty SQLite descriptor wallet for importing descriptors, recovery paths, or watch-only data before generating normal receive addresses.")
                              : qsTr("Create a legacy Berkeley DB wallet without an HD seed. Choose this only when you plan to import keys or set a seed with legacy wallet commands.")
                }

                NuCheckBox {
                    id: createWalletSql
                    text: qsTr("Modern SQL wallet (26.5+)")
                    checked: true
                    helpText: qsTr("Default for new 26.5 and later wallets. Creates a Bitcoin Core-style descriptor wallet stored in SQLite. Turn off only when you explicitly need a legacy Berkeley DB wallet for compatibility testing.")
                }
            }
        }

        onAccepted: {
            NuService.createWallet(createWalletName.text,
                                   createWalletEncrypt.checked,
                                   createWalletPassphrase.text,
                                   createWalletDisablePrivateKeys.checked,
                                   createWalletBlank.checked,
                                   createWalletSql.checked)
        }
        onClosed: {
            createWalletName.text = ""
            createWalletEncrypt.checked = false
            createWalletPassphrase.text = ""
            createWalletPassphraseConfirm.text = ""
            createWalletDisablePrivateKeys.checked = false
            createWalletBlank.checked = false
            createWalletSql.checked = true
        }
    }

    NuDialog {
        id: createRecoveryWalletDialog
        title: qsTr("Create Wallet with Recovery Phrase")
        acceptText: qsTr("Create")
        cancelText: qsTr("Cancel")
        dialogWidth: 720
        property string generatedPhrase: ""

        beforeAccept: function() {
            var phrase = createRecoveryPhraseConfirm.text.toLowerCase().replace(/\s+/g, " ").trim()
            if (createRecoveryWalletName.text.trim().length === 0) {
                messageDialog.title = qsTr("Wallet not created")
                messageDialog.text = qsTr("Enter a wallet name before creating the recovery wallet.")
                messageDialog.open()
                return false
            }
            if (phrase !== generatedPhrase) {
                messageDialog.title = qsTr("Wallet not created")
                messageDialog.text = qsTr("Confirm the 12 recovery words exactly before Nu creates a wallet from them.")
                messageDialog.open()
                return false
            }
            if (createRecoveryEncrypt.checked && createRecoveryPassphrase.text !== createRecoveryPassphraseConfirm.text) {
                messageDialog.title = qsTr("Wallet not created")
                messageDialog.text = qsTr("The wallet passphrase and confirmation do not match.")
                messageDialog.open()
                return false
            }
            if (createRecoveryEncrypt.checked && createRecoveryPassphrase.text.length < 8) {
                messageDialog.title = qsTr("Wallet not created")
                messageDialog.text = qsTr("Enter a wallet passphrase of at least 8 characters, or turn off Encrypt new wallet.")
                messageDialog.open()
                return false
            }
            return true
        }

        onOpened: {
            generatedPhrase = NuService.generateRecoveryPhrase()
            createRecoveryPhrase.text = generatedPhrase
            createRecoveryPhraseConfirm.text = ""
            if (generatedPhrase.length === 0) {
                messageDialog.title = qsTr("Recovery phrase unavailable")
                messageDialog.text = qsTr("The BIP39 English word list is not available in this build.")
                messageDialog.open()
            }
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("Write down these 12 BIP39 English words in order. Nu will create a Core HD wallet from them. The words are never saved by the app after this dialog closes.")
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        NuTextField {
            id: createRecoveryWalletName
            Layout.fillWidth: true
            placeholderText: qsTr("New wallet name")
            maximumLength: 128
            helpText: qsTr("Use a new wallet name up to 128 characters. Recovery phrase creation never overwrites an existing wallet.")
            onAccepted: createRecoveryWalletDialog.requestAccept()
        }

        NuCheckBox {
            id: createRecoveryEncrypt
            text: qsTr("Encrypt new wallet")
            checked: true
            helpText: qsTr("Recommended. Encrypts the new recovery wallet before Nu sets its seed. You will need this passphrase to spend coins.")
        }

        NuTextField {
            id: createRecoveryPassphrase
            Layout.fillWidth: true
            visible: createRecoveryEncrypt.checked
            enabled: visible
            echoMode: TextInput.Password
            placeholderText: qsTr("Wallet passphrase")
            helpText: qsTr("Use at least 8 characters. Nu uses it locally to encrypt and temporarily unlock the new wallet for seed setup.")
            onAccepted: createRecoveryWalletDialog.requestAccept()
            Keys.onReturnPressed: createRecoveryWalletDialog.requestAccept()
            Keys.onEnterPressed: createRecoveryWalletDialog.requestAccept()
        }

        NuTextField {
            id: createRecoveryPassphraseConfirm
            Layout.fillWidth: true
            visible: createRecoveryEncrypt.checked
            enabled: visible
            echoMode: TextInput.Password
            placeholderText: qsTr("Confirm wallet passphrase")
            helpText: qsTr("Re-enter the passphrase to catch typing mistakes before the recovery wallet is created.")
            onAccepted: createRecoveryWalletDialog.requestAccept()
            Keys.onReturnPressed: createRecoveryWalletDialog.requestAccept()
            Keys.onEnterPressed: createRecoveryWalletDialog.requestAccept()
        }

        TextArea {
            id: createRecoveryPhrase
            property bool mnemonicClipboardGuard: true
            Layout.fillWidth: true
            Layout.preferredHeight: 96
            readOnly: true
            selectByMouse: true
            wrapMode: TextArea.Wrap
            color: NuTokens.textPrimary
            font.family: NuTokens.monoFont
            font.pixelSize: NuTokens.fontBody
            background: Rectangle { color: NuTokens.backgroundBase; border.color: NuTokens.lineSubtle; radius: NuTokens.radiusSmall }

            Keys.onPressed: function(event) {
                if (root.isSensitiveClipboardShortcut(event)) {
                    root.requestMnemonicClipboardCopy(createRecoveryPhrase)
                    event.accepted = true
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: {
                    mnemonicCopyMenu.sourceControl = createRecoveryPhrase
                    mnemonicCopyMenu.popup()
                }
            }
        }

        TextArea {
            id: createRecoveryPhraseConfirm
            property bool mnemonicClipboardGuard: true
            Layout.fillWidth: true
            Layout.preferredHeight: 96
            placeholderText: qsTr("Type the 12 words again to confirm")
            selectByMouse: true
            wrapMode: TextArea.Wrap
            color: NuTokens.textPrimary
            font.family: NuTokens.monoFont
            font.pixelSize: NuTokens.fontBody
            background: Rectangle { color: NuTokens.panelBase; border.color: NuTokens.lineSubtle; radius: NuTokens.radiusSmall }

            Keys.onPressed: function(event) {
                if (root.isSensitiveClipboardShortcut(event)) {
                    root.requestMnemonicClipboardCopy(createRecoveryPhraseConfirm)
                    event.accepted = true
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: {
                    mnemonicCopyMenu.sourceControl = createRecoveryPhraseConfirm
                    mnemonicCopyMenu.popup()
                }
            }
        }

        onAccepted: NuService.createWalletWithRecoveryPhrase(createRecoveryWalletName.text,
                                                             generatedPhrase,
                                                             createRecoveryEncrypt.checked,
                                                             createRecoveryPassphrase.text)
        onClosed: {
            generatedPhrase = ""
            createRecoveryWalletName.text = ""
            createRecoveryEncrypt.checked = true
            createRecoveryPassphrase.text = ""
            createRecoveryPassphraseConfirm.text = ""
            createRecoveryPhrase.text = ""
            createRecoveryPhraseConfirm.text = ""
        }
    }

    NuDialog {
        id: restoreRecoveryWalletDialog
        title: qsTr("Restore Wallet from Recovery Phrase")
        acceptText: qsTr("Restore")
        cancelText: qsTr("Cancel")
        dialogWidth: 960
        dialogHeight: 760
        minimumDialogWidth: 820
        minimumDialogHeight: 560
        resizable: true
        property var previewRows: []
        property var previewDetails: []
        property var previewData: ({})
        property int phraseWordCount: 24
        property var phraseWords: []
        property bool phraseUiSyncing: false
        property bool scanPresetSyncing: false
        property string suggestionTarget: ""
        property int suggestionWordIndex: -1
        property string suggestionPrefix: ""
        property int suggestionHighlightIndex: 0
        property var bip39WordLookup: ({})
        property var bip39PrefixCache: ({})
        property var bip39SuggestionCache: ({})
        readonly property var activeSuggestions: bip39Suggestions(suggestionPrefix, suggestionTarget === "word")
        readonly property var invalidPhraseWords: findInvalidPhraseWords()

        Shortcut {
            sequences: [StandardKey.NextChild, "Tab", "Ctrl+I"]
            enabled: restoreRecoveryWalletDialog.visible
                     && restoreRecoveryWalletDialog.activeSuggestions.length > 0
                     && (restoreRecoveryPhraseBox.activeFocus || restoreRecoveryWalletDialog.suggestionTarget === "word")
            context: Qt.ApplicationShortcut
            onActivated: restoreRecoveryWalletDialog.acceptActiveSuggestion(true)
            onActivatedAmbiguously: restoreRecoveryWalletDialog.acceptActiveSuggestion(true)
        }

        function acceptActiveSuggestion(addSeparator) {
            var candidate = selectedSuggestion()
            if (candidate.length === 0)
                return false

            if (suggestionTarget === "bulk") {
                replaceBulkCurrentWord(candidate, addSeparator === true)
                clearSuggestions()
                restoreRecoveryPhraseBox.forceActiveFocus()
                return true
            }

            if (suggestionTarget === "word" && suggestionWordIndex >= 0) {
                var acceptedWordIndex = suggestionWordIndex
                var item = restoreWords.itemAt(acceptedWordIndex)
                if (item) {
                    item.text = candidate
                    item.cursorPosition = candidate.length
                    item.forceActiveFocus()
                }
                setPhraseWord(acceptedWordIndex, candidate)
                clearSuggestions()
                if (addSeparator === true && acceptedWordIndex + 1 < restoreWords.count) {
                    var nextItem = restoreWords.itemAt(acceptedWordIndex + 1)
                    if (nextItem)
                        Qt.callLater(function() { nextItem.forceActiveFocus() })
                }
                return true
            }

            return false
        }

        function activateBulkSuggestions() {
            setSuggestions("bulk", currentBulkPrefix(), -1)
        }

        function activateWordSuggestions(position, text) {
            setSuggestions("word", String(text).toLowerCase().replace(/[^a-z]/g, ""), position)
        }

        function bip39Suggestions(prefix, showAllWhenEmpty) {
            var clean = String(prefix).toLowerCase().trim()
            var words = NuService.bip39EnglishWords
            if (clean.length === 0 && !showAllWhenEmpty)
                return []
            var cacheKey = clean + "|" + (showAllWhenEmpty ? "all" : "prefix")
            if (bip39SuggestionCache[cacheKey] !== undefined)
                return bip39SuggestionCache[cacheKey]

            var exact = []
            var starts = []
            for (var i = 0; i < words.length; ++i) {
                var word = String(words[i])
                if (clean.length === 0 || word.indexOf(clean) === 0) {
                    if (word === clean)
                        exact.push(word)
                    else
                        starts.push(word)
                }
            }
            var result = exact.concat(starts)
            bip39SuggestionCache[cacheKey] = result
            return result
        }

        function clearSuggestions() {
            suggestionTarget = ""
            suggestionWordIndex = -1
            suggestionPrefix = ""
            suggestionHighlightIndex = 0
        }

        function currentBulkPrefix() {
            if (!restoreRecoveryPhraseBox.activeFocus)
                return ""

            var text = restoreRecoveryPhraseBox.text
            var cursor = restoreRecoveryPhraseBox.cursorPosition
            var before = text.substring(0, cursor)
            var after = text.substring(cursor)
            if (after.length > 0 && !/^\s/.test(after))
                return ""

            var match = before.match(/[A-Za-z]*$/)
            return match ? match[0].toLowerCase() : ""
        }

        function applyWordsToBoxes() {
            phraseUiSyncing = true
            for (var i = 0; i < restoreWords.count; ++i) {
                var item = restoreWords.itemAt(i)
                // qmllint disable missing-property
                if (item && item["text"] !== undefined) {
                    item["text"] = i < phraseWords.length ? phraseWords[i] : ""
                }
                // qmllint enable missing-property
            }
            phraseUiSyncing = false
        }

        function moveSuggestion(delta) {
            if (activeSuggestions.length === 0)
                return
            suggestionHighlightIndex = Math.max(0, Math.min(activeSuggestions.length - 1, suggestionHighlightIndex + delta))
        }

        function replaceBulkCurrentWord(candidate, addSeparator) {
            if (candidate.length === 0)
                return false

            var text = restoreRecoveryPhraseBox.text
            var cursor = restoreRecoveryPhraseBox.cursorPosition
            var before = text.substring(0, cursor)
            var after = text.substring(cursor)
            var match = before.match(/[A-Za-z]*$/)
            var prefix = match ? match[0] : ""
            var start = cursor - prefix.length
            var insertText = candidate
            var nextCursor = start + candidate.length
            if (addSeparator === true) {
                if (after.length === 0) {
                    insertText += " "
                    nextCursor += 1
                } else if (/^\s/.test(after)) {
                    nextCursor += 1
                } else {
                    insertText += " "
                    nextCursor += 1
                }
            }
            restoreRecoveryPhraseBox.text = text.substring(0, start) + insertText + after
            restoreRecoveryPhraseBox.cursorPosition = nextCursor
            return true
        }

        function selectedSuggestion() {
            if (activeSuggestions.length === 0)
                return ""
            var index = Math.max(0, Math.min(activeSuggestions.length - 1, suggestionHighlightIndex))
            return String(activeSuggestions[index])
        }

        function setSuggestions(target, prefix, wordIndex) {
            suggestionTarget = target
            suggestionWordIndex = wordIndex
            suggestionPrefix = String(prefix).toLowerCase().replace(/[^a-z]/g, "")
            suggestionHighlightIndex = 0
        }

        function findInvalidPhraseWords() {
            var invalid = []
            var seen = {}
            for (var i = 0; i < phraseWords.length; ++i) {
                var word = String(phraseWords[i]).toLowerCase().trim()
                if (word.length === 0 || wordHasBip39Prefix(word))
                    continue
                if (seen[word])
                    continue
                seen[word] = true
                invalid.push(word)
            }
            return invalid
        }

        function setPhraseFromBulkText(text) {
            if (phraseUiSyncing)
                return

            var normalized = String(text).toLowerCase().replace(/[^a-z\s]/g, " ").replace(/\s+/g, " ").trim()
            var parts = normalized.length > 0 ? normalized.split(" ") : []
            var allowedCounts = [12, 15, 18, 21, 24]
            var targetCount = phraseWordCount
            if (parts.length > phraseWordCount) {
                for (var grow = 0; grow < allowedCounts.length; ++grow) {
                    if (parts.length <= allowedCounts[grow]) {
                        targetCount = allowedCounts[grow]
                        break
                    }
                }
            } else if (allowedCounts.indexOf(parts.length) >= 0 && parts.length !== phraseWordCount) {
                var candidate = NuService.validateRecoveryPhrase(normalized)
                if (candidate.valid)
                    targetCount = parts.length
            }
            if (targetCount !== phraseWordCount) {
                phraseUiSyncing = true
                restoreRecoveryWordCount.currentIndex = allowedCounts.indexOf(targetCount)
                phraseUiSyncing = false
                phraseWordCount = targetCount
            }

            var next = []
            for (var i = 0; i < phraseWordCount; ++i)
                next.push(i < parts.length ? parts[i] : "")
            phraseWords = next
            clearPreview()
            applyWordsToBoxes()
            refreshValidation()
        }

        function updateBulkTextFromWords() {
            if (phraseUiSyncing)
                return

            phraseUiSyncing = true
            restoreRecoveryPhraseBox.text = phraseText()
            restoreRecoveryPhraseBox.cursorPosition = restoreRecoveryPhraseBox.text.length
            phraseUiSyncing = false
        }

        function phraseText() {
            return phraseWords.join(" ").replace(/\s+/g, " ").toLowerCase().trim()
        }

        function ensureBip39WordLookup() {
            if (bip39WordLookup["abandon"] === true)
                return bip39WordLookup
            var lookup = {}
            var words = NuService.bip39EnglishWords
            for (var i = 0; i < words.length; ++i)
                lookup[String(words[i])] = true
            bip39WordLookup = lookup
            return lookup
        }

        function phraseHasCompleteExactWords() {
            var allowedCounts = [12, 15, 18, 21, 24]
            var text = phraseText()
            var parts = text.length > 0 ? text.split(" ") : []
            if (allowedCounts.indexOf(parts.length) < 0 || parts.length !== phraseWordCount)
                return false

            var lookup = ensureBip39WordLookup()
            for (var i = 0; i < parts.length; ++i) {
                if (lookup[parts[i]] !== true)
                    return false
            }
            return true
        }

        function resetPhraseWords() {
            var words = []
            for (var i = 0; i < phraseWordCount; ++i) words.push("")
            phraseWords = words
            updateBulkTextFromWords()
            applyWordsToBoxes()
        }

        function setPhraseWord(position, value) {
            if (phraseUiSyncing)
                return
            var next = phraseWords.slice(0)
            while (next.length < phraseWordCount) next.push("")
            next[position] = String(value).toLowerCase().trim()
            phraseWords = next
            clearPreview()
            updateBulkTextFromWords()
            refreshValidation()
        }

        function selectedWifMode() {
            return restoreRecoveryWifFormat.currentIndex === 1 ? "legacy" : "current"
        }

        function clearPreview() {
            previewRows = []
            previewDetails = []
            previewData = {}
            restoreRecoveryPreviewMessage.text = ""
        }

        function selectedImportRange() {
            if (restoreRecoveryScanPreset.currentIndex === 0)
                return -1024
            var parsed = parseInt(restoreRecoveryRange.text)
            if (isNaN(parsed))
                return 512
            return Math.max(1, Math.min(1000, parsed))
        }

        function validationResult() {
            return NuService.validateRecoveryPhrase(phraseText())
        }

        function wordHasBip39Prefix(word) {
            var clean = String(word).toLowerCase().trim()
            if (clean.length === 0)
                return true
            if (bip39PrefixCache[clean] !== undefined)
                return bip39PrefixCache[clean]
            var words = NuService.bip39EnglishWords
            for (var i = 0; i < words.length; ++i) {
                if (String(words[i]).indexOf(clean) === 0) {
                    bip39PrefixCache[clean] = true
                    return true
                }
            }
            bip39PrefixCache[clean] = false
            return false
        }

        function refreshValidation() {
            var result = validationResult()
            restoreRecoveryStatus.text = result.message
            restoreRecoveryStatus.color = result.valid ? NuTokens.accentSky : NuTokens.textSecondary
        }

        function refreshCompletionAndSuggestions() {
            refreshValidation()
            if (phraseHasCompleteExactWords()) {
                clearSuggestions()
                return true
            }
            return false
        }

        beforeAccept: function() {
            var result = validationResult()
            if (!result.valid) {
                messageDialog.title = qsTr("Wallet not restored")
                messageDialog.text = result.message
                messageDialog.open()
                return false
            }
            if (restoreRecoveryWalletName.text.trim().length === 0) {
                messageDialog.title = qsTr("Wallet not restored")
                messageDialog.text = qsTr("Enter a new wallet name before restoring.")
                messageDialog.open()
                return false
            }
            if (restoreRecoveryMode.currentIndex === 1 && previewRows.length === 0) {
                messageDialog.title = qsTr("Preview required")
                messageDialog.text = qsTr("Preview the first addresses before importing an external derivation path.")
                messageDialog.open()
                return false
            }
            if (restoreRecoveryEncrypt.checked && restoreRecoveryPassphrase.text !== restoreRecoveryPassphraseConfirm.text) {
                messageDialog.title = qsTr("Wallet not restored")
                messageDialog.text = qsTr("The wallet passphrase and confirmation do not match.")
                messageDialog.open()
                return false
            }
            if (restoreRecoveryEncrypt.checked && restoreRecoveryPassphrase.text.length < 8) {
                messageDialog.title = qsTr("Wallet not restored")
                messageDialog.text = qsTr("Enter a wallet passphrase of at least 8 characters, or turn off Encrypt recovered wallet.")
                messageDialog.open()
                return false
            }
            return true
        }

        onOpened: resetPhraseWords()

        Label {
            Layout.fillWidth: true
            text: qsTr("Nu supports 12, 15, 18, 21, and 24-word BIP39 English phrases. Use Nu/Core HD for phrases created by Nu. Use Advanced external scan for Coinomi, Ian Coleman, or other external wallet recovery after you recognize the previewed addresses. Extended keys may be read as xpub/xprv or Defcoin dfcp/dfcv; generated P2SH addresses remain canonical M..., while old 3... and tool 9/A... encodings are accepted for compatibility.")
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("If a recovery phrase leaks during import, and it came from a multi-coin wallet such as Coinomi, every coin wallet derived from that phrase could be exposed. Keep the phrase private. For the strongest practice with high-value phrases, use an offline or freshly trusted machine: disconnect before typing or pasting, recover or sweep the Defcoin wallet, and move any other coins tied to that phrase to new wallet addresses before reusing the phrase on a connected machine. If you are confident the machine, clipboard, and sync tools are not compromised, that level of isolation may not be necessary.")
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        NuTextField {
            id: restoreRecoveryWalletName
            Layout.fillWidth: true
            placeholderText: qsTr("New restored wallet name")
            maximumLength: 128
            helpText: qsTr("Use a new wallet name up to 128 characters. Restore never overwrites an existing wallet.")
        }

        NuCheckBox {
            id: restoreRecoveryEncrypt
            text: qsTr("Encrypt recovered wallet")
            checked: true
            helpText: qsTr("Recommended. Encrypts the newly created recovery wallet before imported keys are added. Nu temporarily unlocks it only long enough to import and rescan, then locks it again.")
        }

        NuTextField {
            id: restoreRecoveryPassphrase
            Layout.fillWidth: true
            visible: restoreRecoveryEncrypt.checked
            enabled: visible
            echoMode: TextInput.Password
            placeholderText: qsTr("Wallet passphrase")
            helpText: qsTr("Use at least 8 characters. This protects the recovered private keys stored in the wallet file.")
            onAccepted: restoreRecoveryWalletDialog.requestAccept()
            Keys.onReturnPressed: restoreRecoveryWalletDialog.requestAccept()
            Keys.onEnterPressed: restoreRecoveryWalletDialog.requestAccept()
        }

        NuTextField {
            id: restoreRecoveryPassphraseConfirm
            Layout.fillWidth: true
            visible: restoreRecoveryEncrypt.checked
            enabled: visible
            echoMode: TextInput.Password
            placeholderText: qsTr("Confirm wallet passphrase")
            helpText: qsTr("Re-enter the wallet passphrase to catch typing mistakes before recovery starts.")
            onAccepted: restoreRecoveryWalletDialog.requestAccept()
            Keys.onReturnPressed: restoreRecoveryWalletDialog.requestAccept()
            Keys.onEnterPressed: restoreRecoveryWalletDialog.requestAccept()
        }

        NuComboBox {
            id: restoreRecoveryWordCount
            Layout.fillWidth: true
            model: ["12", "15", "18", "21", "24"]
            currentIndex: 4
            helpText: qsTr("Select the BIP39 phrase length. Coinomi recovery phrases are often 24 words; Nu-created recovery wallets use 12 words.")
            onCurrentTextChanged: {
                if (restoreRecoveryWalletDialog.phraseUiSyncing)
                    return
                restoreRecoveryWalletDialog.phraseWordCount = parseInt(currentText)
                restoreRecoveryWalletDialog.resetPhraseWords()
                restoreRecoveryWalletDialog.clearPreview()
                restoreRecoveryWalletDialog.refreshValidation()
            }
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("Paste or type the full phrase")
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            font.weight: Font.DemiBold
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 118
            color: NuTokens.panelBase
            border.color: restoreRecoveryWalletDialog.invalidPhraseWords.length > 0
                          ? NuTokens.stateError
                          : (restoreRecoveryPhraseBox.activeFocus ? NuTokens.lineStrong : NuTokens.lineSubtle)
            border.width: restoreRecoveryPhraseBox.activeFocus ? 2 : 1
            radius: NuTokens.radiusSmall
            clip: true

            TextArea {
                id: restoreRecoveryPhraseBox
                property bool mnemonicClipboardGuard: true
                anchors.fill: parent
                anchors.margins: NuTokens.spaceMd
                background: null
                color: NuTokens.textPrimary
                font.family: NuTokens.bodyFont
                font.pixelSize: NuTokens.fontBody
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhLowercaseOnly
                placeholderText: qsTr("Paste or type 12, 15, 18, 21, or 24 BIP39 words")
                placeholderTextColor: NuTokens.textMuted
                selectByMouse: true
                selectedTextColor: NuTokens.textInverse
                selectionColor: NuTokens.lineStrong
                textFormat: TextEdit.PlainText
                wrapMode: TextArea.WrapAnywhere

                Keys.priority: Keys.BeforeItem
                Keys.onPressed: function(event) {
                    if (root.isSensitiveClipboardShortcut(event)) {
                        root.requestMnemonicClipboardCopy(restoreRecoveryPhraseBox)
                        event.accepted = true
                        return
                    }
                    if (event.key === Qt.Key_Down && restoreRecoveryWalletDialog.activeSuggestions.length > 0) {
                        restoreRecoveryWalletDialog.moveSuggestion(1)
                        event.accepted = true
                        return
                    }
                    if (event.key === Qt.Key_Up && restoreRecoveryWalletDialog.activeSuggestions.length > 0) {
                        restoreRecoveryWalletDialog.moveSuggestion(-1)
                        event.accepted = true
                        return
                    }
                    if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            && restoreRecoveryWalletDialog.activeSuggestions.length > 0) {
                        restoreRecoveryWalletDialog.acceptActiveSuggestion(true)
                        event.accepted = true
                        return
                    }
                    if (event.key === Qt.Key_Escape && restoreRecoveryWalletDialog.activeSuggestions.length > 0) {
                        restoreRecoveryWalletDialog.clearSuggestions()
                        event.accepted = true
                    }
                }
                Keys.onTabPressed: function(event) {
                    if (restoreRecoveryWalletDialog.activeSuggestions.length > 0) {
                        restoreRecoveryWalletDialog.acceptActiveSuggestion(true)
                        event.accepted = true
                    }
                }

                onActiveFocusChanged: if (activeFocus) restoreRecoveryWalletDialog.activateBulkSuggestions()
                onCursorPositionChanged: if (activeFocus) restoreRecoveryWalletDialog.activateBulkSuggestions()
                onTextChanged: {
                    restoreRecoveryWalletDialog.setPhraseFromBulkText(text)
                    if (restoreRecoveryWalletDialog.refreshCompletionAndSuggestions())
                        return
                    if (activeFocus) restoreRecoveryWalletDialog.activateBulkSuggestions()
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: {
                        mnemonicCopyMenu.sourceControl = restoreRecoveryPhraseBox
                        mnemonicCopyMenu.popup()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.rightMargin: 38
            Layout.preferredHeight: 128
            visible: restoreRecoveryWalletDialog.suggestionTarget === "bulk"
                     && restoreRecoveryWalletDialog.activeSuggestions.length > 0
            color: NuTokens.backgroundBase
            border.color: NuTokens.lineSubtle
            radius: NuTokens.radiusSmall
            clip: true

            GridView {
                id: bulkSuggestionGrid
                anchors.fill: parent
                anchors.leftMargin: 2
                anchors.topMargin: 2
                anchors.bottomMargin: 2
                anchors.rightMargin: 16
                cellWidth: 116
                cellHeight: 30
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: restoreRecoveryWalletDialog.suggestionHighlightIndex
                model: restoreRecoveryWalletDialog.activeSuggestions

                onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, GridView.Contain)

                Basic.ScrollBar.vertical: Basic.ScrollBar {
                    interactive: true
                    policy: Basic.ScrollBar.AlwaysOn
                    width: 12
                }

                delegate: Rectangle {
                    required property int index
                    required property string modelData
                    width: bulkSuggestionGrid.cellWidth
                    height: bulkSuggestionGrid.cellHeight
                    color: index === restoreRecoveryWalletDialog.suggestionHighlightIndex ? NuTokens.lineStrong : "transparent"
                    radius: NuTokens.radiusSmall

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: NuTokens.spaceSm
                        anchors.rightMargin: NuTokens.spaceSm
                        text: modelData
                        color: index === restoreRecoveryWalletDialog.suggestionHighlightIndex ? NuTokens.textInverse : NuTokens.textPrimary
                        font.family: NuTokens.bodyFont
                        font.pixelSize: NuTokens.fontSmall
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: restoreRecoveryWalletDialog.suggestionHighlightIndex = index
                        onClicked: restoreRecoveryWalletDialog.acceptActiveSuggestion(true)
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("Autocomplete: type normally. Press Tab or Enter to use the highlighted suggestion; use Up/Down or click to choose another. Space keeps the word exactly as typed.")
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        Flow {
            Layout.fillWidth: true
            visible: restoreRecoveryWalletDialog.invalidPhraseWords.length > 0
            spacing: NuTokens.spaceSm

            Label {
                text: qsTr("Unknown BIP39 word:")
                color: NuTokens.stateError
                font.pixelSize: NuTokens.fontSmall
            }
            Repeater {
                model: restoreRecoveryWalletDialog.invalidPhraseWords

                Label {
                    required property string modelData
                    text: modelData
                    color: NuTokens.stateError
                    font.pixelSize: NuTokens.fontSmall
                    font.strikeout: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.rightMargin: 38
            Layout.preferredHeight: 158
            visible: restoreRecoveryWalletDialog.suggestionTarget === "word"
                     && restoreRecoveryWalletDialog.activeSuggestions.length > 0
            color: NuTokens.backgroundBase
            border.color: NuTokens.lineSubtle
            radius: NuTokens.radiusSmall
            clip: true

            GridView {
                id: wordSuggestionGrid
                anchors.fill: parent
                anchors.leftMargin: 2
                anchors.topMargin: 2
                anchors.bottomMargin: 2
                anchors.rightMargin: 16
                cellWidth: 116
                cellHeight: 30
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: restoreRecoveryWalletDialog.suggestionHighlightIndex
                model: restoreRecoveryWalletDialog.activeSuggestions

                onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, GridView.Contain)

                Basic.ScrollBar.vertical: Basic.ScrollBar {
                    interactive: true
                    policy: Basic.ScrollBar.AlwaysOn
                    width: 12
                }

                delegate: Rectangle {
                    required property int index
                    required property string modelData
                    width: wordSuggestionGrid.cellWidth
                    height: wordSuggestionGrid.cellHeight
                    color: index === restoreRecoveryWalletDialog.suggestionHighlightIndex ? NuTokens.lineStrong : "transparent"
                    radius: NuTokens.radiusSmall

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: NuTokens.spaceSm
                        anchors.rightMargin: NuTokens.spaceSm
                        text: modelData
                        color: index === restoreRecoveryWalletDialog.suggestionHighlightIndex ? NuTokens.textInverse : NuTokens.textPrimary
                        font.family: NuTokens.bodyFont
                        font.pixelSize: NuTokens.fontSmall
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: restoreRecoveryWalletDialog.suggestionHighlightIndex = index
                        onClicked: restoreRecoveryWalletDialog.acceptActiveSuggestion(true)
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: NuTokens.spaceSm
            rowSpacing: NuTokens.spaceSm

            Repeater {
                id: restoreWords
                model: restoreRecoveryWalletDialog.phraseWordCount
                Basic.TextField {
                    id: recoveryWordField
                    required property int index
                    property bool mnemonicClipboardGuard: true
                    property string normalizedEditText: String(text).toLowerCase().trim()
                    property bool wordInvalid: normalizedEditText.length > 0 && !restoreRecoveryWalletDialog.wordHasBip39Prefix(normalizedEditText)
                    Layout.fillWidth: true
                    activeFocusOnTab: true
                    color: wordInvalid ? NuTokens.stateError : NuTokens.textPrimary
                    font.family: NuTokens.bodyFont
                    font.pixelSize: NuTokens.fontSmall
                    font.strikeout: wordInvalid
                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhLowercaseOnly
                    leftPadding: NuTokens.spaceMd
                    rightPadding: NuTokens.spaceMd
                    placeholderText: qsTr("word ") + (index + 1)
                    placeholderTextColor: NuTokens.textMuted
                    selectedTextColor: NuTokens.textInverse
                    selectionColor: NuTokens.lineStrong
                    selectByMouse: true
                    Accessible.name: qsTr("Recovery word ") + (index + 1)

                    Keys.priority: Keys.BeforeItem
                    Keys.onPressed: function(event) {
                        if (root.isSensitiveClipboardShortcut(event)) {
                            root.requestMnemonicClipboardCopy(recoveryWordField)
                            event.accepted = true
                            return
                        }
                        if (event.key === Qt.Key_Down && restoreRecoveryWalletDialog.activeSuggestions.length > 0) {
                            restoreRecoveryWalletDialog.moveSuggestion(1)
                            event.accepted = true
                            return
                        }
                        if (event.key === Qt.Key_Up && restoreRecoveryWalletDialog.activeSuggestions.length > 0) {
                            restoreRecoveryWalletDialog.moveSuggestion(-1)
                            event.accepted = true
                            return
                        }
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                && restoreRecoveryWalletDialog.activeSuggestions.length > 0) {
                            restoreRecoveryWalletDialog.acceptActiveSuggestion(false)
                            event.accepted = true
                            return
                        }
                        if (event.key === Qt.Key_Escape && restoreRecoveryWalletDialog.activeSuggestions.length > 0) {
                            restoreRecoveryWalletDialog.clearSuggestions()
                            event.accepted = true
                        }
                    }
                    Keys.onTabPressed: function(event) {
                        if (restoreRecoveryWalletDialog.activeSuggestions.length > 0) {
                            restoreRecoveryWalletDialog.acceptActiveSuggestion(true)
                            event.accepted = true
                        }
                    }

                    onActiveFocusChanged: if (activeFocus) restoreRecoveryWalletDialog.activateWordSuggestions(index, text)
                    onTextEdited: {
                        var cursor = cursorPosition
                        var clean = text.toLowerCase().replace(/[^a-z]/g, "")
                        if (clean !== text) {
                            text = clean
                            cursorPosition = Math.min(cursor, clean.length)
                        }
                        restoreRecoveryWalletDialog.setPhraseWord(index, text)
                        if (restoreRecoveryWalletDialog.refreshCompletionAndSuggestions())
                            return
                        restoreRecoveryWalletDialog.activateWordSuggestions(index, text)
                    }

                    background: Rectangle {
                        color: NuTokens.panelBase
                        border.color: recoveryWordField.wordInvalid ? NuTokens.stateError : (recoveryWordField.activeFocus ? NuTokens.lineStrong : NuTokens.lineSubtle)
                        border.width: recoveryWordField.activeFocus ? 2 : 1
                        radius: NuTokens.radiusSmall
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: {
                            mnemonicCopyMenu.sourceControl = recoveryWordField
                            mnemonicCopyMenu.popup()
                        }
                    }
                }
            }
        }

        Label {
            id: restoreRecoveryStatus
            Layout.fillWidth: true
            text: qsTr("Enter the recovery words.")
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        NuComboBox {
            id: restoreRecoveryMode
            Layout.fillWidth: true
            model: [qsTr("Auto (cycle through common recovery options)"), qsTr("Advanced external scan"), qsTr("Nu/Core HD")]
            helpText: qsTr("Auto imports several common Coinomi/Ian Coleman and legacy derivation paths in one rescan, then reports which method found coins. Advanced lets you pick one path manually. Nu/Core HD is for phrases created by Nu.")
            onCurrentIndexChanged: restoreRecoveryWalletDialog.clearPreview()
        }

        Label {
            Layout.fillWidth: true
            text: restoreRecoveryMode.currentIndex === 0
                  ? qsTr("Recommended for recovery: Auto tries common receive and change-address paths in one scan and reports the path that found coins.")
                  : (restoreRecoveryMode.currentIndex === 1
                     ? qsTr("Advanced mode imports only the selected derivation path. Use it when you already know the path from another wallet or Ian Coleman output.")
                     : qsTr("Nu/Core HD sets the wallet seed for phrases created by Nu. It is not the best default for Coinomi or Ian Coleman recovery."))
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        NuComboBox {
            id: restoreRecoveryPathPreset
            Layout.fillWidth: true
            visible: restoreRecoveryMode.currentIndex === 1
            enabled: visible
            model: [
                qsTr("Coinomi/Ian Coleman Defcoin BIP44: m/44'/1337'/0'/0/*"),
                qsTr("Legacy Bitcoin-family BIP44: m/44'/0'/0'/0/*"),
                qsTr("Litecoin-family BIP44: m/44'/2'/0'/0/*"),
                qsTr("Legacy BIP32 external chain: m/0/*"),
                qsTr("Custom path")
            ]
            helpText: qsTr("Choose a common external recovery path, then preview addresses before importing. Ian Coleman's Defcoin entry uses coin type 1337.")
            onCurrentIndexChanged: {
                if (currentIndex === 0) restoreRecoveryPath.text = "m/44'/1337'/0'/0/*"
                else if (currentIndex === 1) restoreRecoveryPath.text = "m/44'/0'/0'/0/*"
                else if (currentIndex === 2) restoreRecoveryPath.text = "m/44'/2'/0'/0/*"
                else if (currentIndex === 3) restoreRecoveryPath.text = "m/0/*"
                restoreRecoveryWalletDialog.clearPreview()
            }
        }

        NuTextField {
            id: restoreRecoveryPath
            Layout.fillWidth: true
            visible: restoreRecoveryMode.currentIndex === 1
            enabled: visible
            text: "m/44'/1337'/0'/0/*"
            placeholderText: qsTr("m/44'/1337'/0'/0/*")
            helpText: qsTr("External recovery path. It must start with m/ and end with /* so Nu can import a bounded range.")
            onTextChanged: restoreRecoveryWalletDialog.clearPreview()
        }

        NuComboBox {
            id: restoreRecoveryWifFormat
            Layout.fillWidth: true
            visible: restoreRecoveryMode.currentIndex === 1
            enabled: visible
            model: [
                qsTr("Current Defcoin v1.0.0+ WIF (T...)"),
                qsTr("Legacy Defcoin v0.22 / Ian Coleman WIF reference (Q...)")
            ]
            helpText: qsTr("Defcoin v0.22/Ian Coleman used WIF prefix 0x9e, which renders as Q. Defcoin v1.0.0+ uses 0xb0, which renders as T. Nu imports current-wallet-compatible keys while letting you match either recovery reference.")
            onCurrentIndexChanged: restoreRecoveryWalletDialog.clearPreview()
        }

        NuComboBox {
            id: restoreRecoveryScanPreset
            Layout.fillWidth: true
            visible: restoreRecoveryMode.currentIndex !== 2
            enabled: visible
            model: [
                qsTr("Auto until 1024 empty addresses"),
                qsTr("Auto aggressive fixed scan: 512 addresses"),
                qsTr("Quick scan: 64 addresses"),
                qsTr("Standard recovery scan: 256 addresses"),
                qsTr("Deep recovery scan: 512 addresses"),
                qsTr("Deep manual scan: 1000 addresses"),
                qsTr("Custom address count")
            ]
            helpText: qsTr("Auto-until-empty is best for wallets where a user mistakenly mined directly into wallet-derived addresses. It keeps scanning a method until it sees 1024 empty derived addresses in a row after the last address with coins. Fixed scans import only the selected address count.")
            onCurrentIndexChanged: {
                if (restoreRecoveryWalletDialog.scanPresetSyncing)
                    return
                var value = ""
                if (currentIndex === 0) value = "1024"
                else if (currentIndex === 1) value = "512"
                else if (currentIndex === 2) value = "64"
                else if (currentIndex === 3) value = "256"
                else if (currentIndex === 4) value = "512"
                else if (currentIndex === 5) value = "1000"
                if (value.length > 0) {
                    restoreRecoveryWalletDialog.scanPresetSyncing = true
                    restoreRecoveryRange.text = value
                    restoreRecoveryWalletDialog.scanPresetSyncing = false
                    restoreRecoveryWalletDialog.clearPreview()
                }
            }
        }

        NuTextField {
            id: restoreRecoveryRange
            Layout.fillWidth: true
            visible: restoreRecoveryMode.currentIndex !== 2
            enabled: visible && restoreRecoveryScanPreset.currentIndex !== 0
            text: "1024"
            placeholderText: qsTr("Address count, e.g. 512")
            helpText: qsTr("Number of external addresses to import and rescan for this path. External wallets can use far more than 64 addresses, and mined-to-wallet payout history can consume many addresses. Try 256, 512, or 1000 when a smaller scan misses coins or history; if 1000 still misses funds, use a targeted expert recovery workflow.")
            validator: IntValidator { bottom: 1; top: 1000 }
            onTextChanged: {
                if (!restoreRecoveryWalletDialog.scanPresetSyncing && restoreRecoveryScanPreset.currentIndex !== 6) {
                    restoreRecoveryWalletDialog.scanPresetSyncing = true
                    restoreRecoveryScanPreset.currentIndex = 6
                    restoreRecoveryWalletDialog.scanPresetSyncing = false
                }
                restoreRecoveryWalletDialog.clearPreview()
            }
        }

        Label {
            visible: restoreRecoveryMode.currentIndex !== 2
            Layout.fillWidth: true
            text: restoreRecoveryScanPreset.currentIndex === 0
                  ? qsTr("Auto-until-empty can take much longer than fixed scans. It imports and rescans in batches, then stops each method only after 1024 consecutive derived addresses show no received coins. This is intended for unusual recovery cases such as old wallets that were used as mining payout targets.")
                  : (restoreRecoveryMode.currentIndex === 0
                     ? qsTr("Auto recovery imports several common external and change-address paths, then Core rescans the chain once. Larger ranges take longer and can recover later-used addresses that smaller scans miss, but a fixed address count is not exhaustive for every historical wallet.")
                     : qsTr("Recovery imports the selected address range, then Core rescans the chain once. Larger ranges take longer and can recover later-used addresses that smaller scans miss, but a fixed address count is not exhaustive for every historical wallet."))
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        NuActionButton {
            visible: restoreRecoveryMode.currentIndex === 1
            enabled: visible
            text: qsTr("Preview first addresses")
            helpText: qsTr("Derive the first addresses for this phrase and path before importing anything into a wallet.")
            onClicked: {
                restoreRecoveryWalletDialog.previewRows = []
                restoreRecoveryWalletDialog.previewDetails = []
                restoreRecoveryWalletDialog.previewData = {}
                restoreRecoveryPreviewMessage.text = qsTr("Deriving preview addresses...")
                NuService.previewRecoveryPhraseAddresses(restoreRecoveryWalletDialog.phraseText(), restoreRecoveryPath.text, restoreRecoveryWalletDialog.selectedWifMode(), 5)
            }
        }

        Label {
            id: restoreRecoveryPreviewMessage
            visible: restoreRecoveryMode.currentIndex === 1
            Layout.fillWidth: true
            text: ""
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            visible: restoreRecoveryMode.currentIndex === 1 && restoreRecoveryWalletDialog.previewDetails.length > 0
            Layout.fillWidth: true
            spacing: NuTokens.spaceSm

            Label {
                Layout.fillWidth: true
                text: qsTr("Derivation details")
                color: NuTokens.textPrimary
                font.pixelSize: NuTokens.fontBody
                font.weight: Font.DemiBold
            }

            Repeater {
                model: restoreRecoveryWalletDialog.previewDetails

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: NuTokens.spaceMd

                    Label {
                        Layout.preferredWidth: 160
                        text: modelData.cells && modelData.cells.length > 0 ? modelData.cells[0] : ""
                        color: NuTokens.textSecondary
                        font.pixelSize: NuTokens.fontSmall
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.WordWrap
                    }
                    Label {
                        Layout.fillWidth: true
                        text: modelData.cells && modelData.cells.length > 1 ? modelData.cells[1] : ""
                        color: NuTokens.textPrimary
                        font.family: String(text).length > 48 ? NuTokens.monoFont : NuTokens.bodyFont
                        font.pixelSize: NuTokens.fontSmall
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }

        ColumnLayout {
            visible: restoreRecoveryMode.currentIndex === 1 && restoreRecoveryWalletDialog.previewRows.length > 0
            Layout.fillWidth: true
            spacing: NuTokens.spaceXs

            Label {
                Layout.fillWidth: true
                text: qsTr("Previewed addresses")
                color: NuTokens.textPrimary
                font.pixelSize: NuTokens.fontBody
                font.weight: Font.DemiBold
            }

            Repeater {
                model: restoreRecoveryWalletDialog.previewRows
                Label {
                    required property var modelData
                    Layout.fillWidth: true
                    text: "#" + modelData.index + "  " + modelData.address
                    color: NuTokens.textPrimary
                    font.family: NuTokens.monoFont
                    font.pixelSize: NuTokens.fontSmall
                    wrapMode: Text.WrapAnywhere
                }
            }

            Label {
                Layout.fillWidth: true
                text: qsTr("Next step: compare these first addresses with the source wallet or Ian Coleman output. If they match, enter a new wallet name and click Restore. If they do not match, choose another derivation preset/path and preview again before creating a wallet.")
                color: NuTokens.textSecondary
                font.pixelSize: NuTokens.fontSmall
                wrapMode: Text.WordWrap
            }
        }

        onAccepted: {
            NuService.restoreWalletFromRecoveryPhrase(restoreRecoveryWalletName.text,
                                                      phraseText(),
                                                      restoreRecoveryMode.currentIndex === 0 ? "auto" : (restoreRecoveryMode.currentIndex === 1 ? "external" : "core"),
                                                      restoreRecoveryPath.text,
                                                      restoreRecoveryWalletDialog.selectedWifMode(),
                                                      restoreRecoveryWalletDialog.selectedImportRange(),
                                                      restoreRecoveryEncrypt.checked,
                                                      restoreRecoveryPassphrase.text)
        }
        onClosed: {
            restoreRecoveryWalletName.text = ""
            restoreRecoveryEncrypt.checked = true
            restoreRecoveryPassphrase.text = ""
            restoreRecoveryPassphraseConfirm.text = ""
            restoreRecoveryMode.currentIndex = 0
            restoreRecoveryPathPreset.currentIndex = 0
            restoreRecoveryPath.text = "m/44'/1337'/0'/0/*"
            restoreRecoveryWifFormat.currentIndex = 0
            restoreRecoveryScanPreset.currentIndex = 0
            restoreRecoveryRange.text = "1024"
            previewRows = []
            previewDetails = []
            previewData = {}
            restoreRecoveryPreviewMessage.text = ""
            restoreRecoveryWordCount.currentIndex = 4
            phraseWordCount = 24
            resetPhraseWords()
            clearSuggestions()
            for (var i = 0; i < restoreWords.count; ++i) {
                var item = restoreWords.itemAt(i)
                // qmllint disable missing-property
                if (item && item["text"] !== undefined) item["text"] = ""
                // qmllint enable missing-property
            }
        }
    }

    NuDialog {
        id: closeWalletDialog
        title: qsTr("Close Wallet")
        acceptText: qsTr("Close Wallet")
        cancelText: qsTr("Cancel")
        dialogWidth: 620

        Label {
            Layout.fillWidth: true
            text: qsTr("Unload the current wallet from this session. Wallet files, keys, and funds are not deleted.")
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.fillWidth: true
            text: NuService.walletSelected ? qsTr("Current wallet: ") + NuService.walletDisplayName(NuService.currentWalletName) : qsTr("No wallet is currently selected.")
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        onAccepted: NuService.closeWallet("")
    }

    NuDialog {
        id: closeAllWalletsDialog
        title: qsTr("Close All Wallets")
        acceptText: qsTr("Close All")
        cancelText: qsTr("Cancel")
        dialogWidth: 620

        Label {
            Layout.fillWidth: true
            text: qsTr("Unload all loaded wallets from this session. Wallet files, keys, and funds are not deleted.")
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        onAccepted: NuService.closeAllWallets()
    }

    NuDialog {
        id: deleteWalletDialog
        title: qsTr("Delete Wallet")
        acceptText: qsTr("Move Wallet")
        cancelText: qsTr("Cancel")
        dialogWidth: 700
        acceptEnabled: deleteWalletConfirm.text === "MOVE WALLET"

        property string selectedWalletName: deleteWalletSelector.currentIndex >= 0 && deleteWalletSelector.currentIndex < NuService.availableWallets.length
                                            ? String(NuService.availableWallets[deleteWalletSelector.currentIndex])
                                            : ""

        beforeAccept: function() {
            if (deleteWalletDialog.selectedWalletName.length === 0) {
                messageDialog.title = qsTr("Wallet not deleted")
                messageDialog.text = qsTr("Nu does not delete the legacy default wallet.dat from this screen. Back it up first and remove it manually from the Defcoin data directory if you really intend to retire it.")
                messageDialog.open()
                return false
            }
            if (deleteWalletConfirm.text !== "MOVE WALLET") {
                return false
            }
            return true
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("This is the destructive wallet-file cleanup action. For safety, Nu does not shred wallet files. It closes the selected wallet if needed, then moves its wallet directory into a timestamped Deleted Wallets folder inside the Defcoin data directory. Back up any wallet before deleting it.")
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
        }

        NuComboBox {
            id: deleteWalletSelector
            Layout.fillWidth: true
            model: NuService.availableWallets
            textFormatter: function(value) { return NuService.walletDisplayName(String(value)) }
            helpText: qsTr("Select a non-default wallet to move out of the active wallet list. Default wallet (wallet.dat) is intentionally protected here.")
            onActivated: function(index) {
                if (index >= 0 && index < NuService.availableWallets.length) {
                    NuService.setCurrentWallet(NuService.availableWallets[index])
                }
            }
        }

        Label {
            Layout.fillWidth: true
            text: deleteWalletDialog.selectedWalletName.length === 0
                  ? qsTr("Default wallet (wallet.dat) is protected from this delete action.")
                  : qsTr("Selected wallet: ") + NuService.walletDisplayName(deleteWalletDialog.selectedWalletName)
            color: deleteWalletDialog.selectedWalletName.length === 0 ? NuTokens.stateWarning : NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 5
            columnSpacing: NuTokens.spaceMd
            rowSpacing: NuTokens.spaceXs

            NuMetricRow { label: qsTr("Total"); value: NuService.totalBalance }
            NuMetricRow { label: qsTr("Available"); value: NuService.availableBalance }
            NuMetricRow { label: qsTr("Pending"); value: NuService.pendingBalance }
            NuMetricRow { label: qsTr("Immature"); value: NuService.immatureBalance }
            NuMetricRow { label: qsTr("Transactions"); value: NuService.walletTransactionCount }
        }

        Label {
            Layout.fillWidth: true
            text: deleteWalletDialog.selectedWalletName === NuService.currentWalletName
                  ? qsTr("The summary above is for the wallet selected for deletion.")
                  : qsTr("Open/select this wallet first if you want Nu to refresh its exact balance and transaction summary before moving it.")
            color: deleteWalletDialog.selectedWalletName === NuService.currentWalletName ? NuTokens.textSecondary : NuTokens.stateWarning
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("Before continuing, make sure this wallet is backed up and that you are not moving the only copy of private keys for funds you still need. To confirm, type MOVE WALLET.")
            color: NuTokens.stateWarning
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }

        NuTextField {
            id: deleteWalletConfirm
            Layout.fillWidth: true
            placeholderText: qsTr("MOVE WALLET")
            helpText: qsTr("Typed confirmation is required before Nu moves this wallet out of the active wallet list.")
            onAccepted: deleteWalletDialog.requestAccept()
            Keys.onReturnPressed: deleteWalletDialog.requestAccept()
            Keys.onEnterPressed: deleteWalletDialog.requestAccept()
        }

        onAccepted: NuService.deleteWallet(deleteWalletDialog.selectedWalletName)
        onClosed: deleteWalletConfirm.text = ""
    }

    NuDialog {
        id: signDialog
        title: qsTr("Sign message")
        acceptText: qsTr("Sign")
        dialogWidth: 620

        NuTextField {
            id: signAddress
            Layout.fillWidth: true
            placeholderText: qsTr("Wallet address")
        }
        TextArea {
            id: signMessage
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            placeholderText: qsTr("Message")
            color: NuTokens.textPrimary
            selectByMouse: true
            wrapMode: TextArea.Wrap
            background: Rectangle { color: NuTokens.backgroundBase; border.color: NuTokens.lineSubtle; radius: NuTokens.radiusSmall }
        }

        onAccepted: NuService.signMessage(signAddress.text, signMessage.text)
        onClosed: {
            signAddress.text = ""
            signMessage.text = ""
        }
    }

    NuDialog {
        id: verifyDialog
        title: qsTr("Verify message")
        acceptText: qsTr("Verify")
        dialogWidth: 640

        NuTextField {
            id: verifyAddress
            Layout.fillWidth: true
            placeholderText: qsTr("Address")
        }
        NuTextField {
            id: verifySignature
            Layout.fillWidth: true
            placeholderText: qsTr("Signature")
        }
        TextArea {
            id: verifyMessage
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            placeholderText: qsTr("Message")
            color: NuTokens.textPrimary
            selectByMouse: true
            wrapMode: TextArea.Wrap
            background: Rectangle { color: NuTokens.backgroundBase; border.color: NuTokens.lineSubtle; radius: NuTokens.radiusSmall }
        }

        onAccepted: NuService.verifyMessage(verifyAddress.text, verifySignature.text, verifyMessage.text)
        onClosed: {
            verifyAddress.text = ""
            verifySignature.text = ""
            verifyMessage.text = ""
        }
    }

    NuDialog {
        id: updateAvailableDialog
        title: qsTr("Update available")
        acceptText: qsTr("Download")
        cancelText: qsTr("Later")
        dialogWidth: 640
        property string version: ""

        Label {
            id: updateAvailableLabel
            Layout.fillWidth: true
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
        }

        onAccepted: {
            NuService.downloadPendingUpdate()
            updateProgressDialog.open()
        }
    }

    NuDialog {
        id: updateProgressDialog
        title: qsTr("Downloading update")
        acceptText: qsTr("Close")
        showCancel: false
        dialogWidth: 640

        Label {
            Layout.fillWidth: true
            text: NuService.updateStatus
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
        }

        Basic.ProgressBar {
            Layout.fillWidth: true
            from: 0
            to: 100
            value: NuService.updateDownloadProgress
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("The installer is verified against SHA256SUMS.txt before Nu offers to launch it.")
            color: NuTokens.textSecondary
            font.pixelSize: NuTokens.fontSmall
            wrapMode: Text.WordWrap
        }
    }

    NuDialog {
        id: updateReadyDialog
        title: qsTr("Update ready")
        acceptText: qsTr("Quit and Install")
        cancelText: qsTr("Later")
        dialogWidth: 640
        property string version: ""
        property string filePath: ""

        Label {
            id: updateReadyLabel
            Layout.fillWidth: true
            color: NuTokens.textPrimary
            font.pixelSize: NuTokens.fontBody
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
        }

        onAccepted: NuService.installDownloadedUpdate()
    }

    Dialog {
        id: aboutDialog
        title: ""
        modal: true
        standardButtons: Dialog.NoButton
        width: Math.min(root.width - 120, 780)
        height: Math.min(root.height - 96, 640)
        anchors.centerIn: parent
        padding: NuTokens.spaceLg
        background: Rectangle {
            color: NuTokens.panelBase
            border.color: NuTokens.lineStrong
            radius: NuTokens.radiusLarge
        }

        contentItem: ColumnLayout {
            spacing: NuTokens.spaceMd

            NuAboutSummary {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(405, aboutDialog.height - 200)
                showDetailsButton: false
                showOverlayText: true
                buildVersion: root.buildVersion
                buildId: root.buildId
                codeName: root.releaseCodeName
                heroHeight: Math.min(405, aboutDialog.height - 200)
                textHeight: 0
            }

            TextEdit {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(56, implicitHeight)
                readOnly: true
                selectByMouse: true
                persistentSelection: true
                wrapMode: TextEdit.WordWrap
                text: root.trademarkNotice
                color: NuTokens.textSecondary
                selectedTextColor: NuTokens.textInverse
                selectionColor: NuTokens.lineStrong
                font.pixelSize: 10
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: NuTokens.spaceMd

                NuActionButton {
                    text: root.helpEnabled ? qsTr("Details") : qsTr("Build Notes")
                    Layout.preferredWidth: 132
                    helpText: root.helpEnabled ? qsTr("Open the detailed Help window with build, feature, history, and design notes.")
                                               : qsTr("Open Nu build notes and release differences.")
                    onClicked: {
                        aboutDialog.close()
                        root.openDetailedAbout()
                    }
                }

                Item { Layout.fillWidth: true }

                NuActionButton {
                    text: qsTr("Close")
                    Layout.preferredWidth: 112
                    helpText: qsTr("Close this About summary.")
                    onClicked: aboutDialog.close()
                }
            }
        }
    }

    Window {
        id: helpWindow
        visible: false
        width: 900
        height: 700
        minimumWidth: 720
        minimumHeight: 520
        color: NuTokens.panelBase
        flags: Qt.Window

        Rectangle {
            anchors.fill: parent
            color: NuTokens.panelBase
            border.color: NuTokens.lineStrong
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: NuTokens.spaceLg
            spacing: NuTokens.spaceMd

            Basic.ScrollView {
                id: helpScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                Basic.ScrollBar.horizontal.policy: Basic.ScrollBar.AlwaysOff
                Basic.ScrollBar.vertical.policy: Basic.ScrollBar.AlwaysOn
                clip: true

                TextEdit {
                    id: helpText
                    width: Math.max(1, helpScroll.availableWidth)
                    readOnly: true
                    selectByMouse: true
                    activeFocusOnPress: true
                    persistentSelection: true
                    textFormat: TextEdit.RichText
                    wrapMode: TextEdit.WordWrap
                    font.pixelSize: NuTokens.fontBody
                    color: NuTokens.textPrimary
                    selectedTextColor: NuTokens.textInverse
                    selectionColor: NuTokens.lineStrong
                    onLinkActivated: root.openHelpLink(link)
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Item { Layout.fillWidth: true }

                NuActionButton {
                    text: qsTr("Close")
                    Layout.preferredWidth: 112
                    helpText: qsTr("Close this Help window.")
                    onClicked: helpWindow.close()
                }
            }
        }
    }

}
