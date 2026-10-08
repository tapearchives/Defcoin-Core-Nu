#!/usr/bin/env python3
"""Test actual explorer lookup method bodies with temporary SQLite state.

Requires Qt 6 Core/Sql, pkg-config and a C++17 compiler. Dependencies are stubbed
to isolate database readiness and UI refresh. No Nu launch, backend or wallet.
"""

import argparse
import os
import shlex
import subprocess
import tempfile
from pathlib import Path

PREAMBLE = r"""
#include <QCoreApplication>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QStringList>
#include <QTemporaryDir>
#include <QUuid>
#include <QVariant>
#include <cstdlib>
#include <iostream>

static int checks = 0;
static void check(bool ok, const char* name)
{
    if (!ok) { std::cerr << "FAIL: " << name << '\n'; std::exit(1); }
    ++checks;
    std::cout << "PASS: " << name << '\n';
}

class NuRpcService {
public:
    QString path;
    bool ready = true;
    int refreshes = 0;
    QStringList diagnostics;
    bool ensureExplorerDatabase(QString* error)
    {
        if (!ready) *error = QStringLiteral("test database unavailable");
        return ready;
    }
    QString explorerDatabasePath() const { return path; }
    void appendLaunchDiagnostic(const QString& error) { diagnostics.append(error); }
    void loadExplorerRecentLookups() { ++refreshes; }
    void cacheExplorerLookup(const QString&, const QString&, const QString&, const QString&, const QJsonValue&);
    QString explorerLookupHtml(const QString&, const QString&, const QJsonValue&) const;
};
"""

TESTS = r"""
int main(int argc, char** argv)
{
    QCoreApplication app(argc, argv);
    QTemporaryDir temp;
    check(temp.isValid(), "isolated temporary database");
    NuRpcService service;
    service.path = temp.filePath(QStringLiteral("lookups.sqlite"));
    QSqlDatabase probe = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QStringLiteral("test_probe"));
    probe.setDatabaseName(service.path);
    check(probe.open(), "SQLite driver");
    QSqlQuery query(probe);
    check(query.exec(QStringLiteral("CREATE TABLE explorer_lookups("
                                    "type TEXT, id TEXT, title TEXT, summary TEXT, raw_json TEXT, cached_at INTEGER,"
                                    "PRIMARY KEY(type,id))")), "lookup schema");
    const auto connections = QSqlDatabase::connectionNames();
    const QString id = QStringLiteral("quoted'; DROP TABLE explorer_lookups; --");
    const QString title = QString::fromUtf8("Address <script>& \"雪\"");
    const QJsonObject raw{{QStringLiteral("value"), title}};
    service.cacheExplorerLookup(QStringLiteral("address"), id, title, QStringLiteral("first"), raw);
    check(service.refreshes == 1, "successful write refreshes recent lookups");
    check(query.exec(QStringLiteral("SELECT id,title,raw_json,cached_at FROM explorer_lookups")) && query.next()
              && query.value(0).toString() == id && query.value(1).toString() == title
              && QJsonDocument::fromJson(query.value(2).toByteArray()).object() == raw
              && query.value(3).toLongLong() > 0 && !query.next(), "bound identifiers and Unicode JSON round trip");
    query.finish();
    service.cacheExplorerLookup(QStringLiteral("address"), id, QStringLiteral("updated"), QStringLiteral("second"), raw);
    check(query.exec(QStringLiteral("SELECT COUNT(*),MAX(title),MAX(summary) FROM explorer_lookups")) && query.next()
              && query.value(0).toInt() == 1 && query.value(1).toString() == QStringLiteral("updated")
              && query.value(2).toString() == QStringLiteral("second"), "upsert replaces the same type and id");
    query.finish();
    service.cacheExplorerLookup(QStringLiteral("transaction"), id, title, QStringLiteral("other type"), QJsonValue());
    check(query.exec(QStringLiteral("SELECT COUNT(*) FROM explorer_lookups")) && query.next()
              && query.value(0).toInt() == 2, "different lookup types remain distinct");
    query.finish();
    check(query.exec(QStringLiteral("SELECT raw_json FROM explorer_lookups WHERE type='transaction'")) && query.next()
              && query.value(0).toString() == QStringLiteral("{}"), "empty source serializes as an object");
    query.finish();
    const QString summary = QStringLiteral("<p>Trusted &amp; formatted summary</p>");
    const QString html = service.explorerLookupHtml(title, summary, raw);
    check(html.contains(QStringLiteral("<h2>") + title.toHtmlEscaped() + QStringLiteral("</h2>"))
              && html.contains(summary) && !html.contains(QStringLiteral("<script>"))
              && html.contains(QString::fromUtf8(QJsonDocument(raw).toJson(QJsonDocument::Indented)).toHtmlEscaped()),
          "title and source JSON escaped; prepared summary markup retained");
    check(QSqlDatabase::connectionNames() == connections, "successful writes remove temporary SQL connections");
    const int refreshes = service.refreshes;
    service.ready = false;
    service.cacheExplorerLookup(QStringLiteral("address"), id, title, QString(), raw);
    check(service.refreshes == refreshes && service.diagnostics.size() == 1
              && QSqlDatabase::connectionNames() == connections, "readiness failure records a diagnostic without publishing");
    service.ready = true;
    service.path = temp.filePath(QStringLiteral("missing/lookup.sqlite"));
    service.cacheExplorerLookup(QStringLiteral("address"), id, title, QString(), raw);
    check(service.refreshes == refreshes && QSqlDatabase::connectionNames() == connections,
          "database open failure does not publish or leak a connection");
    service.path = probe.databaseName();
    check(query.exec(QStringLiteral("DROP TABLE explorer_lookups")), "failed-write fixture");
    service.cacheExplorerLookup(QStringLiteral("address"), id, title, QString(), raw);
    check(service.refreshes == refreshes && QSqlDatabase::connectionNames() == connections,
          "SQL execution failure does not publish or leak a connection");
    std::cout << checks << " checks passed\n";
    return 0;
}
"""


def method(source: str, signature: str) -> str:
    """Extract one existing method through its top-level closing brace."""
    start = source.index(signature)
    end = source.index("\n}\n", start) + 2
    return source[start:end]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cxx", default=os.environ.get("CXX", "c++"))
    parser.add_argument("--pkg-config", default="pkg-config")
    args = parser.parse_args()
    source_path = Path(__file__).resolve().parent.parent / "app" / "NuRpcService.cpp"
    source = source_path.read_text(encoding="utf-8")
    bodies = [
        method(source, "void NuRpcService::cacheExplorerLookup("),
        method(source, "QString NuRpcService::explorerLookupHtml("),
    ]
    flags = shlex.split(
        subprocess.check_output(
            [args.pkg_config, "--cflags", "--libs", "Qt6Core", "Qt6Sql"], text=True
        )
    )
    with tempfile.TemporaryDirectory(prefix="nu-explorer-lookup-test-") as directory:
        generated = Path(directory) / "lookup_test.cpp"
        executable = Path(directory) / "lookup_test"
        generated.write_text(PREAMBLE + "\n".join(bodies) + TESTS, encoding="utf-8")
        subprocess.run(
            shlex.split(args.cxx) + ["-std=c++17", str(generated), "-o", str(executable)] + flags,
            check=True,
        )
        subprocess.run([str(executable)], check=True)


if __name__ == "__main__":
    main()
