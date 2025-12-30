import SwiftUI
import SwiftMusicNotation

struct ExportMenu: View {
    @ObservedObject var exportManager: ExportManager

    @State private var showingMusicXMLSettings = false
    @State private var showingImagePanel = false
    @State private var showingProgress = false

    var body: some View {
        Menu {
            // Quick Export Section
            Section("Quick Export") {
                Button {
                    Task { await quickExportMusicXML() }
                } label: {
                    Label("MusicXML", systemImage: "doc.text")
                }

                Button {
                    Task { await quickExportPDF() }
                } label: {
                    Label("PDF", systemImage: "doc.richtext")
                }

                Button {
                    Task { await quickExportPNG() }
                } label: {
                    Label("PNG Image", systemImage: "photo")
                }
            }

            Divider()

            // Advanced Export Section
            Section("Advanced") {
                Button {
                    showingMusicXMLSettings = true
                } label: {
                    Label("MusicXML Options...", systemImage: "gearshape")
                }

                Button {
                    showingImagePanel = true
                } label: {
                    Label("Image Options...", systemImage: "slider.horizontal.3")
                }
            }

            Divider()

            // Batch Export
            Section("Batch Export") {
                Button {
                    Task { await exportAllPagesPNG() }
                } label: {
                    Label("All Pages as PNG", systemImage: "square.stack")
                }

                Button {
                    Task { await exportAllPagesJPEG() }
                } label: {
                    Label("All Pages as JPEG", systemImage: "square.stack")
                }
            }

        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
        .disabled(exportManager.isExporting)
        .sheet(isPresented: $showingProgress) {
            ExportProgressView(exportManager: exportManager)
        }
    }

    // MARK: - Quick Export Actions

    private func quickExportMusicXML() async {
        showingProgress = true
        do {
            _ = try await exportManager.exportMusicXML()
        } catch {
            // Error handling
        }
        showingProgress = false
    }

    private func quickExportPDF() async {
        showingProgress = true
        do {
            _ = try await exportManager.exportPDF()
        } catch {
            // Error handling
        }
        showingProgress = false
    }

    private func quickExportPNG() async {
        do {
            _ = try exportManager.exportPNG()
        } catch {
            // Error handling
        }
    }

    private func exportAllPagesPNG() async {
        showingProgress = true
        do {
            _ = try await exportManager.exportAllPages(format: .png)
        } catch {
            // Error handling
        }
        showingProgress = false
    }

    private func exportAllPagesJPEG() async {
        showingProgress = true
        do {
            _ = try await exportManager.exportAllPages(format: .jpeg)
        } catch {
            // Error handling
        }
        showingProgress = false
    }
}

// MARK: - Progress View

struct ExportProgressView: View {
    @ObservedObject var exportManager: ExportManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Exporting...")
                .font(.headline)

            ProgressView(value: exportManager.progress)
                .progressViewStyle(.linear)

            Text(exportManager.currentOperation)
                .font(.caption)
                .foregroundColor(.secondary)

            if !exportManager.isExporting {
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(minWidth: 300)
    }
}
