module engine.engine;

import bindbc.sdl;
import engine.renderer;
import engine.input;

abstract class Engine
{
public:
    final this(uint width, uint height, uint tileSize, string appName)
    {
        this.renderer = new Renderer(width, height, tileSize, appName);
        this.input = new Input();
    }

    final void start()
    {
        onStart();

        while (!isQuit)
        {
            SDL_Event event;
            if (SDL_PollEvent(&event))
            {
                if (event.type == SDL_QUIT)
                    isQuit = true;

                input.updateKeyboard(&event);
            }

            onUpdate();

            // Maybe use delta time?
            SDL_Delay(16);
        }
    }

    final void quit()
    {
        isQuit = true;
    }

    private enum mustBeOverrided = "this method must be overrided";

    void onStart()
    {
        assert(false, mustBeOverrided);
    }

    void onUpdate()
    {
        assert(false, mustBeOverrided);
    }

    void render()
    {
        assert(false, mustBeOverrided);
    }

protected:
    bool isQuit = false;
    Renderer renderer;
    Input input;
}
