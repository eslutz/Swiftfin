//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

/// - Note: Set the environment `isEditing` to `true` to
///         allow server deletion
struct EditServerView: View {

    @Router
    private var router

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.isEditing)
    private var isEditing

    @State
    private var serverURLString: String
    @State
    private var saveError: Error? = nil
    @State
    private var isPresentingConfirmDeletion: Bool = false

    @StateObject
    private var viewModel: ServerConnectionViewModel

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: ServerConnectionViewModel(server: server))
        self._serverURLString = State(initialValue: server.currentURL.absoluteString)
    }

    private var normalizedServerURLString: String {
        serverURLString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedServerURL: URL? {
        guard let url = URL(string: normalizedServerURLString),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host?.isNotEmpty == true
        else {
            return nil
        }

        return url
    }

    private var canSave: Bool {
        guard let parsedServerURL else { return false }

        return parsedServerURL.absoluteString != viewModel.server.currentURL.absoluteString
    }

    private func save() {
        guard let parsedServerURL else { return }

        do {
            try viewModel.saveCurrentURL(to: parsedServerURL)
            dismiss()
        } catch {
            saveError = error
        }
    }

    var body: some View {
        Form(systemImage: "server.rack") {

            Section(L10n.server) {

                LabeledContent(
                    L10n.name,
                    value: viewModel.server.name
                )
                #if os(tvOS)
                .focusable(false)
                #endif

                if let serverVersion = StoredValues[.Server.publicInfo(id: viewModel.server.id)].version {
                    LabeledContent(
                        L10n.version,
                        value: serverVersion
                    )
                    #if os(tvOS)
                    .focusable(false)
                    #endif
                }
            }

            Section {
                #if os(tvOS)
                ListRowMenu(L10n.savedURLs, subtitle: serverURLString) {
                    Picker(L10n.savedURLs, selection: $serverURLString) {
                        ForEach(viewModel.server.urls.sorted(using: \.absoluteString), id: \.self) { url in
                            Text(url.absoluteString)
                                .tag(url.absoluteString)
                        }
                    }
                }
                #else
                TextField(L10n.url, text: $serverURLString)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                #if !os(visionOS)
                if viewModel.server.urls.count > 1 {
                    Picker(L10n.savedURLs, selection: $serverURLString) {
                        ForEach(viewModel.server.urls.sorted(using: \.absoluteString), id: \.self) { url in
                            Text(url.absoluteString)
                                .tag(url.absoluteString)
                        }
                    }
                }
                #endif
                #endif
            } header: {
                Text(L10n.serverURL)
            } footer: {
                if parsedServerURL == nil {
                    Label(L10n.invalidURL, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                } else if !viewModel.server.isVersionCompatible {
                    Label(
                        L10n.serverVersionWarning(viewModel.server.client.version.majorMinor.description),
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            if isEditing {
                Section {
                    Button(L10n.delete, role: .destructive) {
                        isPresentingConfirmDeletion = true
                    }
                    #if !os(visionOS)
                    .buttonStyle(.primary)
                    #endif
                }
            }
        }
        .navigationTitle(L10n.server)
        .navigationBarCloseButton {
            dismiss()
        }
        .topBarTrailing {
            Button(L10n.save, action: save)
                .disabled(!canSave)
        }
        .errorMessage($saveError)
        .alert(L10n.deleteServer, isPresented: $isPresentingConfirmDeletion) {
            Button(L10n.delete, role: .destructive) {
                viewModel.delete()
                router.dismiss()
            }
        } message: {
            Text(L10n.confirmDeleteServerAndUsers(viewModel.server.name))
        }
    }
}
