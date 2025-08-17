# FuldFokusEmotes

FuldFokusEmotes is a lightweight extension for [Twitch Emotes v2](https://www.curseforge.com/wow/addons/twitch-emotes-v2).  
It adds custom emotes used by the guild **FuldFokus** on EU–Draenor, seamlessly integrating them into the existing TwitchEmotes framework.

Maintained by [Eraxter](https://github.com/EraxterCodes).  
All credit for the original addon goes to **Ren – Illidan (US)** and **Jons – MirageRaceway (EU)**.  
This addon simply injects additional emotes into their system.

---

## 📦 Features

- Adds unique **FuldFokus guild emotes** alongside existing Twitch/Discord emotes.
- Full integration with:
  - **Chat replacement**: type `:EmoteName:` and see it render.
  - **Dropdown menu**: emotes appear under a new `FuldFokus` category.
  - **Autocomplete**: start typing `:Em...` and suggestions like `:EmilOk:` will show.
- Completely non-invasive: does not override or modify Twitch Emotes v2, only appends.

---

## 🛠️ Installation

### Option 1:
1. Download the latest release from the [Releases page](https://github.com/EraxterCodes/FuldFokusEmotes/releases).
2. Extract the `.zip` into your WoW `_retail_/Interface/AddOns/` folder.
3. Make sure [Twitch Emotes v2](https://www.curseforge.com/wow/addons/twitch-emotes-v2) is installed and enabled.
4. Enable **FuldFokusEmotes** from the AddOn list in-game.

### Option 2: Install via WowUp
1. Open [WowUp](https://wowup.io/).
2. Go to the **Get Addons** tab.
3. Click **Install from URL**.
4. Paste the repository URL: https://github.com/EraxterCodes/FuldFokusEmotes
5. Click **Install**. WowUp will fetch the addon and place it in the correct folder automatically.

## Contributing

This addon is not meant as a replacement or circumvention of the original **Twitch Emotes v2**. It only exists to provide custom emotes for members of **FuldFokus**. If you would like to see more global emotes added, please consider reaching out to the original authors — this project is only possible thanks to their excellent work.  

For members of **FuldFokus** who want to add guild-specific emotes, there are two ways to contribute:

### Option 1: Pull Request
1. Place the new `.tga` file in `Emotes/FuldFokus/`.  
   - The image **must** use dimensions that are powers of 2 (e.g. `64x64`, `128x128`).  
2. Open `FuldFokusEmotes.lua` and add the emote name to the local `EMOTES` list.  
3. Submit a Pull Request on GitHub.  

### Option 2: Discord Submission
Send me a DM on Discord with the image you’d like added.  
- Remember: the file **must** have pixel dimensions that are powers of 2 (e.g. `64x64`, `128x128`).  
