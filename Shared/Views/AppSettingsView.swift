//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: move sign out-stuff into super user when implemented

struct AppSettingsView: View {

    @Default(.selectUserUseSplashscreen)
    private var selectUserUseSplashscreen
    @Default(.selectUserAllServersSplashscreen)
    private var selectUserAllServersSplashscreen

    @Default(.backgroundSignOutInterval)
    private var backgroundSignOutInterval
    @Default(.signOutOnBackground)
    private var signOutOnBackground
    @Default(.signOutOnClose)
    private var signOutOnClose

    #if os(iOS)
    @Default(.appAppearance)
    private var appearance
    #endif

    @Router
    private var router

    @StateObject
    private var viewModel = SettingsViewModel()

    private var selectedSplashscreenServer: ServerState? {
        selectUserAllServersSplashscreen.server(from: viewModel.servers)
    }

    private var selectedSplashscreenServerSelection: Binding<SelectUserServerSelection> {
        Binding {
            Self.normalizedSplashscreenServerSelection(
                selectUserAllServersSplashscreen,
                servers: viewModel.servers
            )
        } set: { newValue in
            selectUserAllServersSplashscreen = newValue
        }
    }

    private var serverPicker: some View {
        Picker(L10n.servers, selection: selectedSplashscreenServerSelection) {
            Label(L10n.allServers, systemImage: "person.2.fill")
                .tag(SelectUserServerSelection.all)

            ForEach(viewModel.servers) { server in
                Text(server.name)
                    .tag(SelectUserServerSelection.server(id: server.id))
            }
        }
    }

    var body: some View {
        Form(image: .jellyfinBlobBlue) {

            Section(L10n.swiftfin) {
                ChevronButton(L10n.about) {
                    router.route(to: .aboutApp)
                }
            }

            #if os(iOS)
            Section(L10n.customize) {

                ChevronButton(L10n.appIcon) {
                    // TODO: Create NavigationRoute.appIconSelector
                    router.route(to: .appIconSelector(viewModel: viewModel))
                }

                if !selectUserUseSplashscreen {
                    Picker(
                        L10n.appearance,
                        selection: $appearance
                    )
                }
            }
            #endif

            Section {
                Toggle(L10n.useSplashscreen, isOn: $selectUserUseSplashscreen)

                if selectUserUseSplashscreen {

                    if viewModel.servers.isNotEmpty {
                        #if os(tvOS)
                        ListRowMenu(L10n.servers) {
                            if case .all = selectUserAllServersSplashscreen {
                                Text(L10n.allServers)
                            } else if let selectedServer = selectedSplashscreenServer {
                                Text(selectedServer.name)
                            } else {
                                Text(viewModel.servers.first?.name ?? L10n.none)
                            }
                        } content: {
                            serverPicker
                        }
                        #else
                        serverPicker
                        #endif
                    }
                }
            } header: {
                Text(L10n.splashscreen)
            } footer: {
                EmptyView()
            }

            Section {
                Toggle(L10n.signoutClose, isOn: $signOutOnClose)
            } footer: {
                Text(L10n.signoutCloseFooter)
            }

            Section {
                Toggle(L10n.signoutBackground, isOn: $signOutOnBackground)

                if signOutOnBackground {
                    HourMinutePicker(title: L10n.duration, interval: $backgroundSignOutInterval)
                }
            } footer: {
                Text(L10n.signoutBackgroundFooter)
            }

            ChevronButton(L10n.logs) {
                router.route(to: .log)
            }

            #if DEBUG
            ChevronButton("Debug") {
                router.route(to: .debugSettings)
            }
            #endif
        }
        .animation(.linear, value: selectUserUseSplashscreen)
        .animation(.linear, value: signOutOnBackground)
        .navigationTitle(L10n.advanced)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .onAppear(perform: normalizeSplashscreenServerSelection)
        .backport.onChange(of: viewModel.servers.map(\.id)) { _, _ in
            normalizeSplashscreenServerSelection()
        }
    }

    private func normalizeSplashscreenServerSelection() {
        let normalizedSelection = Self.normalizedSplashscreenServerSelection(
            selectUserAllServersSplashscreen,
            servers: viewModel.servers
        )

        guard normalizedSelection != selectUserAllServersSplashscreen else { return }

        selectUserAllServersSplashscreen = normalizedSelection
    }

    static func normalizedSplashscreenServerSelection(
        _ selection: SelectUserServerSelection,
        servers: [ServerState]
    ) -> SelectUserServerSelection {
        switch selection {
        case .all:
            return .all
        case let .server(id):
            guard servers.isNotEmpty else { return selection }
            guard servers.contains(where: { $0.id == id }) else {
                return .server(id: servers[0].id)
            }

            return selection
        }
    }
}
