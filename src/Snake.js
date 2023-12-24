import React, { useState, useEffect, useRef } from 'react';

const Snake = () => {
  const [snake, setSnake] = useState([{ x: 10, y: 10 }]);
  const [food, setFood] = useState({ x: 5, y: 5 });
  const [direction, setDirection] = useState('RIGHT');
  const [gameOver, setGameOver] = useState(false);

  const canvasRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');

    const drawSnake = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.fillStyle = 'grey';
      snake.forEach((segment) => {
        ctx.fillRect(segment.x * 20, segment.y * 20, 20, 20);
      });
    };

    const drawFood = () => {
      ctx.fillStyle = 'red';
      ctx.fillRect(food.x * 20, food.y * 20, 20, 20);
    };

    const moveSnake = () => {
      if (gameOver) return;

      const newSnake = [...snake];
      const head = { ...newSnake[0] };

      switch (direction) {
        case 'UP':
          head.y -= 1;
          break;
        case 'DOWN':
          head.y += 1;
          break;
        case 'LEFT':
          head.x -= 1;
          break;
        case 'RIGHT':
          head.x += 1;
          break;
        default:
          break;
      }

      newSnake.unshift(head);

      // Check collision with food
      if (head.x === food.x && head.y === food.y) {
        setFood({
          x: Math.floor(Math.random() * canvas.width / 20),
          y: Math.floor(Math.random() * canvas.height / 20),
        });
      } else {
        newSnake.pop();
      }

      // Check collision with walls
      if (
        head.x < 0 ||
        head.x >= canvas.width / 20 ||
        head.y < 0 ||
        head.y >= canvas.height / 20
      ) {
        setGameOver(true);
      }

      // Check collision with itself
      for (let i = 1; i < newSnake.length; i++) {
        if (newSnake[i].x === head.x && newSnake[i].y === head.y) {
          setGameOver(true);
        }
      }

      setSnake(newSnake);
    };

    const handleKeyPress = (event) => {
      switch (event.key) {
        case 'ArrowUp':
          setDirection('UP');
          break;
        case 'ArrowDown':
          setDirection('DOWN');
          break;
        case 'ArrowLeft':
          setDirection('LEFT');
          break;
        case 'ArrowRight':
          setDirection('RIGHT');
          break;
        default:
          break;
      }
    };

    document.addEventListener('keydown', handleKeyPress);

    const gameLoop = () => {
      drawSnake();
      drawFood();
      moveSnake();
    };

    const gameInterval = setInterval(gameLoop, 200);

    return () => {
      clearInterval(gameInterval);
      document.removeEventListener('keydown', handleKeyPress);
    };
  }, [snake, food, direction, gameOver]);

  return (
    <canvas
      ref={canvasRef}
      width={400}
      height={400}
      style={{ border: '1px solid black' }}
    />
  );
};

export default Snake;
