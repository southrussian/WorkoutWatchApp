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
    @Published var builder: HKLiveWorkoutBuilder?
    
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
    
    func setupSession() {
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [HKQuantityType.quantityType(forIdentifier: .heartRate)!,
                                HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                                HKQuantityType.quantityType(forIdentifier: .runningSpeed)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            
        }
    }
    
    func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session!.associatedWorkoutBuilder()
            builder!.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            session!.delegate = self
            builder!.delegate = self
            
            session!.startActivity(with: Date())
            builder!.beginCollection(withStart: Date()) { success, error in
                if !success {
                    print("Невозможно начать сбор. Ошибка: \(error)")
                }
                self.status = .inProgress
            }
        } catch {
            
        }
    }
    
    func endWorkoutSession() {
        guard let session = session else {
            print("Невозможно закончить тренировку. Сессия отсутствует")
            return
        }
        
        guard let builder = builder else {
            print("Невозможно закончить тренировку. Билдер отсутствует")
            return
        }
        session.end()
        builder.endCollection(withEnd: Date()) { success, error in
            if !success {
                print("Невозможно закончить сбор")
                return
            }
            
            builder.finishWorkout { workout, error in
                if workout == nil {
                    print("Невозможно прочитать данные тренировки")
                    return
                }
                
                self.status = .complete
                self.workoutData = workout
            }
        }
    }
    
    func resumeWorkout() {
        guard let session = session else {
            print("Невозможно подытожить тренировку. Сессия отсутствует")
            return
        }
        session.resume()
        self.status = .inProgress
    }
    
    func pauseWorkout() {
        guard let session = session else {
            print("Невозможно приостановить тренировку. Сессия отсутствует")
            return
        }
        session.pause()
        self.status = .paused
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
