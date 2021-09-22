import std.typecons : Tuple;

class Game
{
    alias Field = Cell[][];

    enum Cell
    {
        none = ' ',
        borderVertical = '|',
        borderHorizontal = '-',
        snakeHead = '*',
        snakeBody = '#',
        fruit = '$',
    }

    struct Position
    {
        int x, y;
    }

    interface IO
    {
        void updateScreen(ref Field);
        void drawScore(int);
        Tuple!(int, int) getXY();
        bool welcome();
        void gameOver(int);
        Direction getDirection();
    }

    private class DefaultIO : IO
    {
        import deimos.ncurses.ncurses;
        import deimos.ncurses.menu;
        import std.string : toStringz;

        private int x, y;

        this()
        {
            initscr();
            noecho();
            cbreak();

            getmaxyx(stdscr, x, y);
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
                mvprintw(x / 3 + i, ((y - (l.length)) / 2).to!int, `%s`, l.toStringz());
                i++;
            }

            immutable string s = `Type 'p' to play, or any other key to exit.`;
            mvprintw(x / 3 + i + 1, ((y - (s.length)) / 2).to!int, `%s`, s.toStringz());

            refresh();

            if (getch() != 'p' && getch() != 'P')
                return false;

            return true;
        }

        void gameOver(int score)
        {
            move(x / 2, y / 2);
            printw(`Game Over! Your score: %d`.toStringz, score);
            move(x / 2 + 2, y / 2);
            printw(`Type 'q' to exit.`.toStringz, score);

            nodelay(stdscr, false);

            auto c = getch();
            while (c != 'q')
                c = getch();

            return;
        }

        void drawScore(int score)
        {
            move(x, 1);
            printw(`Score: %d`.toStringz, score);
        }

        Tuple!(int, int) getXY()
        {
            return Tuple!(int, int)(x, y);
        }

        void updateScreen(ref Field f)
        {
            erase();

            for (auto x = 0; x < f.length; x++)
            {
                for (auto y = 0; y < f[x].length; y++)
                {
                    mvprintw(x, y, `%c`, cast(char) f[x][y]);
                }
            }
        }

        Direction getDirection()
        {
            nodelay(stdscr, true);
            timeout(50);

            switch (getch())
            {
            case 'w', KEY_UP:
                return Direction.up;
            case 's', KEY_DOWN:
                return Direction.down;
            case 'a', KEY_LEFT:
                return Direction.left;
            case 'd', KEY_RIGHT:
                return Direction.right;
            default:
                return Direction.none;
            }
        }
    }

    private IO io;

    this(IO io = null)
    {
        if (!io)
            io = new DefaultIO();

        this.io = io;

        auto xy = io.getXY();
        auto x = xy[0];
        auto y = xy[1];

        field = new Field(x, y);

        for (int i = 0; i < x; i++)
            field[i][0] = Cell.borderVertical;
        for (int i = 0; i < x; i++)
            field[i][y - 1] = Cell.borderVertical;
        for (int i = 0; i < y; i++)
            field[0][i] = Cell.borderHorizontal;
        for (int i = 0; i < y; i++)
            field[x - 1][i] = Cell.borderHorizontal;
    }

    private Field field;

    private void setField(int x, int y, Cell c)
    {
        field[x][y] = c;
    }

    private void setField(Position p, Cell c)
    {
        field[p.x][p.y] = c;
    }

    private Cell getField(Position p)
    {
        return field[p.x][p.y];
    }

    private Position getCenter()
    {
        return Position(cast(int) field.length / 2, cast(int) field[0].length / 2);
    }

    public enum Direction
    {
        left,
        right,
        up,
        down,
        none,
    }

    private class Snake
    {
        Direction dir;
        Position[] snake;

        this()
        {
            dir = Direction.up;

            snake = new Position[](1);
            snake[0] = getCenter();
            this.grow();

            this.swap();

            io.updateScreen(field);
        }

        // The hardest part :D
        private void swap()
        {
            int prevX = snake[0].x;
            int prevY = snake[0].y;

            int tmpX = 0;
            int tmpY = 0;

            foreach (ref e; snake[1 .. $])
            {
                tmpX = e.x;
                tmpY = e.y;
                e.x = prevX;
                e.y = prevY;
                prevX = tmpX;
                prevY = tmpY;

                setField(e, Cell.snakeBody);
                setField(prevX, prevY, Cell.none);
            }

            setField(snake[0], Cell.snakeHead);
        }

        Position getHead()
        {
            return Position(snake[0].x, snake[0].y);
        }

        void grow()
        {
            auto e = snake[$ - 1];

            if (dir == Direction.right || dir == Direction.left)
                e.y++;
            else
                e.x++;

            snake ~= e;

            setField(e, Cell.snakeBody);
        }

        void move()
        {
            switch (dir)
            {
            case Direction.up:
                snake[0].x--;

                break;
            case Direction.down:
                snake[0].x++;

                break;
            case Direction.left:
                snake[0].y--;

                break;
            case Direction.right:
                snake[0].y++;

                break;
            default:
                break;
            }

            swap();
        }
    }

    private class Fruit
    {
        int x, y;

        this()
        {
            this.spawn();
        }

        private Position random()
        {
            import std.random;

            auto xy = io.getXY();
            int x_ = uniform!"[]"(10, xy[0] - 5);
            int y_ = uniform!"[]"(10, xy[1] - 5);

            x = x_;
            y = y_;

            return Position(x, y);
        }

        Position get()
        {
            return Position(x, y);
        }

        void spawn()
        {
            auto c = random();
            while (getField(c) == Cell.snakeBody || getField(c) == Cell.snakeHead)
                c = random();

            setField(c, Cell.fruit);
        }
    }

    public void run()
    {
        if (!io.welcome())
            return;

        auto snake = new Snake();
        auto fruit = new Fruit();

        import core.thread;

        int score = 0;
        int delay = 100;
        bool gameOver = false;

        while (!gameOver)
        {
            io.updateScreen(field);

            io.drawScore(score);

            auto c = io.getDirection();
            final switch (c)
            {
            case Direction.left:
                if (snake.dir != Direction.right)
                    snake.dir = c;
                break;
            case Direction.right:
                if (snake.dir != Direction.left)
                    snake.dir = c;
                break;
            case Direction.up:
                if (snake.dir != Direction.down)
                    snake.dir = c;
                break;
            case Direction.down:
                if (snake.dir != Direction.up)
                    snake.dir = c;
                break;
            case Direction.none:
                break;
            }
            snake.move();

            auto head = snake.getHead();

            if (head == fruit.get())
            {
                snake.grow();
                fruit.spawn();
                score += 10;

                // Make game faster
                if (score % 50 == 0 && (delay - 5) != 0) {
                    delay -= 5;
                }
            }

            auto xy = io.getXY();
            // Right
            if (head.x >= xy[0] - 1)
                gameOver = true;
            // Top
            if (head.x <= 0)
                gameOver = true;
            // Left
            if (head.y <= 0)
                gameOver = true;
            // Bottom
            if (head.y >= xy[1] - 1)
                gameOver = true;

            foreach (s; snake.snake[2 .. $])
            {
                if (head == s)
                {
                    gameOver = true;
                    break;
                }
            }

            Thread.sleep(delay.msecs);
        }

        io.gameOver(score);
    }
}

void main()
{
    auto s = new Game();
    s.run();
}
