package main

import (
    "fmt"
    "time"

    "github.com/shirou/gopsutil/v3/net"
	"github.com/shirou/gopsutil/v3/battery"
)

const sep = "||"

// ============================================================================
//		NETWORK TRAFFIC
// ============================================================================

// Track previous values to calculate the delta
var prevRx uint64 = 0
var prevTx uint64 = 0

func netTraffic() string {
    ioCounters, err := net.IOCounters(false)
    if err != nil || len(ioCounters) == 0 {
        return "↓0B ↑0B " + sep
    }

    currentRx := ioCounters[0].BytesRecv
    currentTx := ioCounters[0].BytesSent

    // Calculate the difference since the last call
    rxDelta := currentRx - prevRx
    txDelta := currentTx - prevTx

    // Update previous values for the next interval
    prevRx = currentRx
    prevTx = currentTx

    return fmt.Sprintf("↓%4sB ↑%4sB %s", formatBytes(rxDelta), formatBytes(txDelta), sep)
}

func formatBytes(value uint64) string {
    if value > 1024*1024 {
        return fmt.Sprintf("%.1fM", float64(value)/1024/1024)
    }
    if value > 1024 {
        return fmt.Sprintf("%.1fK", float64(value)/1024)
    }
    return fmt.Sprintf("%d", value)
}

// ============================================================================
//		DATE/TIME
// ============================================================================

func dateTime() string {
    return fmt.Sprintf("%s %s", time.Now().Format("02/01/06 | 15:04"), sep)
}

// ============================================================================
//		BATTERY
// ============================================================================

func batteryStatus() string {
    batteries, err := battery.GetAll()
    if err != nil || len(batteries) == 0 {
        return "No Battery " + sep
    }

    bat := batteries[0] // Handle the first battery found
    chargeStatus := getChargeSymbol(bat.State)
    batteryPercent := fmt.Sprintf("%.0f", bat.Current/bat.Full*100)

    return fmt.Sprintf("%s %s%% %s", chargeStatus, batteryPercent, sep)
}

func getChargeSymbol(state battery.State) string {
    switch state {
    case battery.Charging:
        return "+"
    case battery.Discharging:
        return "-"
    case battery.Full:
        return "="
    default:
        return "?"
    }
}

// ============================================================================
//		MAIN
// ============================================================================

func updateStatus(shortContent, longContent string) {
    fmt.Printf("%s %s\n", shortContent, longContent)

	// For using with DWM directly; otherwise pipe stdout to xsetroot:
    // exec.Command("xsetroot", "-name", fmt.Sprintf("%s %s", shortContent, longContent)).Run()
}

func main() {
    shortTicker := time.NewTicker(1 * time.Second)
    longTicker := time.NewTicker(20 * time.Second)
    defer shortTicker.Stop()
    defer longTicker.Stop()

    var shortContent, longContent string

    for {
        select {
        case <-shortTicker.C:
            shortContent = netTraffic()
        case <-longTicker.C:
            longContent = fmt.Sprintf("%s %s", dateTime(), "Battery Status")
        }
        updateStatus(shortContent, longContent)
        time.Sleep(800 * time.Millisecond)
    }
}

