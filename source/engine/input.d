module engine.input;

public import bindbc.sdl;

class Input
{
public:
    bool isKeyPressed(SDL_Keycode key)
    {
        return (key in _isKeyDown) ? _isKeyDown[key] : false;
    }

    bool isAnyKeyPressed(SDL_Keycode[] keys...)
    {
        foreach (key; keys)
        {
            if (isKeyPressed(key))
                return true;
        }

        return false;
    }

package:
    void updateKeyboard(SDL_Event* event)
    {
        switch (event.type)
        {
        case SDL_KEYDOWN:
            _isKeyDown[event.key.keysym.sym] = true;
            break;
        case SDL_KEYUP:
            _isKeyDown[event.key.keysym.sym] = false;
            break;
        default:
            return;
        }
    }

private:
    bool[SDL_Keycode] _isKeyDown;
}
