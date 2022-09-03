module snake.game;

import engine;
import snake.snake;
import snake.point;
import snake.fruit;
import snake.difficulty;

final class Game : Engine
{
public:
    uint width, heigth;
    private uint fieldHeight, fieldWidth;

    this(uint tileSize = 16)
    {
        this.width = this.heigth = 40;

        this.fieldHeight = heigth - 2;
        this.fieldWidth = width;

        super(width * tileSize, heigth * tileSize, tileSize, "snake");
    }

    ~this()
    {
        SDL_DestroyTexture(this.snakeTexture);
        SDL_DestroyTexture(this.fruitTexture);
        SDL_DestroyTexture(this.borderTexture);
    }

    override void onStart()
    {
        renderer.resourcePath = "resources";
        renderer.windowIcon = "fruit.png";

        // TODO: this should be freed
        this.snakeTexture = renderer.loadTexture("snake_head.png");
        this.fruitTexture = renderer.loadTexture("fruit.png");
        this.borderTexture = renderer.loadTexture("border.png");

        this.snake = new Snake(width / 2, heigth / 2, difficulty.speed);
        this.fruit = new Fruit();

        placeFruit();
    }

    override void onUpdate()
    {
        with (Direction)
        {
            if (input.isAnyKeyPressed(SDLK_w, SDLK_UP))
                snake.setDirection(up);
            if (input.isAnyKeyPressed(SDLK_s, SDLK_DOWN))
                snake.setDirection(down);
            if (input.isAnyKeyPressed(SDLK_a, SDLK_LEFT))
                snake.setDirection(left);
            if (input.isAnyKeyPressed(SDLK_d, SDLK_RIGHT))
                snake.setDirection(right);
        }

        snake.move();

        if (snake.isTail(snake.head) || !isInMap(snake.head))
            this.quit();

        if (snake.head == fruit.location)
        {
            placeFruit();
            snake.length++;
            score += fruit.reward;

            if (score % difficulty.speedFactor == 0)
                snake.speed += difficulty.speedStep;
        }

        render();
    }

    override void render()
    {
        renderer.clear();

        renderBorder();
        renderSnake();
        renderFruit();
        renderScore();

        renderer.present();
    }

private:
    uint score = 0;
    Difficulty difficulty = Difficulty(DifficultyLevel.impossible);

    Snake snake;
    Fruit fruit;

    void placeFruit()
    {
        import std.random;

        uint x, y;

        do
        {
            x = uniform!"[)"(width - fieldWidth, fieldWidth);
            y = uniform!"[)"(heigth - fieldHeight, fieldHeight);
        }
        while (snake.isTail(Point(x, y)));

        fruit.location = Point(x, y);
    }

    bool isInMap(Point p)
    {
        return p.x <= fieldWidth && p.y <= fieldHeight && p.x >= width - fieldWidth && p.y >= heigth - fieldHeight;
    }

    // TODO: make texture bank
    SDL_Texture* snakeTexture;
    SDL_Texture* fruitTexture;
    SDL_Texture* borderTexture;

    // TODO: render head based on direction
    void renderSnake()
    {
        foreach (immutable p; snake.body)
            renderer.blit(p.x, p.y, snakeTexture);
    }

    void renderFruit()
    {
        with (fruit.location)
            renderer.blit(x, y, fruitTexture);
    }

    void renderScore()
    {
        import std.conv : to;

        renderer.text(null, 0, 0, "Score: " ~ score.to!string, SDL_Color(218, 178, 2));
    }

    void renderBorder()
    {
        foreach (x; 0 .. width)
            foreach (y; 0 .. heigth - fieldHeight)
                renderer.blit(x, y, borderTexture);
    }
}
