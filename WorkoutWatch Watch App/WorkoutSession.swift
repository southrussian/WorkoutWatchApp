//
//  WorkoutSession.swift
//  WorkoutWatch Watch App
//
//  Created by Danil Peregorodiev on 20.03.2023.
//

import Foundation
import SwiftUI
import HealthKit

class WorkoutSession: NSObject, HKLiveWorkoutBuilderDelegate, HKWorkoutSessionDelegate, ObservableObject { // добавление свойств тренировки
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
    
    @Published var session: HKWorkoutSession? // определение тренировочной сессии
    @Published var builder: HKLiveWorkoutBuilder? // определение билдера тренировки
    
    var healthStore = HKHealthStore() // объект для запроса на работу с данными Apple Health
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) { // инициализация свойств класса тренировочной сессии
        self.distance = workoutBuilder.statistics(for: .init(.distanceWalkingRunning))?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo))
        self.distanceStatistics = workoutBuilder.statistics(for: .init(.distanceWalkingRunning))
        self.heartRateStatistics = workoutBuilder.statistics(for: .init(.heartRate))
        self.energyBurned = workoutBuilder.statistics(for: .init(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie())
        self.elapsedTime = workoutBuilder.elapsedTime
        self.speedStatistics = workoutBuilder.statistics(for: .init(.runningSpeed))
        self.bpm = calculateBPM()
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { // метод нужен для соответствия протоколу
        
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) { // метод нужен для соответствия протоколу
        
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { // метод нужен для соответствия протоколу
        
    }
    
    func setupSession() { // здесь определяется то, с чем работает healthkit и его друг apple health
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [HKQuantityType.quantityType(forIdentifier: .heartRate)!,
                                HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                                HKQuantityType.quantityType(forIdentifier: .runningSpeed)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            // запрос на работу с apple health
        }
    }
    
    func startWorkoutSession() { // инициализация данных для начала тренировки
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
                self.status = .inProgress // перевод тренировки в режим "в процессе"
            }
        } catch {
            
        }
    }
    
    func endWorkoutSession() { // нужен для окончания тренировки
        guard let session = session else { // проверяет сессию
            print("Невозможно закончить тренировку. Сессия отсутствует")
            return
        }
        
        guard let builder = builder else { // проверяет билдер
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
    
    func resumeWorkout() { // возобновление тренировки
        guard let session = session else {
            print("Невозможно продолжить тренировку. Сессия отсутствует")
            return
        }
        session.resume()
        self.status = .inProgress
    }
    
    func pauseWorkout() { // приостановка тренировки
        guard let session = session else {
            print("Невозможно приостановить тренировку. Сессия отсутствует")
            return
        }
        session.pause()
        self.status = .paused
    }
}

enum WorkoutSessionStatus { // кейсы для статуса тренировки
    case inProgress, complete, cancelled, notStarted, paused
}

extension WorkoutSession { // расчет пульса для свойства bpm
    private func calculateBPM() -> Double? {
        let countUnit: HKUnit = .count()
        let minuteUnit: HKUnit = .minute()
        let beatsPerMinute: HKUnit = countUnit.unitDivided(by: minuteUnit)
        
        return self.heartRateStatistics?.mostRecentQuantity()?.doubleValue(for: beatsPerMinute)
    }
}
