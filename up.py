from pyrogram import *
import time
import sys

filename = sys.argv[1]

def progress(current, total):
    percent = (current / total) * 100
    green_hashes = '❄' * int(percent / 2)
    spaces = ' ' * (50 - int(percent / 2))
    
    # ANSI escape code for green color
    green_color_code = '\033[92m'
    reset_color_code = '\033[0m'
    
    sys.stdout.write(f"\rProgress: [{int(percent)}%] [{green_color_code}{green_hashes}{reset_color_code}{spaces}] ({current/1000000:.2f}/{total/1000000:.2f} MB)")
    sys.stdout.flush()

bot = Client(
    "my project",
    api_id=,
    api_hash="",
    bot_token=""
)

print("Uploading...")

with bot:
    bot.send_document(
        chat_id=5115463777,
        document=filename,
        progress=progress
    )

print("\nUpload complete.")
