import Foundation
import Testing
@testable import DaytrackCore

@Suite struct CSVExportTests {
    @Test func csvWritesSkipDistinctFromBlank() {
        let lines = CSVExport.csv(sampleRecord()).split(separator: "\n", omittingEmptySubsequences: false)
        #expect(lines[1] == "date,Sleep,Anxiety,Meds taken")
        #expect(lines[2] == "2027-07-02,7,skip,")
        #expect(lines[3] == "2027-07-03,,7.5,10")
        #expect(lines.count == 5 && lines[4].isEmpty)
    }

    @Test func csvHeaderSaysLossy() {
        let first = CSVExport.csv(Record()).split(separator: "\n").first.map(String.init)
        #expect(first == CSVExport.lossyNote)
        #expect(first?.hasPrefix("#") == true)
        #expect(first?.contains("lossy") == true)
    }

    @Test func csvQuotesNamesWithCommas() {
        let t = Tracker(name: "Pain, \"left\"", symbol: "bandage", type: .numeric, createdAt: DayKey("2027-07-01")!)
        #expect(CSVExport.csv(Record(trackers: [t])).contains("date,\"Pain, \"\"left\"\"\""))
    }

    @Test func csvNeutralisesFormulaLeadingNames() {
        let t = Tracker(name: "=SUM(1)", symbol: "bandage", type: .numeric, createdAt: DayKey("2027-07-01")!)
        let csv = CSVExport.csv(Record(trackers: [t]))
        #expect(csv.contains("date,'=SUM(1)"))
        #expect(!csv.contains(",=SUM(1)"))
    }

    @Test func csvQuotesCRLFAndSpacedFormulas() {
        let a = Tracker(name: "a\r\nb", symbol: "bandage", type: .numeric, createdAt: DayKey("2027-07-01")!)
        let b = Tracker(name: " =1+1", symbol: "bandage", type: .numeric, createdAt: DayKey("2027-07-01")!)
        let csv = CSVExport.csv(Record(trackers: [a, b]))
        #expect(csv.contains("date,\"a\r\nb\",' =1+1"))
    }
}
