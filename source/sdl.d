module sdl;

version (SDLFrontend)
{
    import snake;

    import bindbc.sdl;
    import io = std.stdio;

    class SDL : Game.IO
    {
        SDL_Renderer* renderer;
        SDL_Window* window;

        SDL_Texture* snakeHead;
        SDL_Texture* snakeBody;
        SDL_Texture* fruit;
        SDL_Texture* border;

        const tileSize = 16;

        private auto loadTexture(string filename)
        {
            import std.string : toStringz;
            import path = std.path;

            auto s = path.buildPath("resources", filename);

            return IMG_LoadTexture(this.renderer, s.toStringz());
        }

        private void blit(SDL_Texture* tex, int x, int y)
        {
            SDL_Rect dest;
            dest.x = x * tileSize;
            dest.y = y * tileSize;
            SDL_QueryTexture(tex, null, null, &dest.w, &dest.h);

            SDL_RenderCopy(this.renderer, tex, null, &dest);
        }

        private void loadResources()
        {
            this.snakeHead = loadTexture(`snake_head.png`);
            this.snakeBody = loadTexture(`snake_body.png`);
            this.fruit = loadTexture(`fruit.png`);
            this.border = loadTexture(`border.png`);
        }

        private void destroyResources()
        {
            SDL_DestroyTexture(snakeHead);
            SDL_DestroyTexture(snakeBody);
            SDL_DestroyTexture(fruit);
            SDL_DestroyTexture(border);
        }

        this()
        {
            IMG_Init(IMG_INIT_PNG | IMG_INIT_JPG);

            auto rendererFlags = SDL_RENDERER_ACCELERATED;

            if (SDL_Init(SDL_INIT_VIDEO) < 0)
            {
                io.writeln(SDL_GetError());
                return;
            }

            this.window = SDL_CreateWindow(`Snake`, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 1280, 960, 0);

            if (!window)
            {
                io.writeln(SDL_GetError());
                return;
            }

            this.renderer = SDL_CreateRenderer(this.window, -1, rendererFlags);

            if (!renderer)
            {
                io.writeln(SDL_GetError());
                return;
            }

            loadResources();
        }

        ~this()
        {
            SDL_DestroyRenderer(this.renderer);
            SDL_DestroyWindow(this.window);
            destroyResources();
            SDL_Quit();
        }

        bool welcome()
        {
            return true;
        }

        void gameOver(int score)
        {
            io.writeln(`Game over! Your score: `, score);
            return;
        }

        void drawScore(int score)
        {
        }

        void updateScreen(ref Game.Field f)
        {
            // SDL_SetRenderDrawColor(this.renderer, 96, 128, 255, 255);
            SDL_RenderClear(this.renderer);

            for (auto x = 0; x < f.length; x++)
            {
                for (auto y = 0; y < f[x].length; y++)
                {
                    switch (f[x][y])
                    {
                    case Game.Cell.snakeHead:
                        blit(snakeHead, x, y);
                        break;

                    case Game.Cell.fruit:
                        blit(fruit, x, y);
                        break;

                    case Game.Cell.border:
                        blit(border, x, y);
                        break;

                    default:
                        break;
                    }
                }
            }

            SDL_RenderPresent(this.renderer);
        }

        Game.Direction getDirection()
        {
            SDL_Event event;

            while (SDL_PollEvent(&event))
            {
                switch (event.type)
                {
                case SDL_KEYDOWN:
                    switch (event.key.keysym.sym)
                    {
                    case SDLK_a:
                        return Game.Direction.left;
                    case SDLK_d:
                        return Game.Direction.right;
                    case SDLK_w:
                        return Game.Direction.up;
                    case SDLK_s:
                        return Game.Direction.down;
                    default:
                        return Game.Direction.down;
                    }
                default:
                    return Game.Direction.none;
                }
            }
            return Game.Direction.none;
        }
    }
}
