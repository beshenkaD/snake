module engine;

import bindbc.sdl;

class Engine
{
    struct Tile
    {
        private SDL_Texture* texture;

        this(SDL_Texture* texture)
        {
            this.texture = texture;
        }

        bool isEmpty()
        {
            return this.texture == null;
        }
    }

    struct Map
    {
        private int w;
        private int h;
        private Tile[][] tiles;

        this(int w, int h)
        {
            this.w = w;
            this.h = h;

            this.tiles = new Tile[][](w, h);
        }

        Tile getTile(int x, int y)
        {
            return this.tiles[x][y];
        }

        void addTile(int x, int y, ref Tile o)
        {
            this.tiles[x][y] = o;
        }

        void removeTile(int x, int y)
        {
            this.tiles[x][y] = Tile(null);
        }
    }

    class Render
    {
        private SDL_Renderer* renderer;
        private SDL_Window* window;

        private immutable int tileSize;

        this(int width, int height, int tileSize)
        {
            import std.conv;
            import std.exception;

            this.tileSize = tileSize;

            auto rendererFlags = SDL_RENDERER_ACCELERATED;

            if (SDL_Init(SDL_INIT_VIDEO) < 0)
                throw new Exception(SDL_GetError().to!string);

            this.window = SDL_CreateWindow(`sEngn`, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, width, height, 0);

            if (!window)
                throw new Exception(SDL_GetError().to!string);

            this.renderer = SDL_CreateRenderer(this.window, -1, rendererFlags);

            if (!renderer)
                throw new Exception(SDL_GetError().to!string);
        }

        ~this()
        {
            SDL_DestroyRenderer(this.renderer);
            SDL_DestroyWindow(this.window);
            SDL_Quit();
        }

        private void blit(int x, int y, ref Tile t)
        {
            SDL_Rect dest;
            dest.x = x * tileSize;
            dest.y = y * tileSize;
            SDL_QueryTexture(t.texture, null, null, &dest.w, &dest.h);

            SDL_RenderCopy(this.renderer, t.texture, null, &dest);
        }

        void setWindowTitle(string title)
        {
            import std.string : toStringz;

            SDL_SetWindowTitle(this.window, title.toStringz());
        }

        void draw()
        {
            SDL_RenderClear(this.renderer);

            for (int x = 0; x < map.w; x++)
            {
                for (int y = 0; y < map.h; y++)
                {
                    auto t = map.tiles[x][y];

                    if (t.isEmpty())
                        continue;

                    blit(x, y, t);
                }
            }

            SDL_RenderPresent(this.renderer);
        }

        void delay(int n)
        {
            SDL_Delay(n);
        }

        private string resourcePath;

        void setResourcePath(string path)
        {
            this.resourcePath = path;
        }

        private SDL_Texture* loadTexture(string filename)
        {
            import std.string : toStringz;
            import path = std.path;

            auto s = path.buildPath(resourcePath, filename);

            auto tex = IMG_LoadTexture(this.renderer, s.toStringz());
            if (!tex)
                throw new Exception(`Cannot load texture: ` ~ filename);

            return tex;
        }
    }

    private class Input
    {
        enum InputType
        {
            up,
            down,
            left,
            right,
            pause,
            quit,
        }

        bool[InputType] keys;

        this()
        {
            import std.traits;
            import std.stdio;

            foreach (e; [EnumMembers!InputType])
            {
                keys[e] = false;
            }
        }

        private bool repeatDisabled;

        private void updateKeyboard()
        {
            // TODO: this looks like a dirty hack.
            const string gen = "
                    switch (event.key.keysym.sym) {
                    case SDLK_w, SDLK_UP:
                        keys[InputType.up] = value;
                        break;
                    case SDLK_a, SDLK_LEFT:
                        keys[InputType.left] = value;
                        break;
                    case SDLK_d, SDLK_RIGHT:
                        keys[InputType.right] = value;
                        break;
                    case SDLK_s, SDLK_DOWN:
                        keys[InputType.down] = value;
                        break;
                    case SDLK_q:
                        keys[InputType.quit] = value;
                        break;
                    case SDLK_ESCAPE:
                        keys[InputType.pause] = value;
                        break;
                    default:
                        break;}";

            SDL_Event event;

            while (SDL_PollEvent(&event))
            {
                switch (event.type)
                {
                case SDL_QUIT:
                    keys[InputType.quit] = true;
                    break;

                case SDL_KEYDOWN:
                    const bool value = true;
                    mixin(gen);

                    break;
                case SDL_KEYUP:
                    const bool value = false;
                    mixin(gen);

                    break;
                default:
                    break;
                }
            }
        }

        public void disableRepeat()
        {
            this.repeatDisabled = true;
        }

        public bool isPressed(InputType i)
        {
            updateKeyboard();
            return keys[i];
        }
    }

    public Render render;

    public Map map;

    public Input input;

    Tile loadTile(string filepath)
    {
        return Tile(render.loadTexture(filepath));
    }

    void createMap(int width, int height)
    {
        this.map = Map(width, height);
    }

    this(int width, int height, int tileSize)
    {
        this.render = new Render(width, height, tileSize);
        this.input = new Input();
    }
}
