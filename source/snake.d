module snake;

import engine;

class Game
{
    const int width = 80;
    const int height = 60;

    struct Position
    {
        int x, y;
    }

    private Engine engine;

    enum Obj
    {
        snakeHead,
        snakeBody,
        fruit,
        border,
    }

    engine.Tile*[int] objs;

    this()
    {
        this.engine = new Engine(1280, 960, 16);
        engine.createMap(width, height);
        engine.render.setResourcePath(`resources`);
        engine.render.setWindowTitle(`Snake Game`);

        objs[Obj.snakeBody] = engine.loadTile(`snake_body.png`);
        objs[Obj.snakeHead] = engine.loadTile(`snake_head.png`);
        objs[Obj.border] = engine.loadTile(`border.png`);
        objs[Obj.fruit] = engine.loadTile(`fruit.png`);
    }

    void setObject(int x, int y, Obj o)
    {
        engine.map.addTile(x, y, objs[o]);
    }

    void setObject(Position p, Obj o)
    {
        engine.map.addTile(p.x, p.y, objs[o]);
    }

    void removeObject(Position p)
    {
        engine.map.removeTile(p.x, p.y);
    }

    void removeObject(int x, int y)
    {
        engine.map.removeTile(x, y);
    }

    enum Direction
    {
        up,
        down,
        left,
        right,
        none,
    }

    private class Snake
    {
        private Direction dir;
        private Position head;
        private Position headPrev;
        private Position[] snake;

        this()
        {
            dir = Direction.up;

            head = Position(width / 2, height / 2);
            snake ~= head;
        }

        Position getHeadPosition()
        {
            return head;
        }

        bool isTail(Position p)
        {
            foreach (immutable e; snake)
            {
                if (e == p)
                    return true;
            }

            return false;
        }

        private void swap()
        {
            import std.stdio;

            int prevX = headPrev.x;
            int prevY = headPrev.y;

            int tmpX = 0;
            int tmpY = 0;

            foreach (ref e; snake)
            {
                tmpX = e.x;
                tmpY = e.y;
                e.x = prevX;
                e.y = prevY;
                prevX = tmpX;
                prevY = tmpY;

                setObject(e.x, e.y, Obj.snakeBody);
                removeObject(prevX, prevY);
            }

            setObject(head, Obj.snakeHead);
        }

        void grow()
        {
            auto e = snake[$ - 1];

            // prevent new segment spawn in snake's head
            switch (dir)
            {
            case Direction.right:
                e.x--;
                break;
            case Direction.left:
                e.x++;
                break;
            case Direction.up:
                e.y++;
                break;
            case Direction.down:
                e.y--;
                break;
            default:
                assert(0);
            }

            snake ~= e;

            setObject(e, Obj.snakeBody);
        }

        void setDirection(Direction d)
        {
            Direction getInverse(Direction d2)
            {
                if (d2 == Direction.right)
                    return Direction.left;
                if (d2 == Direction.left)
                    return Direction.right;
                if (d2 == Direction.up)
                    return Direction.down;
                if (d2 == Direction.down)
                    return Direction.up;
                return Direction.none;
            }

            if (getInverse(this.dir) == d || d == Direction.none)
                return;

            this.dir = d;
        }

        private int walkCooldown = 0;
        private int walkDelay = 100;
        private int speed = 15;

        void increaseSpeed(int value)
        {
            this.speed += value;
        }

        void move()
        {
            walkCooldown -= speed;

            if (walkCooldown <= 0)
            {
                headPrev = head;
                switch (dir)
                {
                case Direction.up:
                    head.y--;
                    walkCooldown = walkDelay;
                    break;
                case Direction.down:
                    head.y++;
                    walkCooldown = walkDelay;
                    break;
                case Direction.left:
                    head.x--;
                    walkCooldown = walkDelay;
                    break;
                case Direction.right:
                    head.x++;
                    walkCooldown = walkDelay;
                    break;
                default:
                    assert(0);
                }

                swap();
            }
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

            this.x = x_;
            this.y = y_;

            return Position(x, y);
        }

        Position get()
        {
            return Position(x, y);
        }

        void spawn()
        {
            auto c = random();
            while (engine.map.getTile(c.x, c.y) == objs[Obj.snakeBody])
                c = random();

            setObject(c, Obj.fruit);
        }

    }

    alias i = engine.input.InputType;
    Direction getDirection()
    {
        if (engine.input.isPressed(i.up))
            return Direction.up;
        if (engine.input.isPressed(i.down))
            return Direction.down;
        if (engine.input.isPressed(i.left))
            return Direction.left;
        if (engine.input.isPressed(i.right))
            return Direction.right;

        return Direction.none;
    }

    bool isQuit()
    {
        return engine.input.isPressed(i.quit);
    }

    void createBorders()
    {
        foreach (x; 0 .. width)
        {
            setObject(x, 0, Obj.border);
            setObject(x, height - 1, Obj.border);
        }

        foreach (y; 0 .. height)
        {
            setObject(0, y, Obj.border);
            setObject(width - 1, y, Obj.border);
        }
    }

    void play()
    {
        createBorders();

        auto snake = new Snake();
        auto fruit = new Fruit();

        auto gameOver = false;
        auto score = 0;

        while (!gameOver)
        {
            if (isQuit())
                gameOver = true;

            engine.render.draw();

            snake.setDirection(getDirection());
            snake.move();

            auto head = snake.getHeadPosition();

            if (snake.isTail(head))
                gameOver = true;

            if (head.x >= width - 1)
                gameOver = true;
            if (head.x <= 0)
                gameOver = true;
            if (head.y <= 0)
                gameOver = true;
            if (head.y >= height - 1)
                gameOver = true;

            if (head == fruit.get())
            {
                snake.grow();
                fruit.spawn();

                score++;

                if (score % 5 == 0)
                    snake.increaseSpeed(1);
            }

            engine.render.delay(16);
        }

        import std.file;
        import std.conv;

        write(`score.txt`, `Your score is: ` ~ score.to!string);
    }
}
