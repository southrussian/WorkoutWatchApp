//
//  WorkoutSession.swift
//  WorkoutWatch Watch App
//
//  Created by Danil Peregorodiev on 20.03.2023.
//

import Foundation
import SwiftUI
import HealthKit

class WorkoutSession: NSObject, HKLiveWorkoutBuilderDelegate, HKWorkoutSessionDelegate, ObservableObject {
    @Published var distanceStatistics: HKStatistics?
    @Published var energyBurnedStatistics: HKStatistics?
    @Published var heartRateStatistics: HKStatistics?
    @Published var elapsedTimeStatistics: HKStatistics?
    @Published var speedStatistics: HKStatistics?
    
    @Published var distance: Double?
    @Published var energyBurned: Double?
    @Published var elapsedTime: TimeInterval?
    @Published var speed: Double?
    @Published var bpm: Double?
    @Published var status = WorkoutSessionStatus.notStarted
    @Published var workoutData: HKWorkout?
    
    @Published var session: HKWorkoutSession?
    @Published var builder: HKWorkout?
    
    var healthStore = HKHealthStore()
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        self.distance = workoutBuilder.statistics(for: .init(.distanceWalkingRunning))?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo))
        self.distanceStatistics = workoutBuilder.statistics(for: .init(.distanceWalkingRunning))
        self.heartRateStatistics = workoutBuilder.statistics(for: .init(.heartRate))
        self.energyBurned = workoutBuilder.statistics(for: .init(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie())
        self.elapsedTime = workoutBuilder.elapsedTime
        self.speedStatistics = workoutBuilder.statistics(for: .init(.runningSpeed))
        self.bpm = calculateBPM()
        
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
}

enum WorkoutSessionStatus {
    case inProgress, complete, cancelled, notStarted, paused
}

extension WorkoutSession {
    private func calculateBPM() -> Double? {
        let countUnit: HKUnit = .count()
        let minuteUnit: HKUnit = .minute()
        let beatsPerMinute: HKUnit = countUnit.unitDivided(by: minuteUnit)
        
        return self.heartRateStatistics?.mostRecentQuantity()?.doubleValue(for: beatsPerMinute)
    }
}
