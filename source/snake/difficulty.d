module snake.difficulty;

enum DifficultyLevel : int
{
    easy = 0,
    medium = 1,
    hard = 2,
    impossible = 3,
}

struct Difficulty
{
    const DifficultyLevel level;

    this(DifficultyLevel d)
    {
        this.level = d;

        with (DifficultyLevel)
        {
            final switch (d)
            {
            case easy:
                speed = 15;
                speedFactor = 10;
                speedStep = 2;
                break;
            case medium:
                speed = 20;
                speedFactor = 5;
                speedStep = 2;
                break;
            case hard:
                speed = 30;
                speedFactor = 3;
                speedStep = 5;
                break;
            case impossible:
                speed = 35;
                speedFactor = 3;
                speedStep = 10;
                break;
            }
        }
    }

    int speed;
    int speedStep;
    int speedFactor;
}
