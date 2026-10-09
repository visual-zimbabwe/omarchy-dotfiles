// Strat Journal Analytical Model and Calculation Routines

function computeR(direction, triggerPrice, stopLoss, exitPrice) {
    var trig = Number(triggerPrice)
    var stop = Number(stopLoss)
    var exit = Number(exitPrice)

    if (!isFinite(trig) || !isFinite(stop) || !isFinite(exit)) return 0.0
    var risk = Math.abs(trig - stop)
    if (risk <= 0.0001) return 0.0

    if (direction === "Short") {
        return (trig - exit) / risk
    } else {
        return (exit - trig) / risk
    }
}

function calculatePositionSize(riskDollars, triggerPrice, stopLoss) {
    var r = Number(riskDollars) || 100
    var trig = Number(triggerPrice)
    var stop = Number(stopLoss)
    var riskPerShare = Math.abs(trig - stop)
    if (riskPerShare <= 0.01) return { shares: 0, riskPerShare: 0 }
    var shares = Math.floor(r / riskPerShare)
    return {
        shares: shares,
        riskPerShare: Number(riskPerShare.toFixed(2)),
        totalRisk: Number((shares * riskPerShare).toFixed(2))
    }
}

function computeStatistics(trades) {
    if (!trades || !Array.isArray(trades) || trades.length === 0) {
        return {
            totalTrades: 0,
            closedTrades: 0,
            openTrades: 0,
            totalR: 0.0,
            winRate: 0,
            wins: 0,
            losses: 0,
            scratches: 0,
            avgWinnerR: 0.0,
            avgLoserR: 0.0,
            profitFactor: 0.0,
            comboStats: {},
            gradeStats: { "A": 0, "B": 0, "C": 0, "F": 0 },
            mistakeStats: {}
        }
    }

    var closed = []
    var openCount = 0

    for (var i = 0; i < trades.length; i++) {
        var t = trades[i]
        if (t.status === "open") {
            openCount++
        } else {
            closed.push(t)
        }
    }

    var totalR = 0.0
    var wins = 0
    var losses = 0
    var scratches = 0
    var winRSum = 0.0
    var lossRSum = 0.0

    var comboMap = {}
    var gradeMap = { "A": { count: 0, r: 0.0, wins: 0 }, "B": { count: 0, r: 0.0, wins: 0 }, "C": { count: 0, r: 0.0, wins: 0 }, "F": { count: 0, r: 0.0, wins: 0 } }
    var mistakeMap = {}

    for (var j = 0; j < closed.length; j++) {
        var ct = closed[j]
        var rVal = Number(ct.realized_r || 0.0)
        totalR += rVal

        if (rVal > 0.05) {
            wins++
            winRSum += rVal
        } else if (rVal < -0.05) {
            losses++
            lossRSum += Math.abs(rVal)
        } else {
            scratches++
        }

        // Strat Combo grouping
        var combo = ct.combo || "Other"
        if (!comboMap[combo]) {
            comboMap[combo] = { count: 0, wins: 0, totalR: 0.0 }
        }
        comboMap[combo].count++
        comboMap[combo].totalR += rVal
        if (rVal > 0.05) comboMap[combo].wins++

        // Grade grouping
        var g = ct.grade || "A"
        if (gradeMap[g]) {
            gradeMap[g].count++
            gradeMap[g].r += rVal
            if (rVal > 0.05) gradeMap[g].wins++
        }

        // Mistake grouping
        if (ct.mistake && ct.mistake !== "None" && ct.mistake !== "") {
            mistakeMap[ct.mistake] = (mistakeMap[ct.mistake] || 0) + 1
        }
    }

    var totalDecided = wins + losses
    var winRate = totalDecided > 0 ? Math.round((wins / totalDecided) * 100) : 0
    var avgWinner = wins > 0 ? Number((winRSum / wins).toFixed(2)) : 0.0
    var avgLoser = losses > 0 ? Number((lossRSum / losses).toFixed(2)) : 0.0
    var profitFactor = lossRSum > 0 ? Number((winRSum / lossRSum).toFixed(2)) : (winRSum > 0 ? 99.9 : 0.0)

    // Convert comboMap to sorted array
    var comboList = []
    for (var k in comboMap) {
        var cData = comboMap[k]
        var cWinRate = cData.count > 0 ? Math.round((cData.wins / cData.count) * 100) : 0
        comboList.push({
            name: k,
            count: cData.count,
            wins: cData.wins,
            winRate: cWinRate,
            totalR: Number(cData.totalR.toFixed(2))
        })
    }
    comboList.sort(function(a, b) { return b.totalR - a.totalR })

    return {
        totalTrades: trades.length,
        closedTrades: closed.length,
        openTrades: openCount,
        totalR: Number(totalR.toFixed(2)),
        winRate: winRate,
        wins: wins,
        losses: losses,
        scratches: scratches,
        avgWinnerR: avgWinner,
        avgLoserR: avgLoser,
        profitFactor: profitFactor,
        comboStats: comboList,
        gradeStats: gradeMap,
        mistakeStats: mistakeMap
    }
}
