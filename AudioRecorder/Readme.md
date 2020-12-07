According to Apple's Linear PCM Format Settings, if you want to record uncompressed PCM in a WAV format, you need to set only BitDepth through AVLinearPCMBitDepthKey and not BitRate through AVEncoderBitRateKey. 

Basically, the quality of a PCM stream is represented by two attributes: Sample Rate and Bit Depth.

The connection between Bit Rate and Bit Depth in PCM digital signal, is given by the following formula:

Samplerate sample/seconds * bitDepth bits/samples * channels = bit rate

Sample Rate is the number of samples per time unit, usually per second. A sample is a measurement of signal amplitude and it contains the information of the amplitude value of the signal waveform over a period of time (usually a second), and usually measured in sample per second units.

Bit Depth is the number of bits of information in each sample, in bits per sample units.

Bit Rate is the number of bits (data) per unit of time, usually per second. It refers to the audio quality of the stream. It is measured in bits per second or Kilobitspersec (kbps), but again, this is less relevant for a PCM stream.

Example
So, as in your example, if you record 16000 samples/second in 16-bit depth and 1 channel, then minimal Bit Rate calculation would be 256,000 bits/second to accommodate the flow of information in a PCM stream.

16000 / 1 * 16 / 1 * 1 = 254000

presets.append(["name": "high", "type": "wav", "bitDepth": 24 as Int16, "sampleRate": 48.000, "channels": 1 as Int16])
presets.append(["name": "middle", "type": "wav", "bitDepth": 16 as Int16, "sampleRate": 41.100, "channels": 1 as Int16])
presets.append(["name": "low", "type": "wav", "bitDepth": 16 as Int16, "sampleRate": 22.050, "channels": 1 as Int16])

41.100 * 16 =  

Format to save?
Take, metadata.json, note and image in one folder?

CloudDrive 

Share data with Airdrop and CloudDrive
    Files are copied to CloudDrive 
    
Share data with Cloudkit 
    Files are moved to CloudDrive - UbiquitousContainer
    
Takes to iCloud
    - copy take to iCloud
        Copy take to iCloud, leave take in App's Documents folder, leave CoreData record of take
        Set field in CoreData?
    - remove take from iCloud
        Delete take in iCloud
        Set field in CoreData?
        
When take in iCloud, display take in Takes View?

Can be a take in iCloud and iCloudDrive?

What happens if a take gets, which is in iCloud, get's modified in app?
    - Update iCloud take? 
        
Takes to iDrive
    
        
