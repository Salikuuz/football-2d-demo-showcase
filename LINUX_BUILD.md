# Linux build

The Windows `.exe` is not a Linux game build. Export the `Linux` preset as
`game/linux/Theodoreball.x86_64`.

Before exporting, open **Editor > Manage Export Templates** in Godot 4.7.1
and install the Linux x86_64 debug and release templates. This computer
currently has only the Windows templates installed.

Keep these files together when sending the build:

- `Theodoreball.x86_64`
- `Theodoreball.pck`
- `steam_appid.txt`
- the exported `libgodotsteam.linux.template_release.x86_64.so`
- the exported `libsteam_api.so`

Copy `steam_appid.txt` from the project root next to the Linux executable.
Do not substitute the Windows `.dll` files for either `.so` file.

On the Linux computer:

```bash
chmod +x Theodoreball.x86_64
steam steam://install/480
./Theodoreball.x86_64 --verbose >theodoreball.log 2>&1
```

Steam must be open under the same Linux user before launching Steam mode.
The game uses Steam App ID `480` (Spacewar) for development, so Steam showing
Spacewar is expected until the project receives its own Steam App ID.
