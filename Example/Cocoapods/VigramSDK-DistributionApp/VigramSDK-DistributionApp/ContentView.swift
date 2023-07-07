//
//  ContentView.swift
//  VigramSDK-DistributionApp
//
//  Created by Aleksei Sablin on 30.03.23.
//  Copyright © 2020 Vigram. All rights reserved.
//

import SwiftUI
import VigramSDK

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
