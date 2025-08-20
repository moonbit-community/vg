// Generated Canvas JavaScript
function drawVgGraphics(canvas) {
  const ctx = canvas.getContext('2d');
  canvas.width = 300;
  canvas.height = 200;
  
  // Clear canvas
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  
  // Drawing commands
  ctx.fillStyle = '#F2F2F2';
  ctx.fillRect(0, 0, 300, 200);
  ctx.beginPath();
  ctx.arc(80, 100, 30, 0, 2 * Math.PI);
  ctx.fillStyle = '#FF0000';
  ctx.fill();
  ctx.fillStyle = '#00FF00';
  ctx.fillRect(150, 70, 60, 60);
  ctx.beginPath();
  ctx.moveTo(50, 160);
  ctx.lineTo(250, 160);
  ctx.strokeStyle = '#0000FF';
  ctx.lineWidth = 3;
  ctx.lineCap = 'round';
  ctx.stroke();
  ctx.font = '16px Arial, sans-serif';
  ctx.fillStyle = '#000000';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('Canvas Rendering', 150, 40);
}

// Usage: drawVgGraphics(document.getElementById('myCanvas'));