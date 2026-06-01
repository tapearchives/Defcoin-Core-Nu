#!/bin/sh
set -eu

if [ "$#" -ne 4 ]; then
    echo "usage: deploy_macos_qt_runtime.sh <qt-root> <qt-plugin-root> <qt-qml-root> <app-bundle>" >&2
    exit 2
fi

qt_root="$1"
qt_plugin_root="$2"
qt_qml_root="$3"
app_bundle="$4"

contents_dir="${app_bundle}/Contents"
plugins_dir="${contents_dir}/PlugIns"
qml_dir="${contents_dir}/Resources/qml"

copy_file() {
    src="$1"
    dst="$2"
    if [ ! -e "$src" ]; then
        return 0
    fi
    /bin/mkdir -p "$(/usr/bin/dirname "$dst")"
    /bin/cp -f -L "$src" "$dst"
}

copy_dir() {
    src="$1"
    dst="$2"
    if [ ! -d "$src" ]; then
        return 0
    fi
    /bin/rm -rf "$dst"
    /bin/mkdir -p "$(/usr/bin/dirname "$dst")"
    /bin/cp -R -L "$src" "$dst"
}

copy_qml_file() {
    copy_file "${qt_qml_root}/$1" "${qml_dir}/$1"
}

copy_qml_dir() {
    copy_dir "${qt_qml_root}/$1" "${qml_dir}/$1"
}

if [ ! -d "$qt_plugin_root" ]; then
    echo "Qt plugin root not found: ${qt_plugin_root}" >&2
    exit 2
fi

if [ ! -d "$qt_qml_root" ]; then
    echo "Qt QML import root not found: ${qt_qml_root}" >&2
    exit 2
fi

/bin/rm -rf "$plugins_dir" "$qml_dir"
/bin/mkdir -p "$plugins_dir" "$qml_dir"

# Nu uses the macOS platform plugin, the Basic Qt Quick Controls style, SQLite,
# image loading, SVG icons, and TLS. Copy those runtime pieces explicitly so
# macdeployqt does not pull unrelated Qt modules such as Pdf, 3D, Timeline, or
# VirtualKeyboard into the bundle.
copy_file "${qt_plugin_root}/platforms/libqcocoa.dylib" "${plugins_dir}/platforms/libqcocoa.dylib"
copy_file "${qt_plugin_root}/styles/libqmacstyle.dylib" "${plugins_dir}/styles/libqmacstyle.dylib"
copy_file "${qt_plugin_root}/sqldrivers/libqsqlite.dylib" "${plugins_dir}/sqldrivers/libqsqlite.dylib"
copy_file "${qt_plugin_root}/tls/libqcertonlybackend.dylib" "${plugins_dir}/tls/libqcertonlybackend.dylib"
copy_file "${qt_plugin_root}/tls/libqopensslbackend.dylib" "${plugins_dir}/tls/libqopensslbackend.dylib"
copy_file "${qt_plugin_root}/tls/libqsecuretransportbackend.dylib" "${plugins_dir}/tls/libqsecuretransportbackend.dylib"
copy_file "${qt_plugin_root}/iconengines/libqsvgicon.dylib" "${plugins_dir}/iconengines/libqsvgicon.dylib"

for image_plugin in libqgif.dylib libqicns.dylib libqico.dylib libqjpeg.dylib libqsvg.dylib libqwebp.dylib; do
    copy_file "${qt_plugin_root}/imageformats/${image_plugin}" "${plugins_dir}/imageformats/${image_plugin}"
done

copy_qml_file "QtQuick/qmldir"
copy_qml_file "QtQuick/plugins.qmltypes"
copy_qml_file "QtQuick/libqtquick2plugin.dylib"
copy_qml_file "QtQuick/Controls/qmldir"
copy_qml_file "QtQuick/Controls/plugins.qmltypes"
copy_qml_file "QtQuick/Controls/libqtquickcontrols2plugin.dylib"
copy_qml_dir "QtQuick/Controls/Basic"
copy_qml_dir "QtQuick/Controls/impl"
copy_qml_dir "QtQuick/Layouts"
copy_qml_dir "QtQuick/Templates"
copy_qml_dir "QtQuick/Window"
copy_qml_file "QtQml/qmldir"
copy_qml_file "QtQml/plugins.qmltypes"
copy_qml_file "QtQml/libqmlplugin.dylib"
copy_qml_dir "QtQml/Models"
copy_qml_dir "QtQml/WorkerScript"

echo "Deployed focused Qt macOS runtime from ${qt_root}"
