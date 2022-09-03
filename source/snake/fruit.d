module snake.fruit;

import snake.point;

final class Fruit
{
package:
    int reward;
    Point location;

    this(int reward = 1)
    {
        this.reward = reward;
    }

    this(uint x, uint y, int reward = 1)
    {
        this.location = Point(x, y);
        this.reward = reward;
    }
}
