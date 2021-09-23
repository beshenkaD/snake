module ncurses;

version (NcursesFrontend)
{
    import snake;

    class Ncurses : Game.IO
    {
        import deimos.ncurses.ncurses;
        import deimos.ncurses.menu;
        import std.string : toStringz;

        private int screenX;
        private int screenY;

        this()
        {
            initscr();
            noecho();
            cbreak();
            keypad(stdscr, true);
            curs_set(0);

            getmaxyx(stdscr, screenY, screenX);
        }

        ~this()
        {
            endwin();
        }

        bool welcome()
        {
            immutable string[] logo = [
                r" ____              _        ",
                r"/ ___| _ __   __ _| | _____ ",
                r"\___ \| '_ \ / _` | |/ / _ \",
                r" ___) | | | | (_| |   <  __/",
                r"|____/|_| |_|\__,_|_|\_\___|",
            ];

            import std.conv;

            auto i = 0;
            foreach (l; logo)
            {
                mvprintw(screenY / 3 + i, ((screenX - (l.length)) / 2).to!int, `%s`, l.toStringz());
                i++;
            }

            immutable string s = `Type 'p' to play, or any other key to exit.`;
            mvprintw(screenY / 3 + i + 1, ((screenX - (s.length)) / 2).to!int, `%s`, s.toStringz());

            refresh();

            if (getch() != 'p' && getch() != 'P')
                return false;

            return true;
        }

        void gameOver(int score)
        {
            move(screenY / 2, screenX / 2);
            printw(`Game Over! Your score: %d`.toStringz, score);
            move(screenY / 2 + 2, screenX / 2);
            printw(`Type 'q' to exit.`.toStringz, score);

            nodelay(stdscr, false);

            auto c = getch();
            while (c != 'q')
                c = getch();

            return;
        }

        void drawScore(int score)
        {
            move(screenY, 1);
            printw(`Score: %d`.toStringz, score);
        }

        void updateScreen(ref Game.Field f)
        {
            erase();

            for (auto x = 0; x < f.length; x++)
            {
                for (auto y = 0; y < f[x].length; y++)
                {
                    mvprintw(y, x, `%c`, cast(char) f[x][y]);
                }
            }
        }

        Game.Direction getDirection()
        {
            nodelay(stdscr, true);
            timeout(50);

            switch (getch())
            {
            case 'w', KEY_UP:
                return Game.Direction.up;
            case 's', KEY_DOWN:
                return Game.Direction.down;
            case 'a', KEY_LEFT:
                return Game.Direction.left;
            case 'd', KEY_RIGHT:
                return Game.Direction.right;
            default:
                return Game.Direction.none;
            }
        }
    }
}
