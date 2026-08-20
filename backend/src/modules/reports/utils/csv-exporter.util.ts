export class CsvExporterUtil {
  /**
   * Sanitizes a cell value to prevent CSV Formula Injection / CSV Injection attacks.
   * Prepends a single quote if the field begins with =, +, -, @, \t, or \r.
   */
  static sanitizeCell(value: any): string {
    if (value === null || value === undefined) {
      return '""';
    }

    let stringValue = String(value);

    // Check for formula injection triggers
    const dangerousPrefixes = ["=", "+", "-", "@", "\t", "\r"];
    if (dangerousPrefixes.some((prefix) => stringValue.startsWith(prefix))) {
      stringValue = `'${stringValue}`;
    }

    // Escape double quotes by doubling them
    const escaped = stringValue.replace(/"/g, '""');
    return `"${escaped}"`;
  }

  /**
   * Generates a complete CSV string from headers and rows with formula injection protection.
   */
  static generateCsv(
    headers: { key: string; label: string }[],
    rows: Record<string, any>[],
  ): string {
    const headerRow = headers.map((h) => this.sanitizeCell(h.label)).join(",");
    const bodyRows = rows.map((row) =>
      headers.map((header) => this.sanitizeCell(row[header.key])).join(","),
    );

    return [headerRow, ...bodyRows].join("\r\n");
  }
}
