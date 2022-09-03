module engine.renderer;

import bindbc.sdl;
import std.string : toStringz;
import std.conv;

final class Renderer
{
public:
    string resourcePath = ".";

    this(uint w, uint h, uint tileSize, string name)
    {
        this._tileSize = tileSize;

        // TODO: use accelerated only if it available
        auto rendererFlags = SDL_RENDERER_ACCELERATED;

        if (SDL_Init(SDL_INIT_EVERYTHING) < 0)
            throw new Exception(SDL_GetError().to!string);

        this._window = SDL_CreateWindow(name.toStringz(), SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, w, h, 0);

        if (!this._window)
            throw new Exception(SDL_GetError().to!string);

        this._renderer = SDL_CreateRenderer(_window, -1, rendererFlags);

        if (!_renderer)
            throw new Exception(SDL_GetError().to!string);

        if (TTF_Init() < 0)
            throw new Exception(TTF_GetError().to!string);

        this._fallbackFont = loadFont(getPath("resources/fallback.ttf"), tileSize * 2);
    }

    ~this()
    {
        SDL_DestroyRenderer(_renderer);
        SDL_DestroyWindow(_window);
        SDL_Quit();
    }

    @property void windowTitle(string title)
    {
        SDL_SetWindowTitle(_window, title.toStringz());
    }

    @property string windowTitle()
    {
        return SDL_GetWindowTitle(_window).to!string;
    }

    @property void windowIcon(SDL_Surface* icon)
    {
        SDL_SetWindowIcon(_window, icon);
    }

    @property void windowIcon(string filename)
    {
        auto surface = loadSurface(filename);

        scope (exit)
            SDL_FreeSurface(surface);

        windowIcon = surface;
    }

    TTF_Font* loadFont(string filename, int size = 16)
    {
        auto font = TTF_OpenFont(filename.toStringz, size);

        if (font == null)
            throw new Exception(TTF_GetError().to!string);

        return font;
    }

    SDL_Texture* loadTexture(string filename)
    {
        auto surface = loadSurface(filename);

        scope (exit)
            SDL_FreeSurface(surface);

        return SDL_CreateTextureFromSurface(_renderer, surface);
    }

    SDL_Surface* loadSurface(string filename)
    {
        import std.string : toStringz;

        auto sur = IMG_Load(getPath(filename).toStringz());
        if (!sur)
            throw new Exception(`cannot load surface: ` ~ filename);

        return sur;
    }

    void blit(uint x, uint y, SDL_Texture* texture)
    {
        if (!texture)
            throw new Exception("texture is null");

        SDL_Rect dest;
        dest.x = x * _tileSize;
        dest.y = y * _tileSize;

        SDL_QueryTexture(texture, null, null, &dest.w, &dest.h);
        SDL_RenderCopy(_renderer, texture, null, &dest);
    }

    void text(TTF_Font* font, uint x, uint y, string text, SDL_Color color = SDL_Color(255, 255, 255))
    {
        if (font == null)
            font = this._fallbackFont;

        SDL_Surface* surf = TTF_RenderText_Blended(font, text.toStringz, color);
        SDL_Texture* tex = SDL_CreateTextureFromSurface(_renderer, surf);

        auto dest = SDL_Rect(x, y, surf.w, surf.h);
        SDL_RenderCopy(_renderer, tex, null, &dest);

        SDL_FreeSurface(surf);
        SDL_DestroyTexture(tex);
    }

    void clear()
    {
        SDL_RenderClear(_renderer);
    }

    void present()
    {
        SDL_RenderPresent(_renderer);
    }

private:
    string getPath(string filename)
    {
        static import path = std.path;

        return path.buildPath(resourcePath, filename);
    }

    SDL_Renderer* _renderer;
    SDL_Window* _window;
    TTF_Font* _fallbackFont;

    uint _tileSize = 16;
}
