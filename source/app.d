module main;

import snake;
import toml;

void main()
{
    import std.file : read, FileException;

    TOMLDocument config;
    try
        config = parseTOML(cast(string) read("./config.toml"));
    catch (FileException _)
        new Game().start();

    new Game(cast(uint) config["size"].integer, cast(DifficultyLevel) config["difficulty"].integer).start();
}
