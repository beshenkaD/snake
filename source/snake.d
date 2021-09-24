module snake;

class Game
{
    private IO io;
    interface IO
    {
        void updateScreen(ref Field);
        void drawScore(int);
        bool welcome();
        void gameOver(int);
        Direction getDirection();
    }

    alias Field = Cell[][];
    private Field field;
    enum Cell
    {
        none = ' ',
        border = '%',
        snakeHead = '#',
        snakeBody = '#',
        fruit = '$',
    }

    struct Position
    {
        int x, y;
    }

    int width;
    int height;

    this(int width = 80, int height = 60, IO io = null)
    {
        this.io = io;

        field = new Field(width, height);
        this.width = width;
        this.height = height;

        for (int i = 0; i < width; i++)
        {
            field[i][0] = Cell.border;
            field[i][height - 1] = Cell.border;
        }
        for (int i = 0; i < height; i++)
        {
            field[0][i] = Cell.border;
            field[width - 1][i] = Cell.border;
        }
    }

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

    private Cell getField(int x, int y)
    {
        return field[x][y];
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

                if (getField(prevX, prevY) == Cell.snakeBody || Cell.snakeHead)
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
                e.x++;
            else
                e.y++;

            snake ~= e;

            setField(e, Cell.snakeBody);
        }

        void move()
        {
            switch (dir)
            {
            case Direction.up:
                snake[0].y--;
                break;
            case Direction.down:
                snake[0].y++;
                break;
            case Direction.left:
                snake[0].x--;
                break;
            case Direction.right:
                snake[0].x++;
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

            int x_ = uniform!"[]"(2, width - 2);
            int y_ = uniform!"[]"(2, height - 2);

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
        int delay = 150;
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

            foreach (e; snake.snake[2 .. $])
            {
                if (head == e)
                {
                    gameOver = true;
                    break;
                }
            }

            if (head == fruit.get())
            {
                snake.grow();
                fruit.spawn();
                score += 10;

                // Make game faster
                if (score % 50 == 0 && (delay - 5) != 0)
                    delay -= 5;
            }

            if (head.x >= width - 1)
                gameOver = true;
            if (head.x <= 0)
                gameOver = true;
            if (head.y <= 0)
                gameOver = true;
            if (head.y >= height - 1)
                gameOver = true;

            Thread.sleep(delay.msecs);
        }

        io.gameOver(score);
    }
}
