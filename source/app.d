module main;

import snake;

void main()
{
    version(NcursesFrontend) {
        import ncurses;

        new Game(60, 30, new Ncurses).run();
    }

    version(SDLFrontend) {
        import sdl;

        new Game(80, 60, new SDL).run();
    }
}
