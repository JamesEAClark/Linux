#!/bin/bash

# Check if the required tools are installed
if ! command -v ffmpeg &>/dev/null; then
    echo "Error: ffmpeg is not installed. Please install it."
    exit 1
fi

if ! command -v whisper &>/dev/null; then
    echo "Error: whisper is not installed. Please install it."
    exit 1
fi

# Input video file (change this to your video file's path)
input_video="$1"

# Extract audio using ffmpeg
audio_filename="${input_video%.*}.wav"
ffmpeg -i "$input_video" -vn -acodec pcm_s16le -ar 44100 -map 0:m:language:eng? -ac 2 "$audio_filename"

# Generate SRT subtitles using whisper
subtitle_filename="${input_video%.*}.srt"
whisper "$audio_filename" --model medium --output_format srt --language English
#whisper -i "$audio_filename" -o "$subtitle_filename"

# Clean up the extracted audio file
rm "$audio_filename"

echo "Subtitles generated and audio file cleaned up."
