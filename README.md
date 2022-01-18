# haxound

Music library on the commandline and filesystem.

## Install

For just the player, put the executable on your path:

```
wget https://raw.githubusercontent.com/edemko/haxplay/master/src/play.py -O ~/bin/haxplay
```

For the other utilities, I recommend cloning the repository.
They are slap-dash, and you may need to edit the logic to your taste.

## Player

`haxplay [-r | --repeat] [-s | --shuffle] <files>`

It plays the files you send it, and then is done.
If you pass `-r`, it repeats all. If you pass `-s` it shuffles the list each time through.
Send a keyboard interrupt (ctrl+c) to kill it.

It'd be nice to have play/pause built-in.
Perhaps a few features for looking at the current state.
Maybe even adding/removing/reordering tracks.
All of that requires concurrency, though.

Underneath the hood, it just calls `ffplay -nodisp -autoexit <file>`, and waits for the process to finish.


## Library Organization

The idea is to have a folder containing the actual music files.
Then, create additional folders for various different organizations, all filled with symbolic links.

To do this, some scripts are provided that coordinate `id3tool` or `mp3info` and `ln`, `mkdir,` &c.

Make a directory for the top level of your music browser;
let's call that `<root>`.
Create a symlink at `<root>/_main_` which should point to a directory tree with all your music.
You are now ready to index your music files in various ways.

### Navigation

Create a folder `<root>/genre-artist-album`, then index.
The directory tree here will look like `<root>/genre-artist-album/<genre>/<artist>/<album>/<track> - <title>`.
The ID3 tags are extracted by `id3tool` or `mp3info`,
    and the final track is merely a symlink to the actual track back through `root/_main_`.

You can do the same with similar dash-separated combinations of ID3 tags.
At the moment, supported tags are:
    
    * none, b/c I haven't written this thing yet

### Playlists

Make the directory `<root>/playlists`.
When you want a new playlist, make a folder for it under there.
Add tracks to a playlist using symlinks which have (zero-padded) integer names.

TODO: I suppose it'd be nice to have a utility to move tracks up/down to a playlist, but for now I'll just do it manually.

### Smart Playlists

If there's an executable `_make_` under a playlist, execute it.
It should re-populate that playlist.
Presumably the script should just look through your library and sift for files that match some criterion you like.
