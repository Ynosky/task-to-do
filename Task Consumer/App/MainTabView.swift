//
//  MainTabView.swift
//  Task ToDo
//
//  Created by ryunosuke sato on 2025/12/21.
//

import SwiftUI
import SwiftData
import Charts

struct MainTabView: View {
    @State private var viewModel = TaskViewModel()
    @AppStorage("userInterfaceStyle") private var userInterfaceStyle: String = "light"
    
    private var colorScheme: ColorScheme? {
        switch userInterfaceStyle {
        case "light":
            return .light
        case "dark":
            return .dark
        case "system":
            return nil
        default:
            return .light
        }
    }
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            // Plan (計画)
            PlanView(viewModel: viewModel)
                .tabItem {
                    Label(AppText.Tab.plan, systemImage: "calendar")
                }
                .tag(0)
            
            // Do (実行)
            DoView(viewModel: viewModel)
                .tabItem {
                    Label(AppText.Tab.doTab, systemImage: "checkmark.circle.fill")
                }
                .tag(1)
            
            // Stats (統計)
            StatsView()
                .tabItem {
                    Label(AppText.Tab.stats, systemImage: "chart.bar")
                }
                .tag(2)
            
            // Settings (設定)
            SettingsView()
                .tabItem {
                    Label(AppText.Tab.settings, systemImage: "gearshape")
                }
                .tag(3)
        }
        .id(LanguageManager.shared.language)
        .tint(colorScheme == .dark ? AppTheme.Deep.accent : AppTheme.Paper.accent)
        .preferredColorScheme(colorScheme)
        .background {
            if colorScheme == .dark {
                SeaPatternBackground()
            }
        }
    }
}

// MARK: - Stats View

struct StatsView: View {
    @Query(sort: \TaskItem.date, order: .forward) private var tasks: [TaskItem]
    @Environment(\.colorScheme) private var colorScheme
    
    // 表示モード管理
    @State private var chartDataType: ChartDataType = .timeSaved
    @State private var selectedPeriod: ChartPeriod = .sevenDays
    
    enum ChartDataType: String, CaseIterable {
        case timeSaved
        case workTime
        
        var displayName: String {
            switch self {
            case .timeSaved: return AppText.Stats.timeSaved
            case .workTime: return AppText.Stats.workTime
            }
        }
    }
    
    enum ChartPeriod: String, CaseIterable {
        case sevenDays
        case oneMonth
        case sixMonths
        
        var days: Int {
            switch self {
            case .sevenDays: return 7
            case .oneMonth: return 30
            case .sixMonths: return 180
            }
        }
        
        var displayName: String {
            switch self {
            case .sevenDays: return AppText.Stats.sevenDays
            case .oneMonth: return AppText.Stats.oneMonth
            case .sixMonths: return AppText.Stats.sixMonths
            }
        }
    }
    
    // チャートデータポイント
    struct ChartDataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let timeSaved: Int // 分単位
        let workTime: Int // 分単位（実績時間の合計）
    }
    
    // データ集計用モデル（計画精度用）
    struct DailyStats {
        let date: Date
        let planned: Double
        let actual: Double
    }
    
    struct MovingAveragePoint: Identifiable {
        let id = UUID()
        let date: Date
        let accuracy: Double // 0.8 = 80%
    }
    
    // 過去N日間の完了タスクを取得
    func getCompletedTasks(days: Int) -> [TaskItem] {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: now) else {
            return []
        }
        return tasks.filter { task in
            task.date >= startDate && task.isCompleted && task.actualDuration != nil
        }
    }
    
    // 過去N日間の節約時間を計算
    func calculateTotalTimeSaved(days: Int) -> Int {
        let completedTasks = getCompletedTasks(days: days)
        return completedTasks.reduce(0) { total, task in
            guard let actual = task.actualDuration else { return total }
            return total + (task.effectiveDuration - actual)
        }
    }
    
    // 過去N日間の完了タスク数を計算
    func calculateCompletedTasks(days: Int) -> Int {
        getCompletedTasks(days: days).count
    }
    
    // 3日間移動平均データの生成（計画精度用）
    func calculateMovingAverages() -> [MovingAveragePoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 1. 日ごとの集計
        var dailyMap: [Date: DailyStats] = [:]
        for task in tasks where task.isCompleted && task.actualDuration != nil {
            let date = calendar.startOfDay(for: task.date)
            let current = dailyMap[date] ?? DailyStats(date: date, planned: 0, actual: 0)
            
            dailyMap[date] = DailyStats(
                date: date,
                planned: current.planned + Double(task.effectiveDuration),
                actual: current.actual + Double(task.actualDuration!)
            )
        }
        
        // 2. 直近10日分の移動平均を計算
        var points: [MovingAveragePoint] = []
        for i in 0..<10 {
            guard let targetDate = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            
            var sumPlanned: Double = 0
            var sumActual: Double = 0
            
            // 過去3日分(当日含む)を合算
            for j in 0..<3 {
                if let pastDate = calendar.date(byAdding: .day, value: -j, to: targetDate),
                   let stats = dailyMap[pastDate] {
                    sumPlanned += stats.planned
                    sumActual += stats.actual
                }
            }
            
            if sumPlanned > 0 {
                points.append(MovingAveragePoint(date: targetDate, accuracy: sumActual / sumPlanned))
            }
        }
        
        return points.sorted { $0.date < $1.date }
    }
    
    // 現在の計画精度とステータス
    private var currentAccuracy: Double {
        let data = calculateMovingAverages()
        return data.last?.accuracy ?? 0.0
    }
    
    private var accuracyStatus: String {
        let accuracy = currentAccuracy
        if accuracy < 0.8 {
            return AppText.Stats.tooLoose
        } else if accuracy <= 1.2 {
            return AppText.Stats.perfectZone
        } else {
            return AppText.Stats.overtime
        }
    }
    
    private var accuracyColor: Color {
        let accuracy = currentAccuracy
        if accuracy < 0.8 {
            return .orange
        } else if accuracy <= 1.2 {
            return .green
        } else {
            return .red
        }
    }
    
    // チャート用データを生成
    func generateChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let days = selectedPeriod.days
        var dataPoints: [ChartDataPoint] = []
        
        for i in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: targetDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let dayTasks = tasks.filter { task in
                task.date >= startOfDay && task.date < endOfDay &&
                task.isCompleted && task.actualDuration != nil
            }
            
            let timeSaved = dayTasks.reduce(0) { total, task in
                guard let actual = task.actualDuration else { return total }
                return total + (task.effectiveDuration - actual)
            }
            
            let workTime = dayTasks.reduce(0) { total, task in
                total + (task.actualDuration ?? 0)
            }
            
            dataPoints.append(ChartDataPoint(
                date: startOfDay,
                timeSaved: timeSaved,
                workTime: workTime
            ))
        }
        
        return dataPoints.reversed() // 古い順に
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. サマリーカード (2カラム)
                    HStack(spacing: 16) {
                        SummaryCard(
                            title: AppText.Stats.timeSaved,
                            value: formatDuration(calculateTotalTimeSaved(days: 30)),
                            icon: "hourglass.bottomhalf.filled",
                            color: AppTheme.accent(for: colorScheme)
                        )
                        
                        SummaryCard(
                            title: AppText.Stats.tasksDone,
                            value: "\(calculateCompletedTasks(days: 30))",
                            icon: "checkmark.circle.fill",
                            color: .blue
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // 2. Planning Accuracy Graph (計画精度グラフ)
                    accuracyTrendGraph
                    
                    // 3. チャートセクション
                    chartSection
                }
            }
            .background(Color.clear) // 背景を透明にして深海パターンが見えるように
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    // MARK: - View Components
    
    private var accuracyTrendGraph: some View {
        let data = calculateMovingAverages()
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppText.Stats.planningAccuracy)
                        .font(.headline)
                    
                    Text(AppText.Stats.target)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                }
                
                Spacer()
                
                // 現在のスコア表示
                if !data.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.0f%%", currentAccuracy * 100))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(accuracyColor)
                        Text(accuracyStatus)
                            .font(.caption)
                            .foregroundColor(accuracyColor)
                    }
                }
            }
            
            if data.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    Text(AppText.Stats.noData)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                }
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else {
                Chart {
                    // ターゲットゾーン (80-120%)
                    if let firstDate = data.first?.date,
                       let lastDate = data.last?.date {
                        RectangleMark(
                            xStart: .value("Start", firstDate, unit: .day),
                            xEnd: .value("End", lastDate, unit: .day),
                            yStart: .value("Low", 0.8),
                            yEnd: .value("High", 1.2)
                        )
                        .foregroundStyle(.green.opacity(0.15))
                    }
                    
                    // 移動平均線
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Accuracy", point.accuracy)
                        )
                        .foregroundStyle(AppTheme.accent(for: colorScheme))
                        .symbol(Circle())
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartYScale(domain: 0...2.0) // 0% - 200%表示
                .chartYAxis {
                    AxisMarks(values: [0.0, 0.5, 0.8, 1.0, 1.2, 1.5, 2.0]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(String(format: "%.0f%%", doubleValue * 100))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        AxisValueLabel(format: .dateTime.month().day())
                        AxisGridLine()
                    }
                }
                .frame(height: 250)
            }
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .padding(.horizontal)
    }
    
    private var chartSection: some View {
        let chartData = generateChartData()
        
        return VStack(alignment: .leading, spacing: 16) {
            // コントロール
            HStack {
                Picker("Data Type", selection: $chartDataType) {
                    ForEach(ChartDataType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                
                Spacer()
                
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(ChartPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            
            // チャート本体
            if chartData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    Text(AppText.Stats.noDataAvailable)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else {
                Chart {
                    ForEach(chartData) { point in
                        let value = chartDataType == .timeSaved ? point.timeSaved : point.workTime
                        let color = chartDataType == .timeSaved
                            ? (value >= 0 ? AppTheme.accent(for: colorScheme) : Color.red)
                            : Color.blue
                        
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(color)
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: selectedPeriod == .sixMonths ? 30 : 1)) { value in
                        AxisValueLabel(format: .dateTime.month().day())
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(formatMinutes(intValue))
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: 300)
            }
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // 分数を "2h 15m" 形式にするヘルパー
    func formatDuration(_ minutes: Int) -> String {
        let absMinutes = abs(minutes)
        let h = absMinutes / 60
        let m = absMinutes % 60
        let sign = minutes < 0 ? "-" : "+"
        
        if h > 0 && m > 0 {
            return "\(sign) \(h)h \(m)m"
        } else if h > 0 {
            return "\(sign) \(h)h"
        } else {
            return "\(sign) \(m)m"
        }
    }
    
    // チャート用の時間フォーマット（短縮版）
    func formatMinutes(_ minutes: Int) -> String {
        let absMinutes = abs(minutes)
        let h = absMinutes / 60
        let m = absMinutes % 60
        
        if h > 0 && m > 0 {
            return "\(h)h \(m)m"
        } else if h > 0 {
            return "\(h)h"
        } else {
            return "\(m)m"
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.05), radius: 5)
    }
}


// MARK: - Sea Pattern Background

struct SeaPatternBackground: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 全体のベースグラデーション
                LinearGradient(
                    colors: [
                        .teal.opacity(0.15),
                        .black.opacity(0.8), // 深さを出すため少し暗く
                        .blue.opacity(0.1)
                    ],
                    startPoint: isAnimating ? .topLeading : .top,
                    endPoint: isAnimating ? .bottomTrailing : .bottom
                )
                .animation(.easeInOut(duration: 15).repeatForever(autoreverses: true), value: isAnimating)
                
                // 2. 漂う光の玉 (メイン: Teal)
                Circle()
                    .fill(Color.teal.opacity(0.12))
                    .frame(width: geometry.size.width * 0.9)
                    .scaleEffect(isAnimating ? 1.1 : 0.9) // 呼吸
                    .offset(x: isAnimating ? -30 : 30, y: isAnimating ? -20 : 20) // 漂い
                    .blur(radius: 60)
                    .position(x: geometry.size.width * 0.3, y: geometry.size.height * 0.4)
                    .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: isAnimating)
                
                // 3. 漂う光の玉 (サブ: Blue)
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: geometry.size.width * 0.8)
                    .scaleEffect(isAnimating ? 1.0 : 1.2)
                    .offset(x: isAnimating ? 40 : -20, y: isAnimating ? 30 : -10)
                    .blur(radius: 50)
                    .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.8)
                    .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: isAnimating)
                
                // 4. 深層からの輝き (Indigo)
                RadialGradient(
                    colors: [.indigo.opacity(0.15), .clear],
                    center: isAnimating ? .bottomLeading : .bottomTrailing,
                    startRadius: 0,
                    endRadius: geometry.size.height * 0.6
                )
                .opacity(isAnimating ? 0.8 : 0.5) // 明滅
                .animation(.easeInOut(duration: 14).repeatForever(autoreverses: true), value: isAnimating)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false) // タップ操作を邪魔しない
        .onAppear {
            // ゆっくりとした深海の動き
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: TaskItem.self, inMemory: true)
}

