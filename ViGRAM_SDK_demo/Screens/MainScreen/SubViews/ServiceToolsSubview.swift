//
//  ServiceToolsSubview.swift
//  ViGRAM_SDK_demo
//
//  Created by Khaustov Iaroslav
//

import SwiftUI

struct ServiceToolsSubview: View {

    @ObservedObject var viewModel: ServiceToolsViewModel

    var body: some View {
        ClientCard(
            title: "Device Service Tools",
            subtitle: "Rare support actions that are not needed in a normal workflow."
        ) {
            ClientActionGrid(minimumWidth: 150) {
                Button("Refresh battery") {
                    viewModel.requestBattery()
                }
                .buttonStyle(.bordered)

            }


            DisclosureGroup("Reset viDoc control") {
                VStack(alignment: .leading, spacing: 10) {
                    if !viewModel.resetMessageError.isEmpty {
                        Text(viewModel.resetMessageError)
                            .font(.subheadline.bold())
                            .foregroundColor(.red)
                    }

                    Button("Reset viDoc") {
                        viewModel.resetDevice()
                    }
                    .buttonStyle(.bordered)

                    Text("GNTXT messages")
                        .font(.subheadline.bold())
                        .foregroundStyle(ClientTheme.textPrimary)

                    ClientLogBox(
                        text: viewModel.viDocState,
                        placeholder: "No GNTXT messages yet."
                    )

                    Button("Clear log") {
                        viewModel.clearTXTLog()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 8)
            }
        }
    }
}
