//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Section where Parent == Text, Footer == Text, Content: View {

    init(
        _ header: String,
        footer: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(content: content) {
            Text(header)
        } footer: {
            Text(footer)
        }
    }
}

// MARK: - Section Overloads

func Section(
    _ title: String,
    @ViewBuilder content: @escaping () -> some View,
    @LabeledContentBuilder learnMore: @escaping () -> AnyView
) -> some View {
    Section(
        title,
        content: content,
        footer: { EmptyView() },
        learnMore: learnMore
    )
}

func Section(
    _ title: String,
    footer: String,
    @ViewBuilder content: @escaping () -> some View,
    @LabeledContentBuilder learnMore: @escaping () -> AnyView
) -> some View {
    Section(
        title,
        content: content,
        footer: { Text(footer) },
        learnMore: learnMore
    )
}

func Section(
    _ title: String,
    @ViewBuilder content: @escaping () -> some View,
    @ViewBuilder footer: @escaping () -> some View,
    @LabeledContentBuilder learnMore: @escaping () -> AnyView
) -> some View {
    InlinePlatformView {
        Section {
            content()
        } header: {
            Text(title)
        } footer: {
            VStack(alignment: .leading) {
                footer()

                LearnMoreButton(
                    title,
                    content: learnMore
                )
            }
        }
    } tvOSView: {
        Section {
            content()
                .focusedValue(\.formLearnMore, learnMore())
        } header: {
            Text(title)
        } footer: {
            footer()
        }
    }
}

// MARK: - LearnMoreButton

private struct LearnMoreButton: View {

    @State
    private var isPresented = false

    private let content: AnyView
    private let title: String

    init(
        _ title: String,
        @LabeledContentBuilder content: @escaping () -> AnyView
    ) {
        self.content = content()
        self.title = title
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label(L10n.learnMore + .ellipsis, systemImage: "info.circle")
        }
        #if os(visionOS)
        .buttonStyle(.plain)
        .font(.footnote)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .visionHoverEffect(Capsule(), .highlight)
        #else
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        #endif
        .sheet(isPresented: $isPresented) {
            NavigationStack {
                ScrollView {
                    SeparatorVStack(alignment: .leading) {
                        Divider()
                            .padding(.vertical, 8)
                    } content: {
                        content
                            .labeledContentStyle(LearnMoreLabeledContentStyle())
                            .foregroundStyle(Color.primary, Color.secondary)
                    }
                    .edgePadding()
                }
                .navigationTitle(title.localizedCapitalized)
                .navigationBarTitleDisplayMode(.inline)
                #if os(iOS) || os(visionOS)
                    .navigationBarCloseButton {
                        isPresented = false
                    }
                #endif
            }
        }
    }
}
