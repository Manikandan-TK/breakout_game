import os
import requests
from pathlib import Path

def download_file(url, filename):
    print(f"Downloading {filename}...")
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        with open(filename, 'wb') as f:
            f.write(response.content)
        print(f"Successfully downloaded {filename}")
    except Exception as e:
        print(f"Failed to download {filename}: {str(e)}")

def main():
    # Create audio directory if it doesn't exist
    audio_dir = Path("../assets/audio")
    audio_dir.mkdir(parents=True, exist_ok=True)
    
    # Sound effects from GitHub repositories with open-source game assets
    sound_files = {
        "hit.wav": "https://raw.githubusercontent.com/photonstorm/phaser-examples/master/examples/assets/audio/SoundEffects/alien_death1.wav",
        "break.wav": "https://raw.githubusercontent.com/photonstorm/phaser-examples/master/examples/assets/audio/SoundEffects/squit.wav",
        "powerup.wav": "https://raw.githubusercontent.com/photonstorm/phaser-examples/master/examples/assets/audio/SoundEffects/key.wav",
        "game_over.wav": "https://raw.githubusercontent.com/photonstorm/phaser-examples/master/examples/assets/audio/SoundEffects/squit.wav",
        "background.mp3": "https://raw.githubusercontent.com/photonstorm/phaser-examples/master/examples/assets/audio/oedipus_wizball_highscore.mp3"
    }
    
    # Download each sound file
    for filename, url in sound_files.items():
        filepath = audio_dir / filename
        download_file(url, filepath)

if __name__ == "__main__":
    main()
