import AVFoundation

let session = AVAudioSession.sharedInstance()
do {
    try session.setCategory(.record, mode: .measurement, options: .duckOthers)
    print("setCategory success")
} catch {
    print("setCategory failed:", error)
}
