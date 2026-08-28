import SwiftUI
import TarotCore
import LocalAuthentication
import AVFoundation

public struct SecretVaultView: View {
    @StateObject private var vaultManager = SecretVaultManager()
    @State private var pinInput: String = ""
    @State private var pinError: String? = nil
    @State private var showingImagePicker = false
    @State private var showingVideoPicker = false
    @State private var showingAudioRecorder = false
    @State private var showingAddSheet = false
    @State private var showingChangePIN = false
    @State private var selectedImageData: Data? = nil
    @State private var selectedVideoURL: URL? = nil
    @State private var newTitle: String = ""
    @State private var newNotes: String = ""
    @State private var oldPIN = ""
    @State private var newPIN = ""
    @State private var changePINError: String? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.tarotBackground.ignoresSafeArea()
                
                if !vaultManager.isUnlocked {
                    pinKeypadView
                } else {
                    unlockedVaultContent
                }
            }
            .navigationTitle("Bóveda Secreta")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if vaultManager.isUnlocked {
                    ToolbarItem(placement: .automatic) {
                        Menu {
                            Button { showingChangePIN = true } label: { Label("Cambiar código", systemImage: "key.fill") }
                            Button { vaultManager.biometricEnabled.toggle() } label: { Label(vaultManager.biometricEnabled ? "Desactivar \(vaultManager.biometricTypeName)" : "Activar \(vaultManager.biometricTypeName)", systemImage: vaultManager.biometricTypeName == "Face ID" ? "faceid" : "touchid") }
                            Button(role: .destructive) { vaultManager.lock() } label: { Label("Bloquear", systemImage: "lock.fill") }
                        } label: {
                            Image(systemName: "ellipsis.circle").foregroundStyle(Color.tarotGold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                addEntrySheet
            }
            .sheet(isPresented: $showingChangePIN) { changePINSheet }
            #if os(iOS)
            .sheet(isPresented: $showingVideoPicker) {
                VideoCapturePicker(videoURL: $selectedVideoURL, onVideoPicked: { url in
                    self.selectedVideoURL = url
                    self.showingAddSheet = true
                })
            }
            .sheet(isPresented: $showingAudioRecorder) {
                AudioRecorderSheet { data, duration in
                    _ = vaultManager.saveAudio(data: data, title: "Audio \(Date().formatted(date: .abbreviated, time: .omitted))", notes: "", duration: duration)
                }
            }
            #endif
        }
    }
    
    // MARK: - PIN Keypad View
    private var pinKeypadView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield")
                .font(.system(size: 54, weight: .thin))
                .foregroundStyle(Color.tarotGold)
                .padding(.bottom, 8)
            
            Text(vaultManager.hasPINSet ? "Introduce tu Código PIN" : "Crea tu Código PIN Secreto")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(Color.tarotIvory)
            
            HStack(spacing: 16) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index < pinInput.count ? Color.tarotGold : Color.tarotPanel)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.tarotGold, lineWidth: 1))
                }
            }
            .padding(.vertical, 12)
            
            if let error = pinError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if vaultManager.hasPINSet && vaultManager.canUseBiometrics() {
                Button {
                    Task { _ = await vaultManager.authenticateWithBiometrics() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: vaultManager.biometricTypeName == "Face ID" ? "faceid" : "touchid")
                        Text("Desbloquear con \(vaultManager.biometricTypeName)")
                            .font(.system(size: 13, weight: .semibold, design: .serif))
                    }
                    .foregroundStyle(Color.tarotGold)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color.tarotGold.opacity(0.12)))
                    .overlay(Capsule().stroke(Color.tarotGold.opacity(0.22), lineWidth: 0.7))
                }
                .buttonStyle(.plain)
                Toggle(isOn: Binding(get: { vaultManager.biometricEnabled }, set: { vaultManager.biometricEnabled = $0 })) {
                    Text("Activar \(vaultManager.biometricTypeName)")
                        .font(.system(size: 11, design: .serif))
                        .foregroundStyle(Color.tarotIvory.opacity(0.6))
                }.tint(Color.tarotGold).padding(.horizontal, 32).padding(.top, 4)
            }
            
            // Keypad 1-9 & 0
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(72), spacing: 20), count: 3), spacing: 16) {
                ForEach(1...9, id: \.self) { digit in
                    keypadButton(number: "\(digit)")
                }
                
                Button(action: {
                    if !pinInput.isEmpty { pinInput.removeLast() }
                }) {
                    Image(systemName: "delete.left")
                        .font(.title2.weight(.light))
                        .frame(width: 72, height: 72)
                        .foregroundStyle(Color.tarotIvory.opacity(0.80))
                        .luxuryGlass(cornerRadius: 36)
                }
                
                keypadButton(number: "0")
                
                Spacer()
            }
            .padding(.top, 12)
        }
        .padding()
    }
    
    private func keypadButton(number: String) -> some View {
        Button {
            TarotAudioService.shared.playCardSelect()
            if pinInput.count < 4 {
                pinInput.append(number)
                if pinInput.count == 4 {
                    verifyPIN()
                }
            }
        } label: {
            Text(number)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .frame(width: 72, height: 72)
                .foregroundStyle(Color.tarotGold)
                .luxuryGlass(cornerRadius: 36)
        }
    }
    
    private func verifyPIN() {
        if vaultManager.unlock(with: pinInput) {
            pinInput = ""
            pinError = nil
        } else {
            pinError = "Código PIN incorrecto. Inténtalo de nuevo."
            pinInput = ""
        }
    }
    
    // MARK: - Unlocked Vault Content
    private var unlockedVaultContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tiradas Físicas Guardadas")
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundStyle(Color.tarotGold)
                        Text("Fotos privadas y notas confidenciales de tus lecturas")
                            .font(.caption)
                            .foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button { showingImagePicker = true } label: {
                            HStack(spacing: 6) { Image(systemName: "camera"); Text("Foto") }
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color.tarotGold).foregroundStyle(.black).cornerRadius(10)
                        }
                        Button { showingVideoPicker = true } label: {
                            HStack(spacing: 6) { Image(systemName: "video"); Text("Video") }
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color.tarotGold.opacity(0.85)).foregroundStyle(.black).cornerRadius(10)
                        }
                        Button { showingAudioRecorder = true } label: {
                            HStack(spacing: 6) { Image(systemName: "mic"); Text("Audio") }
                                .font(.system(size: 12, weight: .bold, design: .serif))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color.white.opacity(0.08)).foregroundStyle(Color.tarotGold)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.tarotGold.opacity(0.22), lineWidth: 0.7))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                
                if vaultManager.entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.tarotGold.opacity(0.6))
                        Text("No tienes lecturas secretas registradas.")
                            .font(.subheadline)
                            .foregroundStyle(Color.tarotIvory.opacity(0.58))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                        ForEach(vaultManager.entries) { entry in
                            vaultCardView(entry: entry)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        #if os(iOS)
        .sheet(isPresented: $showingImagePicker) {
            PhotoCapturePicker(imageData: $selectedImageData, onImagePicked: { data in
                self.selectedImageData = data
                self.showingAddSheet = true
            })
        }
        #endif
    }
    
    private func vaultCardView(entry: SecretVaultEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if entry.mediaType == .photo {
                        AsyncImage(url: vaultManager.getImageURL(for: entry)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill).frame(height: 160).clipped().cornerRadius(12)
                            } else {
                                Rectangle().fill(Color.tarotPanel).frame(height: 160).cornerRadius(12).overlay(Image(systemName: "photo").foregroundStyle(Color.tarotIvory.opacity(0.58)))
                            }
                        }
                    } else if entry.mediaType == .video {
                        Rectangle().fill(Color.tarotPanel).frame(height: 160).cornerRadius(12)
                            .overlay(VStack(spacing: 6) { Image(systemName: "video").font(.system(size: 28)).foregroundStyle(Color.tarotGold); Text("Video").font(.caption2).foregroundStyle(Color.tarotIvory.opacity(0.6)) })
                    } else {
                        Rectangle().fill(Color.tarotPanel).frame(height: 160).cornerRadius(12)
                            .overlay(VStack(spacing: 6) { Image(systemName: "waveform").font(.system(size: 28)).foregroundStyle(Color.tarotGold); if let d = entry.duration { Text(String(format: "%.0fs", d)).font(.caption2).foregroundStyle(Color.tarotIvory.opacity(0.6)) } })
                    }
                }
                HStack(spacing: 4) {
                    Image(systemName: entry.mediaType == .photo ? "camera" : entry.mediaType == .video ? "video" : "mic")
                        .font(.system(size: 9, weight: .bold))
                    Text(entry.mediaType == .photo ? "FOTO" : entry.mediaType == .video ? "VIDEO" : "AUDIO")
                        .font(.system(size: 8, weight: .black, design: .rounded)).tracking(0.6)
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 6).padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.55)))
                .padding(8)
            }
            
            Text(entry.title)
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(Color.tarotIvory)
            
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(Color.tarotIvory.opacity(0.58))
            }
            
            Text(entry.dateAdded.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(Color.tarotGold.opacity(0.8))
        }
        .padding(10)
        .background(Color.tarotPanel)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.tarotBorder, lineWidth: 1))
        .contextMenu {
            Button(role: .destructive) {
                vaultManager.deleteEntry(entry)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Add Entry Sheet
    private var addEntrySheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detalles de la Lectura")) {
                    TextField("Título de la lectura", text: $newTitle)
                    TextField("Notas secretas o interpretación...", text: $newNotes, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle("Nueva Lectura Secreta")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showingAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if let data = selectedImageData {
                            _ = vaultManager.savePhoto(data: data, title: newTitle, notes: newNotes)
                        } else if let url = selectedVideoURL {
                            _ = vaultManager.saveVideo(from: url, title: newTitle, notes: newNotes)
                        }
                        newTitle = ""; newNotes = ""; selectedImageData = nil; selectedVideoURL = nil
                        showingAddSheet = false
                    }
                    .disabled((selectedImageData == nil && selectedVideoURL == nil) && newTitle.isEmpty && newNotes.isEmpty)
                }
            }
        }
    }

    private var changePINSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Cambiar código")) {
                    SecureField("Código actual (4 dígitos)", text: $oldPIN)
                    SecureField("Nuevo código (4 dígitos)", text: $newPIN)
                    if let err = changePINError { Text(err).font(.caption).foregroundStyle(.red) }
                }
                Section {
                    HStack {
                        Image(systemName: vaultManager.biometricTypeName == "Face ID" ? "faceid" : "touchid").foregroundStyle(Color.tarotGold)
                        Toggle("Usar \(vaultManager.biometricTypeName)", isOn: Binding(get: { vaultManager.biometricEnabled }, set: { vaultManager.biometricEnabled = $0 }))
                            .tint(Color.tarotGold)
                    }
                }
            }
            .navigationTitle("Cambiar código")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showingChangePIN = false; oldPIN=""; newPIN=""; changePINError=nil } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if vaultManager.changePIN(oldPIN: oldPIN, newPIN: newPIN) {
                            showingChangePIN=false; oldPIN=""; newPIN=""; changePINError=nil
                        } else {
                            changePINError = "Código actual incorrecto o nuevo inválido (4 dígitos)"
                        }
                    }.disabled(newPIN.count != 4 || oldPIN.count != 4)
                }
            }
        }
    }
}

// MARK: - Photo Capture Picker Wrapper
#if os(iOS)
import PhotosUI
import UniformTypeIdentifiers

private struct VideoCapturePicker: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
    let onVideoPicked: (URL) -> Void
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.delegate = context.coordinator
        p.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        p.mediaTypes = [UTType.movie.identifier]
        p.videoQuality = .typeMedium
        return p
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoCapturePicker
        init(_ parent: VideoCapturePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.mediaURL] as? URL {
                parent.videoURL = url
                parent.onVideoPicked(url)
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}

private struct AudioRecorderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Data, Double) -> Void
    @StateObject private var recorder = AudioRecorder()
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: recorder.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 72)).foregroundStyle(Color.tarotGold)
                    .scaleEffect(recorder.isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: recorder.isRecording)
                Text(recorder.isRecording ? String(format: "%.0fs", recorder.elapsed) : "Listo para grabar")
                    .font(.system(size: 14, weight: .semibold, design: .serif)).foregroundStyle(Color.tarotIvory)
                HStack(spacing: 16) {
                    Button(recorder.isRecording ? "Detener" : "Grabar") {
                        if recorder.isRecording { recorder.stop() } else { try? recorder.start() }
                    }
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Capsule().fill(recorder.isRecording ? Color.red.opacity(0.85) : Color.tarotGold))
                    .foregroundStyle(.white)
                    if let url = recorder.fileURL, !recorder.isRecording, FileManager.default.fileExists(atPath: url.path) {
                        Button("Guardar") {
                            if let data = try? Data(contentsOf: url) {
                                onSave(data, recorder.elapsed)
                            }
                            dismiss()
                        }
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(Capsule().fill(Color.tarotGoldGradient))
                        .foregroundStyle(Color.black)
                    }
                }
            }
            .padding().frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.tarotBackground)
            .navigationTitle("Grabar Audio").toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } } }
        }
    }
}

@MainActor
private final class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var elapsed: Double = 0
    @Published var fileURL: URL?
    private var recorder: AVAudioRecorder?
    private var tickTask: Task<Void, Never>?
    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default)
        try session.setActive(true)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        fileURL = url
        let settings: [String: Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
        isRecording = true
        elapsed = 0
        tickTask = Task { @MainActor in
            while isRecording {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard isRecording else { break }
                elapsed += 1
            }
        }
    }
    func stop() {
        recorder?.stop(); isRecording = false; tickTask?.cancel(); tickTask = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

private struct PhotoCapturePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    let onImagePicked: (Data) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoCapturePicker
        init(_ parent: PhotoCapturePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.8) {
                parent.imageData = data
                parent.onImagePicked(data)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif
