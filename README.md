This is an enhanced drop in replacement for the `mpd` applet from 

https://github.com/adi1090x/rofi

To quote (and echo) their sentiment:

> The purpose of this repository is to provide you a complete (almost) reference. So by using the files as reference, You can theme rofi by yourself.

This does not alter or change any existing parts of that installation; it builds on it instead. The only file that conflicts is `mpd.sh` itself, and we are copying that to `mpd_original.sh`, so that it can be a straight-up drop-in replacement.

I've incorporated a lot of my older work into here; for example, if you use `yadshow` from [this repository of mine](https://github.com/uriel1998/yolo-mpd), the cache directory structure is the same, so you can use a symlink between `${XDG_CACHE_HOME}/rofi` and `${XDG_CACHE_HOME}/yadshow` and have it work just fine.

## What's new/enhanced?

* Cover art in display, with fallback to original images
* Goes back to the main window after executing a command (use ESC to close)
* Title, album, and track visible
* Consume added as a toggleable button
* Outputs added as a toggleable button
* Local playing of MPD streamed output
* Info window with lyrics (if present; default lyrics file included)
* Tools button showing various tools you can use, including invoking `puddletag` 
on the currently playing track, removing duplicates from the current playqueue, 
and replacing the queue with the currently playing artist, album, or genre.

## Things you'll need

* By default this invokes `puddletag` for tagging and `play` for the stream.

## Installation

* Follow the installation directions for [https://github.com/adi1090x/rofi](https://github.com/adi1090x/rofi)
* Clone this repository, and change to its directory.
* Copy the relevant files:

```
cp -f "$HOME/.config/rofi/applets/bin/mpd.sh" "$HOME/.config/rofi/applets/bin/mpd_original.sh"
cp -f ./mpd.sh "$HOME/.config/rofi/applets/bin"
cp -f ./edit_current_mp3tags.sh "$HOME/.config/rofi/applets/bin"
cp ./style-4.rasi "$HOME/.config/rofi/applets/type-5"
cp ./style-5.rasi "$HOME/.config/rofi/applets/type-5"
cp ./style-6.rasi "$HOME/.config/rofi/applets/type-5"
cp ./default_lyrics.md "$HOME/.config/rofi/applets/shared"
```

## Configuration

Add to your `.bashrc` (if it does not already exist):

`export MPD_HOST=PASSWORD@HOST`

I run snapserver on a second output named `my_pipe`.  Alter `OUTPUT_NAME` at the 
top of the script to match the name of the output you wish to toggle.

The radio controls a *local* player (literally `play` though I've used `mplayer` 
before) playing a stream from my MPD server.  Alter `STREAMURL` at the top of the 
script to add the url of your stream.

If your MPD music base is *not* "${HOME}/Music", change it at the top of the script.

If you'd rather not alter the script, you can also define these variables in your .bashrc if you like, e.g.:


```
export STREAMURL="https://example.com/mpd.mp3"
export OUTPUT_NAME="second_output" 
export MPD_MUSIC_BASE="/home/USERNAME/Music"
```

*Note* Technically you do not have to export them, it's a simple grep match, not 
reading of environment variables. I export them because I use the same things among 
different scripts.
