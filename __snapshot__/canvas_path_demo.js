// Generated Canvas JavaScript
function drawVgGraphics(canvas) {
  const ctx = canvas.getContext('2d');
  canvas.width = 250;
  canvas.height = 150;
  
  // Clear canvas
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  
  // Drawing commands
  ctx.fillStyle = '#F2F2F2';
  ctx.fillRect(0, 0, 250, 150);
  ctx.beginPath();
  ctx.moveTo(50, 50);
  ctx.lineTo(150, 50);
  ctx.quadraticCurveTo(200, 75, 150, 100);
  ctx.lineTo(50, 100);
  ctx.closePath();
  ctx.fillStyle = '#FF00FF';
  ctx.fill();
  ctx.font = '14px Arial, sans-serif';
  ctx.fillStyle = '#000000';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('Canvas Path Demo', 125, 30);
}

// Usage: drawVgGraphics(document.getElementById('myCanvas'));