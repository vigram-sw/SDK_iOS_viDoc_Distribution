//
//  NMEASubview.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 14.12.23.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

struct NMEASubview: View {

    // MARK: Private properties

    @ObservedObject private var viewModel: MainScreenView.MainScreenViewModel

    @State private var showViDocReset = false
    @State private var showDeviceNumber = false

    // MARK: Init

    init(_ viewModel: MainScreenView.MainScreenViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Computed properties

    var body: some View {
        VStack {
            if viewModel.isReadyNMEA, !viewModel.rmxIsActive {
                HStack {
                    Text("  Latitude: ").font(Font.headline.bold()).foregroundColor(.black)
                    Text(viewModel.latitude)
                    Spacer()
                }
                HStack {
                    Text("  Longitude: ").font(Font.headline.bold()).foregroundColor(.black)
                    Text(viewModel.longitude)
                    Spacer()
                }
                HStack {
                    Text("  Count satellite: ").font(Font.headline.bold()).foregroundColor(.black)
                    Text(viewModel.countSatellite)
                    Spacer()
                }
                HStack {
                    Text("  Vert. accuracy: ").font(Font.headline.bold()).foregroundColor(.black)
                    Text(viewModel.vertAcc)
                    Spacer()
                }
                HStack {
                    Text("  Horiz. accuracy: ").font(Font.headline.bold()).foregroundColor(.black)
                    Text(viewModel.horAcc)
                    Spacer()
                }
                HStack {
                    Text("  Correction: ").font(Font.headline.bold()).foregroundColor(.black)
                    Text(viewModel.correction)
                    Spacer()
                }
                HStack {
                    Text("  Latitude error: ").font(Font.headline.bold()).foregroundColor(.black)
                    Text(viewModel.latAccErr)
                    Spacer()
                }
                HStack {
                    Text("  Longitude error: ").font(Font.headline.bold()).foregroundColor(.black)
                    Text(viewModel.lonAccErr)
                    Spacer()
                }
            }
            HStack {
                Text("  North velocity: ").font(Font.headline.bold()).foregroundColor(.black)
                Text(viewModel.nVelocity)
                Spacer()
            }
            HStack {
                Text("  East velocity: ").font(Font.headline.bold()).foregroundColor(.black)
                Text(viewModel.eVelocity)
                Spacer()
            }
            HStack {
                Text("  Down velocity: ").font(Font.headline.bold()).foregroundColor(.black)
                Text(viewModel.dVelocity)
                Spacer()
            }
            HStack {
                Text("  PDOP: ").font(Font.headline.bold()).foregroundColor(.black)
                Text(viewModel.pdop)
                Spacer()
            }
            HStack {
                Text("  VDOP: ").font(Font.headline.bold()).foregroundColor(.black)
                Text(viewModel.vdop)
                Spacer()
            }
            HStack {
                Text("  HDOP: ").font(Font.headline.bold()).foregroundColor(.black)
                Text(viewModel.hdop)
                Spacer()
            }
            HStack {
                Text("  TDOP: ").font(Font.headline.bold()).foregroundColor(.black)
                Text(viewModel.tdop)
                Spacer()
            }
            HStack {
                Text("  GDOP: ").font(Font.headline.bold()).foregroundColor(.black)
                Text(viewModel.gdop)
                Spacer()
            }
            HStack {
                Text("  RTK: ").font(Font.headline.bold()).foregroundColor(.black)
                Text(viewModel.rtkStatus)
                Spacer()
            }
        }.padding(6)
    }
}
