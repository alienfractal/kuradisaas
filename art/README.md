# Art sources and unused exports

Keep editable Aseprite files, working images and unused exports here.
This directory is not included in Flutter's asset bundle.

Export images needed by the game to `../resources/images/`; the fighter,
scenario, menu and settings cache services load those runtime images.

The older nine-frame `jann_kick2_right_*` exports have been replaced in the
game by the front/high/very-high kick sheets. The alternate mosquito hit and
street/star exports here are also unused by the current game.

`moved-files.csv` records the original locations and SHA-256 hashes of files
moved here during this cleanup. Original GameMaker/CGA project folders remain
in their existing locations outside the Flutter project.
