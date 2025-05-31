from telethon import TelegramClient
import sys
import os
# Define your API ID, Hash, and phone number
api_id =         # Replace with your API ID
api_hash = ''    # Replace with your API Hash
bot_token = ''  # Your Telegram phone number
chat_id = 
# Create the Telegram client
client = TelegramClient('bot_session', api_id, api_hash).start(bot_token=bot_token)
async def progress_callback(current, total):
    # Print progress percentage and the number of bytes uploaded
    print(f'Uploaded {current} out of {total} bytes ({current / total:.2%})')
async def send_large_file(file_path, chat_id):
    await client.send_file(chat_id, file_path, progress_callback = progress_callback)
    print("File sent successfully!")



# Run the client and send the file
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 send_large_file.py <file_path>")
        sys.exit(1)

    file_path = sys.argv[1]

    # Check if the file exists
    if not os.path.isfile(file_path):
        print(f"❌ File not found: {file_path}")
        sys.exit(1)

    # Run the send function
    with client:
        client.loop.run_until_complete(send_large_file(file_path, chat_id))




