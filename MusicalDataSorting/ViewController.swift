import Cocoa
import AVFoundation

class ViewController: NSViewController {
	@IBOutlet weak var statusLabel: NSTextField!
	@IBOutlet weak var uploadButton: NSButton!
	
	let audioEngine = AVAudioEngine()
	let audioPlayer = AVAudioPlayerNode()
	
	@IBAction func startMusicPrompt(_ sender: NSButton) {
		let fileSelectionPanel = NSOpenPanel()
		fileSelectionPanel.canChooseFiles = true
		fileSelectionPanel.allowsMultipleSelection = false
		fileSelectionPanel.canChooseDirectories = false
		
		fileSelectionPanel.beginSheetModal(for: view.window!) { result in
			guard result == .OK else { return }
			
			self.playFile(at: fileSelectionPanel.urls[0])
		}
	}
	
	func playFile(at url: URL) {
		do {
			let audioFile = try AVAudioFile(forReading: url)
			let pieces = try audioFile.splitIntoPieces(count: 2)
			
			audioEngine.attach(audioPlayer)
			audioEngine.connect(audioPlayer, to: audioEngine.mainMixerNode, format: nil)
			
			try audioEngine.start()
			
			audioPlayer.scheduleFile(audioFile, at: nil)
			
			//for audioPiece in pieces {
			//	audioPlayer.scheduleBuffer(audioPiece)
			//}
			
			audioPlayer.play()
			
			statusLabel.stringValue = "Status - Successful"
		} catch {
			statusLabel.stringValue = "Status - Failed, try again"
			print(error.localizedDescription)
			
			let description = """
			Your computer is about to blow up!
			
			\(error.localizedDescription)
			
			This is most likely due to the file not being an audio file.
			"""
			
			let newError = NSError(domain: "" , code: 0, userInfo: [NSLocalizedDescriptionKey: description])
			NSAlert(error: newError).runModal()
		}
	}
	
	override func viewDidLoad() {
		// Do any additional setup after loading the view.
	}
}

extension AVAudioFile {
	func splitIntoPieces(count: Int) throws -> [AVAudioPCMBuffer] {
		let frameCount = Int(length)
		let splitFrameCount = frameCount / count + 1
		
		let sourceBuffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: .init(frameCount))!
		try read(into: sourceBuffer)
		let channelCount = Int(sourceBuffer.format.channelCount)
		
		return stride(from: 0, to: frameCount, by: splitFrameCount).map { startFrame -> AVAudioPCMBuffer in
			let splitBuffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: .init(splitFrameCount))!
			
			let sourceFrames = startFrame..<min(startFrame + splitFrameCount, frameCount)
			let targetFrames = stride(from: 0, to: splitFrameCount, by: sourceBuffer.stride)
			
			for channel in 0..<channelCount {
				for (sourceFrame, targetFrame) in zip(sourceFrames, targetFrames) {
					let sample = sourceBuffer.floatChannelData![channel][sourceFrame]
					splitBuffer.floatChannelData![channel][targetFrame] = sample
				}
			}
			
			return splitBuffer
		}
	}
}
