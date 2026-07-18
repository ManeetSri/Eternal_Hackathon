//
//  HomeViewModel.swift
//  Eternal Scan
//
//  Created by Maneet@MLL on 18/07/26.
//

import Foundation

@Observable
final class HomeViewModel {
    private let container: AppContainer
    
    let title = "Eternal Scan"
    let subtitle = "Refill your home in seconds."
    
    init(container: AppContainer) {
        self.container = container
    }
}


extension HomeViewModel {
    func navigateToScanner() {
        container.router.push(.scanner)
    }

    func navigateToMeal() {
        container.router.push(.mealInput)
    }
}

