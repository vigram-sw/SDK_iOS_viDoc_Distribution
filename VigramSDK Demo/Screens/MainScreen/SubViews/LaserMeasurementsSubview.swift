//
//  LaserMeasurementsSubview.swift
//  VigramSDK Demo
//
//  Created by Aleksei Sablin on 15.12.23.
//  Copyright © 2023 Vigram GmbH. All rights reserved.
//

import SwiftUI

struct LaserMeasurementsSubview: View {

    // MARK: Private properties

    @ObservedObject private var viewModel: MainScreenView.MainScreenViewModel

    @State private var showOffsets = false

    // MARK: Init
    
    init(_ viewModel: MainScreenView.MainScreenViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: Computed properties
    
    var body: some View {
        VStack {
            Text("Laser configuration").font(Font.headline.bold())
            HStack {
                Text("  Duration (second): ").font(Font.headline.bold())
                TextField("5", text: $viewModel.durationMeasurements)
                    .keyboardType(.decimalPad)
                Spacer()
            }
            if let isNewProtocol = viewModel.isNewProtocol, isNewProtocol {
                HStack {
                    Text("  Notice: 0 second - infinity measurements").font(Font.headline.bold())
                    Spacer()
                }
                HStack {
                    Text("  Cancel measurements - press LasersOff").font(Font.headline.bold())
                    Spacer()
                }
            }
            HStack {
                SelectButton(
                    isSelected: $viewModel.isBottomLaserSelected,
                    color: .green,
                    text: "Bottom"
                ).onTapGesture {
                    viewModel.turnOffLaser()
                    viewModel.isBottomLaserSelected = true
                    if viewModel.isBottomLaserSelected {
                        viewModel.setCurrentOffset(with: .bottom)
                        showOffsets = false
                    }
                }
                SelectButton(
                    isSelected: $viewModel.isBackLaserSelected,
                    color: .green,
                    text: "Back"
                ).onTapGesture {
                    viewModel.turnOffLaser()
                    viewModel.isBackLaserSelected = true
                    if viewModel.isBackLaserSelected {
                        viewModel.setCurrentOffset(with: .back)
                        showOffsets = false
                    }
                }
            }
            if let isNewProtocol = viewModel.isNewProtocol, isNewProtocol {
                HStack {
                    Text("  Lasers state: ")
                        .font(Font.headline.bold())
                        .foregroundColor(.black)
                    Text(viewModel.lasersState)
                    Spacer()
                }
            }
            Button { viewModel.getLaserStatus() } label: {
                Text("Get lasers status")
                    .font(Font.headline.bold())
                    .foregroundColor(.black)
            }.buttonStyle(.bordered)
            Button { viewModel.turnOnLaser() } label: {
                Text("LaserOn")
                    .font(Font.headline.bold())
                    .foregroundColor(.black)
            }.buttonStyle(.bordered)
            Button { viewModel.turnOffLaser() } label: {
                Text("LaserOff")
                    .font(Font.headline.bold())
                    .foregroundColor(.black)
            }.buttonStyle(.bordered)
            Button { viewModel.startLaser() } label: {
                Text("Start measurements")
                    .font(Font.headline.bold())
                    .foregroundColor(.black)
            }.buttonStyle(.bordered)
            HStack {
                Text("  Distance: ").font(Font.headline.bold())
                Text(viewModel.distance)
                Spacer()
            }
            HStack {
                Text("  Quality: ").font(Font.headline.bold())
                Text(viewModel.quality)
                Spacer()
            }
        }.padding(6)
    }
}
