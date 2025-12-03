const express = require('express');
const multer = require('multer');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3456;

// Create temp directory
const TEMP_DIR = path.join(__dirname, 'temp');
if (!fs.existsSync(TEMP_DIR)) {
  fs.mkdirSync(TEMP_DIR, { recursive: true });
}

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, TEMP_DIR),
  filename: (req, file, cb) => cb(null, `${uuidv4()}-${file.originalname}`)
});
const upload = multer({ storage });

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'n8n-ffmpeg' });
});

// Merge audio files endpoint - accepts any field name
app.post('/merge', upload.any(), async (req, res) => {
  const files = req.files;

  if (!files || files.length === 0) {
    return res.status(400).json({ error: 'No audio files provided' });
  }

  // Sort files by fieldname (audio_0, audio_1, etc.) to ensure correct order
  files.sort((a, b) => {
    const numA = parseInt(a.fieldname.replace(/\D/g, '') || '0');
    const numB = parseInt(b.fieldname.replace(/\D/g, '') || '0');
    return numA - numB;
  });

  console.log('Merging files:', files.map(f => f.fieldname));

  const sessionId = uuidv4();
  const listFile = path.join(TEMP_DIR, `${sessionId}-list.txt`);
  const outputFile = path.join(TEMP_DIR, `${sessionId}-merged.mp3`);

  try {
    // Create ffmpeg concat list file
    const fileList = files
      .map(f => `file '${f.path}'`)
      .join('\n');
    fs.writeFileSync(listFile, fileList);

    // Run ffmpeg to concatenate
    await new Promise((resolve, reject) => {
      exec(
        `ffmpeg -f concat -safe 0 -i "${listFile}" -c copy "${outputFile}"`,
        (error, stdout, stderr) => {
          if (error) {
            console.error('ffmpeg error:', stderr);
            reject(error);
          } else {
            resolve();
          }
        }
      );
    });

    // Send merged file
    res.setHeader('Content-Type', 'audio/mpeg');
    res.setHeader('Content-Disposition', 'attachment; filename="merged-podcast.mp3"');

    const readStream = fs.createReadStream(outputFile);
    readStream.pipe(res);

    // Cleanup after sending
    readStream.on('end', () => {
      cleanup(files, listFile, outputFile);
    });

  } catch (error) {
    console.error('Merge error:', error);
    cleanup(files, listFile, outputFile);
    res.status(500).json({ error: 'Failed to merge audio files', details: error.message });
  }
});

function cleanup(files, listFile, outputFile) {
  try {
    files.forEach(f => fs.existsSync(f.path) && fs.unlinkSync(f.path));
    fs.existsSync(listFile) && fs.unlinkSync(listFile);
    fs.existsSync(outputFile) && fs.unlinkSync(outputFile);
  } catch (e) {
    console.error('Cleanup error:', e);
  }
}

app.listen(PORT, () => {
  console.log(`n8n-ffmpeg server running on port ${PORT}`);
});
