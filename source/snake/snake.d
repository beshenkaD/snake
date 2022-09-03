module snake.snake;

import snake.point;

enum Direction
{
    up,
    down,
    left,
    right
}

final class Snake
{
package:
    // increment this to make snake bigger
    uint length = 1;

    // increment this to make snake faster
    uint speed;

    this(uint x, uint y, uint speed = 20)
    {
        this._body = new Point[](1);
        this._body[0].x = x;
        this._body[0].y = y;
        this.speed = speed;
    }

    bool isTail(Point p)
    {
        foreach (immutable Point sp; body)
        {
            if (sp == p)
                return true;
        }

        return false;
    }

    void setDirection(Direction d)
    {
        alias dr = Direction;

        const auto rev = [
            dr.down: dr.up,
            dr.up: dr.down,
            dr.left: dr.right,
            dr.right: dr.left,
        ];

        if (rev[d] != this._direction)
            this._direction = d;
    }

private:
    int walkCooldown = 0;
    real walkDelay = 100;

package:
    void move()
    {
        walkCooldown -= speed;

        if (walkCooldown >= 0)
            return;

        auto h = Point(head().x, head().y);

        with (Direction)
        {
            final switch (_direction)
            {
            case left:
                h.x--;
                break;
            case right:
                h.x++;
                break;
            case up:
                h.y--;
                break;
            case down:
                h.y++;
                break;
            }
        }

        if (this.length > body.length)
            _body ~= h;
        else
            _body = _body[1 .. $] ~ h;

        walkCooldown = cast(int) walkDelay;
    }

    @property Point head()
    {
        return this._body[$ - 1];
    }

    // dfmt off
    @property Point[] body()
    {
        return this._body[0 .. $ - 1];
    }
    // dfmt on

private:
    Point[] _body;
    Direction _direction;
}
