import Foundation

/// A spreadsheet view of the record. Export only: it cannot be restored (Q2, [O2]).
public enum CSVExport {
    public static let lossyNote = "# Daytrack CSV is lossy: it leaves out notes, wording revisions, archive ranges and write times. Only a full copy (JSON) can be restored."

    /// One row per written day, one column per tracker. A skip reads `skip`; a blank cell is empty.
    public static func csv(_ record: Record) -> String {
        let header = (["date"] + record.trackers.map(\.name)).map(field).joined(separator: ",")
        let rows = record.entries.values.sorted { $0.date < $1.date }.map { entry in
            ([entry.date.isoString] + record.trackers.map { cell(entry.values[$0.id]) }).joined(separator: ",")
        }
        return ([lossyNote, header] + rows).joined(separator: "\n") + "\n"
    }

    private static func cell(_ value: DayValue?) -> String {
        switch value {
        case nil: ""
        case .skip: "skip"
        case .set(let n): n == n.rounded() ? String(Int(n)) : String(n)
        }
    }

    private static func field(_ raw: String) -> String {
        // A leading =, +, -, @, tab or CR makes spreadsheets evaluate the cell as a formula.
        let s = raw.first.map({ "=+-@\t\r".contains($0) }) == true ? "'" + raw : raw
        guard s.contains(where: { ",\"\n\r".contains($0) }) else { return s }
        return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
