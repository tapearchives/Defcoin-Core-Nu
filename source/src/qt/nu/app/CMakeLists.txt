cmake_minimum_required(VERSION 3.24)

project(DefcoinCoreNuQml VERSION 26.6.0 LANGUAGES CXX)

set(DEFCOIN_NU_RELEASE_NAME "26.6g" CACHE STRING "Visible Defcoin Core Nu release label")
option(DEFCOIN_NU_ENABLE_HELP "Bundle and expose the Defcoin Core Nu help manual" OFF)
set(DEFCOIN_NU_VELOPACK_ROOT "" CACHE PATH "Optional Velopack libc root to bundle with Defcoin Core Nu")
set(DEFCOIN_NU_VELOPACK_UPDATE_URL "https://github.com/defcoincore/Defcoin-Core-Nu/releases/latest/download" CACHE STRING "Velopack update feed URL")

if(APPLE)
    enable_language(OBJCXX)
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Network OpenGL Qml QmlMeta QmlModels QmlWorkerScript Quick QuickControls2 QuickLayouts QuickTemplates2 Sql Svg Widgets)
find_library(QRENCODE_LIBRARY qrencode REQUIRED)
find_path(QRENCODE_INCLUDE_DIR qrencode.h REQUIRED)

qt_add_executable(DefcoinCoreNu
    MACOSX_BUNDLE
    main.cpp
    NuPlatformIntegration.cpp
    NuPlatformIntegration.h
    NuRpcService.cpp
    NuRpcService.h
    NuVelopackUpdater.cpp
    NuVelopackUpdater.h
)

set(DEFCOIN_NU_ICON_MACOS "${CMAKE_CURRENT_LIST_DIR}/../assets/brand/DefcoinCoreNuNuIcon.icns")
set_source_files_properties(${DEFCOIN_NU_ICON_MACOS} PROPERTIES
    MACOSX_PACKAGE_LOCATION "Resources"
)
target_sources(DefcoinCoreNu PRIVATE ${DEFCOIN_NU_ICON_MACOS})

if(WIN32)
    target_sources(DefcoinCoreNu PRIVATE DefcoinCoreNu.rc)
endif()

if(APPLE)
    target_sources(DefcoinCoreNu PRIVATE MacHelp.h MacHelp.mm)
    find_library(COCOA_LIBRARY Cocoa REQUIRED)
    find_library(CARBON_LIBRARY Carbon REQUIRED)
endif()

if(WIN32)
    target_link_options(DefcoinCoreNu PRIVATE -mwindows)
endif()

target_link_libraries(DefcoinCoreNu
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Network
        Qt6::OpenGL
        Qt6::Qml
        Qt6::QmlMeta
        Qt6::QmlModels
        Qt6::QmlWorkerScript
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::QuickLayouts
        Qt6::QuickTemplates2
        Qt6::Sql
        Qt6::Svg
        Qt6::Widgets
        ${QRENCODE_LIBRARY}
)

if(APPLE)
    target_link_libraries(DefcoinCoreNu PRIVATE ${COCOA_LIBRARY} ${CARBON_LIBRARY})
endif()

target_include_directories(DefcoinCoreNu PRIVATE ${QRENCODE_INCLUDE_DIR})

set_target_properties(DefcoinCoreNu PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER org.defcoincore.DefcoinCoreNu
    MACOSX_BUNDLE_BUNDLE_NAME "Defcoin Core Nu"
    MACOSX_BUNDLE_DISPLAY_NAME "Defcoin Core Nu"
    MACOSX_BUNDLE_ICON_FILE "DefcoinCoreNuNuIcon"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "${DEFCOIN_NU_RELEASE_NAME}"
    MACOSX_BUNDLE_BUNDLE_VERSION "${DEFCOIN_NU_RELEASE_NAME}"
)

if(DEFCOIN_NU_ENABLE_HELP)
    set(DEFCOIN_NU_HELP_ENABLED_VALUE 1)
else()
    set(DEFCOIN_NU_HELP_ENABLED_VALUE 0)
endif()

target_compile_definitions(DefcoinCoreNu PRIVATE
    DEFCOIN_NU_VERSION="${DEFCOIN_NU_RELEASE_NAME}"
    DEFCOIN_NU_HELP_ENABLED=${DEFCOIN_NU_HELP_ENABLED_VALUE}
    DEFCOIN_NU_VELOPACK_UPDATE_URL="${DEFCOIN_NU_VELOPACK_UPDATE_URL}"
    DEFCOIN_NU_EXPFOR_APP=0
)

qt_add_executable(DefcoinCoreExpFor
    MACOSX_BUNDLE
    main.cpp
    NuPlatformIntegration.cpp
    NuPlatformIntegration.h
    NuRpcService.cpp
    NuRpcService.h
    NuVelopackUpdater.cpp
    NuVelopackUpdater.h
)

target_sources(DefcoinCoreExpFor PRIVATE ${DEFCOIN_NU_ICON_MACOS})

if(WIN32)
    target_sources(DefcoinCoreExpFor PRIVATE DefcoinCoreNu.rc)
    target_link_options(DefcoinCoreExpFor PRIVATE -mwindows)
endif()

if(APPLE)
    target_sources(DefcoinCoreExpFor PRIVATE MacHelp.h MacHelp.mm)
    target_link_libraries(DefcoinCoreExpFor PRIVATE ${COCOA_LIBRARY} ${CARBON_LIBRARY})
endif()

target_link_libraries(DefcoinCoreExpFor
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Network
        Qt6::OpenGL
        Qt6::Qml
        Qt6::QmlMeta
        Qt6::QmlModels
        Qt6::QmlWorkerScript
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::QuickLayouts
        Qt6::QuickTemplates2
        Qt6::Sql
        Qt6::Svg
        Qt6::Widgets
        ${QRENCODE_LIBRARY}
)

target_include_directories(DefcoinCoreExpFor PRIVATE ${QRENCODE_INCLUDE_DIR})

set_target_properties(DefcoinCoreExpFor PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER org.defcoincore.DefcoinCoreExpFor
    MACOSX_BUNDLE_BUNDLE_NAME "Defcoin Core ExpFor"
    MACOSX_BUNDLE_DISPLAY_NAME "Defcoin Core ExpFor"
    MACOSX_BUNDLE_ICON_FILE "DefcoinCoreNuNuIcon"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "${DEFCOIN_NU_RELEASE_NAME}"
    MACOSX_BUNDLE_BUNDLE_VERSION "${DEFCOIN_NU_RELEASE_NAME}"
)

target_compile_definitions(DefcoinCoreExpFor PRIVATE
    DEFCOIN_NU_VERSION="${DEFCOIN_NU_RELEASE_NAME}"
    DEFCOIN_NU_HELP_ENABLED=${DEFCOIN_NU_HELP_ENABLED_VALUE}
    DEFCOIN_NU_VELOPACK_UPDATE_URL="${DEFCOIN_NU_VELOPACK_UPDATE_URL}"
    DEFCOIN_NU_EXPFOR_APP=1
)

file(GLOB_RECURSE DEFCOIN_NU_QML_FILES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_LIST_DIR}/../qml/*.qml"
    "${CMAKE_CURRENT_LIST_DIR}/../qml/qmldir"
)

set(DEFCOIN_NU_RUNTIME_ASSET_FILES
    "${CMAKE_CURRENT_LIST_DIR}/../assets/brand/DefcoinCoreNu.ico"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/bip39/english.txt"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/brand/defcoin-nu-coin-stack-hires.png"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/brand/defcoin-nu-icon-1024.png"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/activity.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/copy.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/external-link.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/explorer.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/forensics.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/home.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/isolated.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/lock.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/mining.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/network.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/node.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/qr.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/receive.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/send.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/settings.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/sync.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/wallet.svg"
    "${CMAKE_CURRENT_LIST_DIR}/../assets/icons/warning.svg"
)

file(GLOB_RECURSE DEFCOIN_NU_HELP_FILES CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_LIST_DIR}/../help/*"
)

if(WIN32)
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/qt.conf"
"[Paths]
Prefix=.
Plugins=plugins
Qml2Imports=qml
")
endif()

set(DEFCOIN_NU_BACKEND_BINARY "" CACHE FILEPATH "Optional defcoind binary to bundle with Defcoin Core Nu")
set(DEFCOIN_NU_CLI_BINARY "" CACHE FILEPATH "Optional defcoin-cli binary to bundle with Defcoin Core Nu")
set(DEFCOIN_NU_TX_BINARY "" CACHE FILEPATH "Optional defcoin-tx binary to bundle with Defcoin Core Nu")
set(DEFCOIN_NU_WALLET_BINARY "" CACHE FILEPATH "Optional defcoin-wallet binary to bundle with Defcoin Core Nu")

if(APPLE)
    set(DEFCOIN_NU_RESOURCE_DIR "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Resources/nu")
    set(DEFCOIN_NU_HELP_DIR "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Resources/DefcoinCoreNu.help")
else()
    set(DEFCOIN_NU_RESOURCE_DIR "$<TARGET_FILE_DIR:DefcoinCoreNu>/nu")
    set(DEFCOIN_NU_HELP_DIR "${DEFCOIN_NU_RESOURCE_DIR}/help/DefcoinCoreNu.help")
endif()

set(DEFCOIN_NU_ASSET_COPY_COMMANDS)
foreach(nu_asset IN LISTS DEFCOIN_NU_RUNTIME_ASSET_FILES)
    file(RELATIVE_PATH nu_asset_rel "${CMAKE_CURRENT_LIST_DIR}/../assets" "${nu_asset}")
    get_filename_component(nu_asset_rel_dir "${nu_asset_rel}" DIRECTORY)
    list(APPEND DEFCOIN_NU_ASSET_COPY_COMMANDS
        COMMAND ${CMAKE_COMMAND} -E make_directory "${DEFCOIN_NU_RESOURCE_DIR}/assets/${nu_asset_rel_dir}"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${nu_asset}" "${DEFCOIN_NU_RESOURCE_DIR}/assets/${nu_asset_rel}"
    )
endforeach()

add_custom_target(DefcoinCoreNuResources ALL
    DEPENDS ${DEFCOIN_NU_QML_FILES} ${DEFCOIN_NU_RUNTIME_ASSET_FILES}
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${DEFCOIN_NU_RESOURCE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${DEFCOIN_NU_RESOURCE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_LIST_DIR}/../qml" "${DEFCOIN_NU_RESOURCE_DIR}/qml"
    ${DEFCOIN_NU_ASSET_COPY_COMMANDS}
)

add_dependencies(DefcoinCoreNuResources DefcoinCoreNu)

if(APPLE)
    add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
        COMMAND /bin/chmod u+w "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Info.plist"
        COMMAND ${CMAKE_COMMAND}
            "-DDEFCOIN_NU_RESOURCE_DIR=${DEFCOIN_NU_RESOURCE_DIR}"
            "-DDEFCOIN_NU_RELEASE_NAME=${DEFCOIN_NU_RELEASE_NAME}"
            "-DDEFCOIN_NU_SOURCE_DIR=${CMAKE_CURRENT_LIST_DIR}"
            "-DDEFCOIN_NU_PLIST_PATH=$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Info.plist"
            -P "${CMAKE_CURRENT_LIST_DIR}/write_nu_build_metadata.cmake"
        COMMENT "Writing Defcoin Core Nu build metadata"
    )
else()
    add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
        COMMAND ${CMAKE_COMMAND}
            "-DDEFCOIN_NU_RESOURCE_DIR=${DEFCOIN_NU_RESOURCE_DIR}"
            "-DDEFCOIN_NU_RELEASE_NAME=${DEFCOIN_NU_RELEASE_NAME}"
            "-DDEFCOIN_NU_SOURCE_DIR=${CMAKE_CURRENT_LIST_DIR}"
            -P "${CMAKE_CURRENT_LIST_DIR}/write_nu_build_metadata.cmake"
        COMMENT "Writing Defcoin Core Nu build metadata"
    )
endif()

if(DEFCOIN_NU_ENABLE_HELP)
    add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E rm -rf "${DEFCOIN_NU_HELP_DIR}"
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_LIST_DIR}/../help/DefcoinCoreNu.help" "${DEFCOIN_NU_HELP_DIR}"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_LIST_DIR}/../help/DefcoinCoreNu.hhp" "${DEFCOIN_NU_RESOURCE_DIR}/help/DefcoinCoreNu.hhp"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_LIST_DIR}/../help/DefcoinCoreNu.hhc" "${DEFCOIN_NU_RESOURCE_DIR}/help/DefcoinCoreNu.hhc"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_LIST_DIR}/../help/DefcoinCoreNu.hhk" "${DEFCOIN_NU_RESOURCE_DIR}/help/DefcoinCoreNu.hhk"
        COMMENT "Bundling Defcoin Core Nu help"
    )
else()
    add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E rm -rf "${DEFCOIN_NU_HELP_DIR}"
        COMMAND ${CMAKE_COMMAND} -E rm -rf "${DEFCOIN_NU_RESOURCE_DIR}/help"
        COMMENT "Omitting optional Defcoin Core Nu help resources"
    )
endif()

if(APPLE)
    set(DEFCOIN_NU_EXPFOR_RESOURCE_DIR "$<TARGET_BUNDLE_DIR:DefcoinCoreExpFor>/Contents/Resources/nu")
    set(DEFCOIN_NU_EXPFOR_HELP_DIR "$<TARGET_BUNDLE_DIR:DefcoinCoreExpFor>/Contents/Resources/DefcoinCoreNu.help")
else()
    set(DEFCOIN_NU_EXPFOR_RESOURCE_DIR "$<TARGET_FILE_DIR:DefcoinCoreExpFor>/nu")
    set(DEFCOIN_NU_EXPFOR_HELP_DIR "${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}/help/DefcoinCoreNu.help")
endif()

set(DEFCOIN_NU_EXPFOR_ASSET_COPY_COMMANDS)
foreach(nu_asset IN LISTS DEFCOIN_NU_RUNTIME_ASSET_FILES)
    file(RELATIVE_PATH nu_asset_rel "${CMAKE_CURRENT_LIST_DIR}/../assets" "${nu_asset}")
    get_filename_component(nu_asset_rel_dir "${nu_asset_rel}" DIRECTORY)
    list(APPEND DEFCOIN_NU_EXPFOR_ASSET_COPY_COMMANDS
        COMMAND ${CMAKE_COMMAND} -E make_directory "${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}/assets/${nu_asset_rel_dir}"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${nu_asset}" "${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}/assets/${nu_asset_rel}"
    )
endforeach()

add_custom_target(DefcoinCoreExpForResources ALL
    DEPENDS ${DEFCOIN_NU_QML_FILES} ${DEFCOIN_NU_RUNTIME_ASSET_FILES}
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${CMAKE_CURRENT_LIST_DIR}/../qml" "${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}/qml"
    ${DEFCOIN_NU_EXPFOR_ASSET_COPY_COMMANDS}
)

add_dependencies(DefcoinCoreExpForResources DefcoinCoreExpFor)

if(APPLE)
    add_custom_command(TARGET DefcoinCoreExpForResources POST_BUILD
        COMMAND /bin/chmod u+w "$<TARGET_BUNDLE_DIR:DefcoinCoreExpFor>/Contents/Info.plist"
        COMMAND ${CMAKE_COMMAND}
            "-DDEFCOIN_NU_RESOURCE_DIR=${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}"
            "-DDEFCOIN_NU_RELEASE_NAME=${DEFCOIN_NU_RELEASE_NAME}"
            "-DDEFCOIN_NU_SOURCE_DIR=${CMAKE_CURRENT_LIST_DIR}"
            "-DDEFCOIN_NU_PLIST_PATH=$<TARGET_BUNDLE_DIR:DefcoinCoreExpFor>/Contents/Info.plist"
            -P "${CMAKE_CURRENT_LIST_DIR}/write_nu_build_metadata.cmake"
        COMMAND /bin/sh "${CMAKE_CURRENT_LIST_DIR}/set_macos_launch_plist.sh" "$<TARGET_BUNDLE_DIR:DefcoinCoreExpFor>/Contents/Info.plist"
        COMMAND /bin/sh "${CMAKE_CURRENT_LIST_DIR}/remove_macos_help_plist.sh" "$<TARGET_BUNDLE_DIR:DefcoinCoreExpFor>/Contents/Info.plist"
        COMMAND /usr/bin/touch -ch "$<TARGET_BUNDLE_DIR:DefcoinCoreExpFor>"
        COMMENT "Writing Defcoin Core ExpFor resources and build metadata"
    )
else()
    add_custom_command(TARGET DefcoinCoreExpForResources POST_BUILD
        COMMAND ${CMAKE_COMMAND}
            "-DDEFCOIN_NU_RESOURCE_DIR=${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}"
            "-DDEFCOIN_NU_RELEASE_NAME=${DEFCOIN_NU_RELEASE_NAME}"
            "-DDEFCOIN_NU_SOURCE_DIR=${CMAKE_CURRENT_LIST_DIR}"
            -P "${CMAKE_CURRENT_LIST_DIR}/write_nu_build_metadata.cmake"
        COMMENT "Writing Defcoin Core ExpFor build metadata"
    )
endif()

add_custom_command(TARGET DefcoinCoreExpForResources POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${DEFCOIN_NU_EXPFOR_HELP_DIR}"
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}/help"
    COMMENT "Omitting optional Defcoin Core ExpFor help resources"
)

if(APPLE)
    add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
        COMMAND /bin/sh "${CMAKE_CURRENT_LIST_DIR}/set_macos_launch_plist.sh" "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Info.plist"
        COMMENT "Disabling macOS saved no-window restoration for Defcoin Core Nu"
    )

    if(Qt6Core_DIR)
        if(Qt6_DIR)
            get_filename_component(DEFCOIN_NU_QT_ROOT "${Qt6_DIR}/../../.." ABSOLUTE)
        else()
            get_filename_component(DEFCOIN_NU_QT_ROOT "${Qt6Core_DIR}/../../.." ABSOLUTE)
        endif()
        set(DEFCOIN_NU_QT_PLUGIN_ROOT "")
        foreach(candidate_plugin_root
            "${DEFCOIN_NU_QT_ROOT}/plugins"
            "${DEFCOIN_NU_QT_ROOT}/share/qt/plugins"
            "/opt/homebrew/share/qt/plugins"
            "/usr/local/share/qt/plugins"
        )
            if(NOT DEFCOIN_NU_QT_PLUGIN_ROOT AND EXISTS "${candidate_plugin_root}")
                set(DEFCOIN_NU_QT_PLUGIN_ROOT "${candidate_plugin_root}")
            endif()
        endforeach()
        set(DEFCOIN_NU_QT_QML_ROOT "")
        foreach(candidate_qml_root
            "${DEFCOIN_NU_QT_ROOT}/qml"
            "${DEFCOIN_NU_QT_ROOT}/share/qt/qml"
            "/opt/homebrew/share/qt/qml"
            "/usr/local/share/qt/qml"
        )
            if(NOT DEFCOIN_NU_QT_QML_ROOT AND EXISTS "${candidate_qml_root}/QtQuick/qmldir")
                set(DEFCOIN_NU_QT_QML_ROOT "${candidate_qml_root}")
            endif()
        endforeach()
        if(NOT DEFCOIN_NU_QT_PLUGIN_ROOT)
            message(FATAL_ERROR "Unable to locate Qt plugin root for focused macOS deployment")
        endif()
        if(NOT DEFCOIN_NU_QT_QML_ROOT)
            message(FATAL_ERROR "Unable to locate Qt QML import root for focused macOS deployment")
        endif()
        set(DEFCOIN_NU_MACDEPLOYQT "${DEFCOIN_NU_QT_ROOT}/bin/macdeployqt")
        if(EXISTS "${DEFCOIN_NU_MACDEPLOYQT}")
            execute_process(
                COMMAND "${DEFCOIN_NU_MACDEPLOYQT}" -h
                OUTPUT_VARIABLE DEFCOIN_NU_MACDEPLOYQT_HELP
                ERROR_VARIABLE DEFCOIN_NU_MACDEPLOYQT_HELP
                OUTPUT_STRIP_TRAILING_WHITESPACE
                ERROR_STRIP_TRAILING_WHITESPACE
            )
            set(DEFCOIN_NU_MACDEPLOYQT_CODESIGN_FLAGS "")
            if(DEFCOIN_NU_MACDEPLOYQT_HELP MATCHES "-no-codesign")
                list(APPEND DEFCOIN_NU_MACDEPLOYQT_CODESIGN_FLAGS -no-codesign)
            endif()
            add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E rm -rf "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Frameworks"
                COMMAND ${CMAKE_COMMAND} -E rm -rf "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/PlugIns"
                COMMAND ${CMAKE_COMMAND} -E rm -rf "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Resources/qml"
                COMMAND "${DEFCOIN_NU_MACDEPLOYQT}" "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>"
                    -no-plugins
                    "-libpath=${DEFCOIN_NU_QT_ROOT}/lib"
                    -always-overwrite
                    -appstore-compliant
                    ${DEFCOIN_NU_MACDEPLOYQT_CODESIGN_FLAGS}
                COMMAND /bin/sh "${CMAKE_CURRENT_LIST_DIR}/deploy_macos_qt_runtime.sh" "${DEFCOIN_NU_QT_ROOT}" "${DEFCOIN_NU_QT_PLUGIN_ROOT}" "${DEFCOIN_NU_QT_QML_ROOT}" "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>"
                COMMAND /bin/sh "${CMAKE_CURRENT_LIST_DIR}/fix_macos_qt_rpath.sh" "${DEFCOIN_NU_QT_ROOT}" "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/MacOS/DefcoinCoreNu"
                COMMAND "${Python3_EXECUTABLE}" "${CMAKE_CURRENT_LIST_DIR}/repair_macos_qt_bundle.py" "${DEFCOIN_NU_QT_ROOT}" "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>"
                COMMAND ${CMAKE_COMMAND} -E rm -f "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/PlugIns/sqldrivers/libqsqlmimer.dylib"
                COMMENT "Deploying focused Qt frameworks, plugins, and QML imports"
            )
        else()
            message(WARNING "macdeployqt not found at ${DEFCOIN_NU_MACDEPLOYQT}; macOS app bundle will not be self-contained")
        endif()
    endif()

    if(DEFCOIN_NU_ENABLE_HELP)
        add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
            COMMAND /bin/sh "${CMAKE_CURRENT_LIST_DIR}/set_macos_help_plist.sh" "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Info.plist"
            COMMAND /usr/bin/hiutil -Cf "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Resources/DefcoinCoreNu.help/Contents/Resources/en.lproj/search.helpindex" "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Resources/DefcoinCoreNu.help/Contents/Resources/en.lproj"
            COMMAND /usr/bin/touch -ch "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>"
            COMMENT "Refreshing Defcoin Core Nu app bundle modified timestamp"
        )
    else()
        add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
            COMMAND /bin/sh "${CMAKE_CURRENT_LIST_DIR}/remove_macos_help_plist.sh" "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Info.plist"
            COMMAND /usr/bin/touch -ch "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>"
            COMMENT "Removing Defcoin Core Nu help metadata for this release"
        )
    endif()
endif()

if(WIN32)
    set(DEFCOIN_NU_QT_RUNTIME_TARGETS
        Qt6::Core
        Qt6::Gui
        Qt6::Network
        Qt6::OpenGL
        Qt6::Qml
        Qt6::QmlMeta
        Qt6::QmlModels
        Qt6::QmlWorkerScript
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::QuickLayouts
        Qt6::QuickTemplates2
        Qt6::Sql
        Qt6::Svg
        Qt6::Widgets
    )
    foreach(qt_runtime_target IN LISTS DEFCOIN_NU_QT_RUNTIME_TARGETS)
        add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:${qt_runtime_target}>" "$<TARGET_FILE_DIR:DefcoinCoreNu>"
        )
    endforeach()
    if(Qt6Core_DIR)
        get_filename_component(DEFCOIN_NU_QT_RUNTIME_ROOT "${Qt6Core_DIR}/../../.." ABSOLUTE)
        foreach(qt_runtime_dll IN ITEMS
            Qt6QuickControls2Basic.dll
            Qt6QuickControls2BasicStyleImpl.dll
            Qt6QuickControls2FluentWinUI3StyleImpl.dll
            Qt6QuickControls2Fusion.dll
            Qt6QuickControls2FusionStyleImpl.dll
            Qt6QuickControls2Imagine.dll
            Qt6QuickControls2ImagineStyleImpl.dll
            Qt6QuickControls2Impl.dll
            Qt6QuickControls2Material.dll
            Qt6QuickControls2MaterialStyleImpl.dll
            Qt6QuickControls2Universal.dll
            Qt6QuickControls2UniversalStyleImpl.dll
            Qt6QuickControls2WindowsStyleImpl.dll
        )
            if(EXISTS "${DEFCOIN_NU_QT_RUNTIME_ROOT}/bin/${qt_runtime_dll}")
                add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_QT_RUNTIME_ROOT}/bin/${qt_runtime_dll}" "$<TARGET_FILE_DIR:DefcoinCoreNu>"
                )
            endif()
        endforeach()
    endif()

    get_filename_component(DEFCOIN_NU_MINGW_BIN_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
    foreach(mingw_runtime IN ITEMS libgcc_s_seh-1.dll libstdc++-6.dll libwinpthread-1.dll)
        if(EXISTS "${DEFCOIN_NU_MINGW_BIN_DIR}/${mingw_runtime}")
            add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_MINGW_BIN_DIR}/${mingw_runtime}" "$<TARGET_FILE_DIR:DefcoinCoreNu>"
            )
        endif()
    endforeach()
    if(CMAKE_CXX_COMPILER)
        execute_process(COMMAND "${CMAKE_CXX_COMPILER}" -print-file-name=libgcc_s_seh-1.dll
            OUTPUT_VARIABLE DEFCOIN_NU_MINGW_LIBGCC OUTPUT_STRIP_TRAILING_WHITESPACE)
        execute_process(COMMAND "${CMAKE_CXX_COMPILER}" -print-file-name=libstdc++-6.dll
            OUTPUT_VARIABLE DEFCOIN_NU_MINGW_LIBSTDCPP OUTPUT_STRIP_TRAILING_WHITESPACE)
        foreach(mingw_runtime_file IN ITEMS "${DEFCOIN_NU_MINGW_LIBGCC}" "${DEFCOIN_NU_MINGW_LIBSTDCPP}")
            if(EXISTS "${mingw_runtime_file}")
                add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${mingw_runtime_file}" "$<TARGET_FILE_DIR:DefcoinCoreNu>"
                )
            endif()
        endforeach()
        if(EXISTS "${DEFCOIN_NU_MINGW_LIBSTDCPP}")
            get_filename_component(DEFCOIN_NU_MINGW_TRIPLET_LIB "${DEFCOIN_NU_MINGW_LIBSTDCPP}" DIRECTORY)
            get_filename_component(DEFCOIN_NU_MINGW_TRIPLET_ROOT "${DEFCOIN_NU_MINGW_TRIPLET_LIB}" DIRECTORY)
            set(DEFCOIN_NU_MINGW_PTHREAD_DLL "${DEFCOIN_NU_MINGW_TRIPLET_ROOT}/bin/libwinpthread-1.dll")
            if(EXISTS "${DEFCOIN_NU_MINGW_PTHREAD_DLL}")
                add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_MINGW_PTHREAD_DLL}" "$<TARGET_FILE_DIR:DefcoinCoreNu>"
                )
            endif()
        endif()
    endif()

    if(Qt6Core_DIR)
        get_filename_component(DEFCOIN_NU_QT_ROOT "${Qt6Core_DIR}/../../.." ABSOLUTE)
        set(DEFCOIN_NU_QT_PLUGINS_DIR "${DEFCOIN_NU_QT_ROOT}/plugins")
        set(DEFCOIN_NU_QT_QML_DIR "${DEFCOIN_NU_QT_ROOT}/qml")
        set(DEFCOIN_NU_QT_TRANSLATIONS_DIR "${DEFCOIN_NU_QT_ROOT}/translations")

        foreach(plugin_dir IN ITEMS platforms styles imageformats iconengines networkinformation sqldrivers tls)
            if(EXISTS "${DEFCOIN_NU_QT_PLUGINS_DIR}/${plugin_dir}")
                add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E rm -rf "$<TARGET_FILE_DIR:DefcoinCoreNu>/plugins/${plugin_dir}"
                    COMMAND ${CMAKE_COMMAND} -E copy_directory
                        "${DEFCOIN_NU_QT_PLUGINS_DIR}/${plugin_dir}"
                        "$<TARGET_FILE_DIR:DefcoinCoreNu>/plugins/${plugin_dir}"
                )
            endif()
        endforeach()

        if(EXISTS "${DEFCOIN_NU_QT_QML_DIR}")
            add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E rm -rf "$<TARGET_FILE_DIR:DefcoinCoreNu>/qml"
                COMMAND ${CMAKE_COMMAND} -E copy_directory
                    "${DEFCOIN_NU_QT_QML_DIR}"
                    "$<TARGET_FILE_DIR:DefcoinCoreNu>/qml"
            )
        endif()

        if(EXISTS "${DEFCOIN_NU_QT_TRANSLATIONS_DIR}")
            add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E rm -rf "$<TARGET_FILE_DIR:DefcoinCoreNu>/translations"
                COMMAND ${CMAKE_COMMAND} -E copy_directory
                    "${DEFCOIN_NU_QT_TRANSLATIONS_DIR}"
                    "$<TARGET_FILE_DIR:DefcoinCoreNu>/translations"
            )
        endif()
    endif()

    add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_BINARY_DIR}/qt.conf" "$<TARGET_FILE_DIR:DefcoinCoreNu>/qt.conf"
        COMMENT "Deploying Qt runtime files for Defcoin Core Nu on Windows"
    )
endif()

if(DEFCOIN_NU_VELOPACK_ROOT)
    if(APPLE)
        set(DEFCOIN_NU_VELOPACK_RUNTIME "${DEFCOIN_NU_VELOPACK_ROOT}/lib/velopack_libc_osx.dylib")
        set(DEFCOIN_NU_VELOPACK_RUNTIME_DEST "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Frameworks/velopack_libc_osx.dylib")
        if(EXISTS "${DEFCOIN_NU_VELOPACK_RUNTIME}")
            add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Frameworks"
                COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_VELOPACK_RUNTIME}" "${DEFCOIN_NU_VELOPACK_RUNTIME_DEST}"
                COMMENT "Bundling Velopack runtime for Defcoin Core Nu"
            )
        else()
            message(WARNING "DEFCOIN_NU_VELOPACK_ROOT was set, but ${DEFCOIN_NU_VELOPACK_RUNTIME} was not found")
        endif()
    elseif(WIN32)
        set(DEFCOIN_NU_VELOPACK_RUNTIME "${DEFCOIN_NU_VELOPACK_ROOT}/lib/velopack_libc_win_x64_msvc.dll")
        if(EXISTS "${DEFCOIN_NU_VELOPACK_RUNTIME}")
            add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_VELOPACK_RUNTIME}" "$<TARGET_FILE_DIR:DefcoinCoreNu>"
                COMMENT "Bundling Velopack runtime for Defcoin Core Nu"
            )
        else()
            message(WARNING "DEFCOIN_NU_VELOPACK_ROOT was set, but ${DEFCOIN_NU_VELOPACK_RUNTIME} was not found")
        endif()
    elseif(UNIX)
        if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
            set(DEFCOIN_NU_VELOPACK_RUNTIME "${DEFCOIN_NU_VELOPACK_ROOT}/lib/velopack_libc_linux_arm64_gnu.so")
        else()
            set(DEFCOIN_NU_VELOPACK_RUNTIME "${DEFCOIN_NU_VELOPACK_ROOT}/lib/velopack_libc_linux_x64_gnu.so")
        endif()
        if(EXISTS "${DEFCOIN_NU_VELOPACK_RUNTIME}")
            add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_VELOPACK_RUNTIME}" "$<TARGET_FILE_DIR:DefcoinCoreNu>"
                COMMENT "Bundling Velopack runtime for Defcoin Core Nu"
            )
        else()
            message(WARNING "DEFCOIN_NU_VELOPACK_ROOT was set, but ${DEFCOIN_NU_VELOPACK_RUNTIME} was not found")
        endif()
    endif()
endif()

if(DEFCOIN_NU_BACKEND_BINARY)
    get_filename_component(DEFCOIN_NU_BACKEND_INPUT_DIR "${DEFCOIN_NU_BACKEND_BINARY}" DIRECTORY)
    if(NOT DEFCOIN_NU_CLI_BINARY)
        if(WIN32)
            set(DEFCOIN_NU_CLI_CANDIDATE "${DEFCOIN_NU_BACKEND_INPUT_DIR}/defcoin-cli.exe")
        else()
            set(DEFCOIN_NU_CLI_CANDIDATE "${DEFCOIN_NU_BACKEND_INPUT_DIR}/defcoin-cli")
        endif()
        if(EXISTS "${DEFCOIN_NU_CLI_CANDIDATE}")
            set(DEFCOIN_NU_CLI_BINARY "${DEFCOIN_NU_CLI_CANDIDATE}")
        endif()
    endif()
    if(NOT DEFCOIN_NU_TX_BINARY)
        if(WIN32)
            set(DEFCOIN_NU_TX_CANDIDATE "${DEFCOIN_NU_BACKEND_INPUT_DIR}/defcoin-tx.exe")
        else()
            set(DEFCOIN_NU_TX_CANDIDATE "${DEFCOIN_NU_BACKEND_INPUT_DIR}/defcoin-tx")
        endif()
        if(EXISTS "${DEFCOIN_NU_TX_CANDIDATE}")
            set(DEFCOIN_NU_TX_BINARY "${DEFCOIN_NU_TX_CANDIDATE}")
        endif()
    endif()
    if(NOT DEFCOIN_NU_WALLET_BINARY)
        if(WIN32)
            set(DEFCOIN_NU_WALLET_CANDIDATE "${DEFCOIN_NU_BACKEND_INPUT_DIR}/defcoin-wallet.exe")
        else()
            set(DEFCOIN_NU_WALLET_CANDIDATE "${DEFCOIN_NU_BACKEND_INPUT_DIR}/defcoin-wallet")
        endif()
        if(EXISTS "${DEFCOIN_NU_WALLET_CANDIDATE}")
            set(DEFCOIN_NU_WALLET_BINARY "${DEFCOIN_NU_WALLET_CANDIDATE}")
        endif()
    endif()
    if(APPLE)
        set(DEFCOIN_NU_BACKEND_OUTPUT "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Resources/nu/bin/defcoind")
        set(DEFCOIN_NU_CLI_OUTPUT "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Resources/nu/bin/defcoin-cli")
        set(DEFCOIN_NU_TX_OUTPUT "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Resources/nu/bin/defcoin-tx")
        set(DEFCOIN_NU_WALLET_OUTPUT "$<TARGET_BUNDLE_DIR:DefcoinCoreNu>/Contents/Resources/nu/bin/defcoin-wallet")
    elseif(WIN32)
        set(DEFCOIN_NU_BACKEND_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreNu>/nu/bin/defcoind.exe")
        set(DEFCOIN_NU_CLI_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreNu>/nu/bin/defcoin-cli.exe")
        set(DEFCOIN_NU_TX_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreNu>/nu/bin/defcoin-tx.exe")
        set(DEFCOIN_NU_WALLET_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreNu>/nu/bin/defcoin-wallet.exe")
    else()
        set(DEFCOIN_NU_BACKEND_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreNu>/nu/bin/defcoind")
        set(DEFCOIN_NU_CLI_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreNu>/nu/bin/defcoin-cli")
        set(DEFCOIN_NU_TX_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreNu>/nu/bin/defcoin-tx")
        set(DEFCOIN_NU_WALLET_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreNu>/nu/bin/defcoin-wallet")
    endif()
    add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${DEFCOIN_NU_RESOURCE_DIR}/bin"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_BACKEND_BINARY}" "${DEFCOIN_NU_BACKEND_OUTPUT}"
        COMMAND /bin/chmod 755 "${DEFCOIN_NU_BACKEND_OUTPUT}"
        COMMENT "Bundling Defcoin backend for Nu"
    )
    if(DEFCOIN_NU_CLI_BINARY)
        add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${DEFCOIN_NU_RESOURCE_DIR}/bin"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_CLI_BINARY}" "${DEFCOIN_NU_CLI_OUTPUT}"
            COMMAND /bin/chmod 755 "${DEFCOIN_NU_CLI_OUTPUT}"
            COMMENT "Bundling Defcoin CLI for Nu"
        )
    endif()
    if(DEFCOIN_NU_TX_BINARY)
        add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${DEFCOIN_NU_RESOURCE_DIR}/bin"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_TX_BINARY}" "${DEFCOIN_NU_TX_OUTPUT}"
            COMMAND /bin/chmod 755 "${DEFCOIN_NU_TX_OUTPUT}"
            COMMENT "Bundling Defcoin transaction utility for Nu"
        )
    endif()
    if(DEFCOIN_NU_WALLET_BINARY)
        add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${DEFCOIN_NU_RESOURCE_DIR}/bin"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_WALLET_BINARY}" "${DEFCOIN_NU_WALLET_OUTPUT}"
            COMMAND /bin/chmod 755 "${DEFCOIN_NU_WALLET_OUTPUT}"
            COMMENT "Bundling Defcoin wallet utility for Nu"
        )
    endif()
    if(APPLE)
        set(DEFCOIN_NU_EXPFOR_BACKEND_OUTPUT "$<TARGET_BUNDLE_DIR:DefcoinCoreExpFor>/Contents/Resources/nu/bin/defcoind")
        set(DEFCOIN_NU_EXPFOR_CLI_OUTPUT "$<TARGET_BUNDLE_DIR:DefcoinCoreExpFor>/Contents/Resources/nu/bin/defcoin-cli")
        set(DEFCOIN_NU_EXPFOR_TX_OUTPUT "$<TARGET_BUNDLE_DIR:DefcoinCoreExpFor>/Contents/Resources/nu/bin/defcoin-tx")
        set(DEFCOIN_NU_EXPFOR_WALLET_OUTPUT "$<TARGET_BUNDLE_DIR:DefcoinCoreExpFor>/Contents/Resources/nu/bin/defcoin-wallet")
    elseif(WIN32)
        set(DEFCOIN_NU_EXPFOR_BACKEND_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreExpFor>/nu/bin/defcoind.exe")
        set(DEFCOIN_NU_EXPFOR_CLI_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreExpFor>/nu/bin/defcoin-cli.exe")
        set(DEFCOIN_NU_EXPFOR_TX_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreExpFor>/nu/bin/defcoin-tx.exe")
        set(DEFCOIN_NU_EXPFOR_WALLET_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreExpFor>/nu/bin/defcoin-wallet.exe")
    else()
        set(DEFCOIN_NU_EXPFOR_BACKEND_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreExpFor>/nu/bin/defcoind")
        set(DEFCOIN_NU_EXPFOR_CLI_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreExpFor>/nu/bin/defcoin-cli")
        set(DEFCOIN_NU_EXPFOR_TX_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreExpFor>/nu/bin/defcoin-tx")
        set(DEFCOIN_NU_EXPFOR_WALLET_OUTPUT "$<TARGET_FILE_DIR:DefcoinCoreExpFor>/nu/bin/defcoin-wallet")
    endif()
    add_custom_command(TARGET DefcoinCoreExpForResources POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}/bin"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_BACKEND_BINARY}" "${DEFCOIN_NU_EXPFOR_BACKEND_OUTPUT}"
        COMMAND /bin/chmod 755 "${DEFCOIN_NU_EXPFOR_BACKEND_OUTPUT}"
        COMMENT "Bundling Defcoin backend for ExpFor"
    )
    if(DEFCOIN_NU_CLI_BINARY)
        add_custom_command(TARGET DefcoinCoreExpForResources POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}/bin"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_CLI_BINARY}" "${DEFCOIN_NU_EXPFOR_CLI_OUTPUT}"
            COMMAND /bin/chmod 755 "${DEFCOIN_NU_EXPFOR_CLI_OUTPUT}"
            COMMENT "Bundling Defcoin CLI for ExpFor"
        )
    endif()
    if(DEFCOIN_NU_TX_BINARY)
        add_custom_command(TARGET DefcoinCoreExpForResources POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}/bin"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_TX_BINARY}" "${DEFCOIN_NU_EXPFOR_TX_OUTPUT}"
            COMMAND /bin/chmod 755 "${DEFCOIN_NU_EXPFOR_TX_OUTPUT}"
            COMMENT "Bundling Defcoin transaction utility for ExpFor"
        )
    endif()
    if(DEFCOIN_NU_WALLET_BINARY)
        add_custom_command(TARGET DefcoinCoreExpForResources POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "${DEFCOIN_NU_EXPFOR_RESOURCE_DIR}/bin"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_WALLET_BINARY}" "${DEFCOIN_NU_EXPFOR_WALLET_OUTPUT}"
            COMMAND /bin/chmod 755 "${DEFCOIN_NU_EXPFOR_WALLET_OUTPUT}"
            COMMENT "Bundling Defcoin wallet utility for ExpFor"
        )
    endif()
    if(WIN32)
        file(GLOB DEFCOIN_NU_BACKEND_RUNTIME_DLLS CONFIGURE_DEPENDS
            "${DEFCOIN_NU_BACKEND_INPUT_DIR}/*.dll"
        )
        foreach(backend_runtime_dll IN LISTS DEFCOIN_NU_BACKEND_RUNTIME_DLLS)
            add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different "${backend_runtime_dll}" "${DEFCOIN_NU_RESOURCE_DIR}/bin"
                COMMENT "Bundling Defcoin backend runtime DLL ${backend_runtime_dll}"
            )
        endforeach()
        get_filename_component(DEFCOIN_NU_BACKEND_MINGW_BIN_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
        foreach(backend_mingw_runtime IN ITEMS libgcc_s_seh-1.dll libstdc++-6.dll libwinpthread-1.dll)
            if(EXISTS "${DEFCOIN_NU_BACKEND_MINGW_BIN_DIR}/${backend_mingw_runtime}")
                add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_BACKEND_MINGW_BIN_DIR}/${backend_mingw_runtime}" "${DEFCOIN_NU_RESOURCE_DIR}/bin"
                    COMMENT "Bundling backend MinGW runtime ${backend_mingw_runtime}"
                )
            endif()
        endforeach()
        if(CMAKE_CXX_COMPILER)
            execute_process(COMMAND "${CMAKE_CXX_COMPILER}" -print-file-name=libgcc_s_seh-1.dll
                OUTPUT_VARIABLE DEFCOIN_NU_BACKEND_MINGW_LIBGCC OUTPUT_STRIP_TRAILING_WHITESPACE)
            execute_process(COMMAND "${CMAKE_CXX_COMPILER}" -print-file-name=libstdc++-6.dll
                OUTPUT_VARIABLE DEFCOIN_NU_BACKEND_MINGW_LIBSTDCPP OUTPUT_STRIP_TRAILING_WHITESPACE)
            foreach(backend_mingw_runtime_file IN ITEMS "${DEFCOIN_NU_BACKEND_MINGW_LIBGCC}" "${DEFCOIN_NU_BACKEND_MINGW_LIBSTDCPP}")
                if(EXISTS "${backend_mingw_runtime_file}")
                    add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${backend_mingw_runtime_file}" "${DEFCOIN_NU_RESOURCE_DIR}/bin"
                        COMMENT "Bundling backend MinGW runtime ${backend_mingw_runtime_file}"
                    )
                endif()
            endforeach()
            if(EXISTS "${DEFCOIN_NU_BACKEND_MINGW_LIBSTDCPP}")
                get_filename_component(DEFCOIN_NU_BACKEND_MINGW_TRIPLET_LIB "${DEFCOIN_NU_BACKEND_MINGW_LIBSTDCPP}" DIRECTORY)
                get_filename_component(DEFCOIN_NU_BACKEND_MINGW_TRIPLET_ROOT "${DEFCOIN_NU_BACKEND_MINGW_TRIPLET_LIB}" DIRECTORY)
                set(DEFCOIN_NU_BACKEND_MINGW_PTHREAD_DLL "${DEFCOIN_NU_BACKEND_MINGW_TRIPLET_ROOT}/bin/libwinpthread-1.dll")
                if(EXISTS "${DEFCOIN_NU_BACKEND_MINGW_PTHREAD_DLL}")
                    add_custom_command(TARGET DefcoinCoreNuResources POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${DEFCOIN_NU_BACKEND_MINGW_PTHREAD_DLL}" "${DEFCOIN_NU_RESOURCE_DIR}/bin"
                        COMMENT "Bundling backend MinGW runtime ${DEFCOIN_NU_BACKEND_MINGW_PTHREAD_DLL}"
                    )
                endif()
            endif()
        endif()
    endif()
endif()
