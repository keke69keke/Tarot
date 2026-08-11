import SwiftUI
import AVFoundation

public struct MysticMusicPlayerBar: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTrack: String = "Cuencos Tibetanos"
    @State private var showMusicPicker = false

    public init() {}

    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    showMusicPicker = true
                }) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Text(currentTrack)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                Button(action: {
                    if isPlaying {
                        audioPlayer?.pause()
                    } else {
                        playSound(named: currentTrack)
                    }
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.38))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .sheet(isPresented: $showMusicPicker) {
            MusicPickerView(selectedTrack: $currentTrack, onSelect: { track in
                currentTrack = track
                playSound(named: track)
                isPlaying = true
            })
        }
        .onAppear {
            playSound(named: currentTrack)
        }
    }

    private func playSound(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("No se encontró el archivo de audio: \(name)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Error al reproducir el audio: \(error.localizedDescription)")
        }
    }
}

struct MusicPickerView: View {
    @Binding var selectedTrack: String
    var onSelect: (String) -> Void

    let tracks = [
        "Cuencos Tibetanos",
        "Frecuencia 432Hz",
        "Frecuencia 528Hz",
        "Sonidos de la Naturaleza",
        "Música de Meditación"
    ]

    var body: some View {
        NavigationView {
            List(tracks, id: \.self) { track in
                Button(action: {
                    selectedTrack = track
                    onSelect(track)
                }) {
                    HStack {
                        Text(track)
                        Spacer()
                        if selectedTrack == track {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Seleccionar Música")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        // Cerrar la hoja
                    }
                }
            }
            #endif
        }
    }
}
