//
//  ContentView.swift
//  WorkoutWatch Watch App
//
//  Created by Danil Peregorodiev on 11.10.2022.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @ObservedObject var workoutsession = WorkoutSession()
    @State private var scale = 1.0
    var body: some View {
        VStack {
            if workoutsession.status == .notStarted {
                Button("Начать") {
                    workoutsession.setupSession()
                    workoutsession.startWorkoutSession()
                }
            } else if workoutsession.status == .inProgress {
                if workoutsession.distance != nil {
                    HStack {
                        Image(systemName: "ruler")
                        Spacer()
                        Text(distanceFormatter())
                    }
                }
                
                if workoutsession.bpm != nil {
                    HStack {
                        Image(systemName: "heart")
                            .foregroundColor(.red)
                            .scaleEffect(scale)
                            .onAppear {
                                let animation = Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)
                                withAnimation(animation) {
                                    scale = 0.5
                                }
                            }
                        Spacer()
                        Text(heartBeatFormatter())
                    }
                }
                
                if workoutsession.energyBurned != nil {
                    HStack {
                        Image(systemName: "figure.run")
                        Spacer()
                        Text("\(workoutsession.energyBurned!) ккал")
                        
                    }
                }
                
                if workoutsession.elapsedTime != nil {
                    HStack {
                        Image(systemName: "stopwatch")
                        Spacer()
                        Text("\(workoutsession.elapsedTime!)")
                    }
                }
                
                Button {
                    workoutsession.pauseWorkout()
                    scale = 1.0
                } label: {
                    HStack {
                        Image(systemName: "pause")
                            .padding(5)
                        Text("Пауза")
                    }
                }
                
                Button {
                    workoutsession.endWorkoutSession()
                    
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                            .padding(5)
                        Text("Конец")
                    }
                }
            } else if workoutsession.status == .paused {
                if workoutsession.distance != nil {
                    HStack {
                        Image(systemName: "ruler")
                        Spacer()
                        Text(distanceFormatter())
                    }
                }
                
                if workoutsession.bpm != nil {
                    HStack {
                        Image(systemName: "heart")
                            .foregroundColor(.red)
                            .scaleEffect(scale)
                            .onAppear {
                                let animation = Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)
                                withAnimation(animation) {
                                    scale = 0.5
                                }
                            }
                        Spacer()
                        Text(heartBeatFormatter())
                    }
                }
                
                if workoutsession.energyBurned != nil {
                    HStack {
                        Image(systemName: "figure.run")
                        Spacer()
                        Text("\(workoutsession.energyBurned!) ккал")
                    }
                }
                
                if workoutsession.elapsedTime != nil {
                    HStack {
                        Image(systemName: "stopwatch")
                        Spacer()
                        Text("\(workoutsession.elapsedTime!)")
                    }
                }
                
                Button {
                    workoutsession.resumeWorkout()
                    scale = 1.0
                } label: {
                    HStack {
                        Image(systemName: "play.circle")
                            .padding(5)
                        Text("Продолжить")
                    }
                }
                
                Button {
                    workoutsession.endWorkoutSession()
                    
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                            .padding(5)
                        Text("Конец")
                    }
                }
            } else if workoutsession.status == .complete {
                if workoutsession.distance != nil {
                    HStack {
                        Image(systemName: "ruler")
                        Spacer()
                        Text(distanceFormatter())
                    }
                }
                
                if workoutsession.bpm != nil {
                    HStack {
                        Image(systemName: "heart")
                            .foregroundColor(.red)
                            .scaleEffect(scale)
                            .onAppear {
                                let animation = Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)
                                withAnimation(animation) {
                                    scale = 0.5
                                }
                            }
                        Spacer()
                        Text(heartBeatFormatter())
                    }
                }
                
                if workoutsession.energyBurned != nil {
                    HStack {
                        Text("\(workoutsession.energyBurned!) ккал")
                        Spacer()
                    }
                }
                
                if workoutsession.elapsedTime != nil {
                    HStack {
                        Image(systemName: "stopwatch")
                        Spacer()
                        Text("\(workoutsession.elapsedTime!)")
                    }
                }
                Button("Конец") {
                    workoutsession.status = .notStarted
                }
            }
        }
    }
    
    func distanceFormatter() -> String {
        let formatter = NumberFormatter()
        formatter.maximumSignificantDigits = 3
        return formatter.string(from: workoutsession.distance! as NSNumber)!
    }
    
    func heartBeatFormatter() -> String {
        let formatter = NumberFormatter()
        formatter.maximumSignificantDigits = 0
        return formatter.string(from: workoutsession.bpm! as NSNumber)!
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


