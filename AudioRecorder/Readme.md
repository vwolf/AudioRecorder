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
    
#### Takes to iCloud
    - copy take to iCloud
        Copy take + metadata.json to iCloud (set ubquitios). Take is no longer in in App's Documents folder so remove from CoreData
        
    - remove take from iCloud
        reset ubquitios
        Set field in CoreData?
 
 #### Take from iCloud to App
    - copy take to app's documents directory
    
    - copy process is triggered through metadata request
    - show alert to confirm transfer 
    - take.cloudTakeToLocal()
    1. get TakeCKRecord and Take object
    2. fetch files from iCloud and copy to app's document directory
    3. when all files in app's document directory take.deleteTakeFromICloud() 
    4. use metadata.json to add instance CoreData record for take
    5. update TakeVC tableView
  
When take in iCloud, display take in Takes View?

Can be a take in iCloud and iCloudDrive?

What happens if a take gets, which is in iCloud, get's modified in app?
    - Update iCloud take? 
        
Takes to iDrive
    
#### Image to take
    - select image
    - copy image to take folder
    - save image name in metadata item
    - when loading into TakeVC metadata item load from take folder
    - when changing selected image then replace in take folder
