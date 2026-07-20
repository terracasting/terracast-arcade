// Static safety check for every generated route jump and checkpoint transition.
const LEVELS = 8;
const ROWS = 100;
const CENTER = 3500;
const AMPLITUDE = 2900;
const FREQUENCY = 0.12;
const VERTICAL_GAP = 190;
const CHECKPOINT_GAP = 200;
const MAX_CENTER_SHIFT = 430;
const MAX_SINGLE_VERTICAL_GAP = 260;
const MAX_DOUBLE_VERTICAL_GAP = 390;
let failures = [];
let previousX = CENTER;
let previousY = 0;
let mandatoryDoubleJumps = 0;
let movingPlatforms = 0;

for (let level=0; level<LEVELS; level++) {
  for (let row=1; row<=ROWS; row++) {
    const step = level*ROWS+row;
	let x = CENTER + AMPLITUDE*Math.sin(step*FREQUENCY);
	x += level*18*Math.sin(Math.PI*row/100)*Math.sin(row*.72);
	x = Math.max(260,Math.min(6740,x));
    const dx = Math.abs(x-previousX);
	const isDouble = row % 20 === 7 && Math.floor(row/20) < Math.min(level+1,5);
    const offset = isDouble ? 160 : 0;
    const y = level*19200 + row*VERTICAL_GAP + offset;
    const dy = y-previousY;
    const verticalLimit = isDouble ? MAX_DOUBLE_VERTICAL_GAP : MAX_SINGLE_VERTICAL_GAP;
    if (dx > MAX_CENTER_SHIFT || dy > verticalLimit) {
      failures.push({level:level+1,row,dx,dy,isDouble});
    }
    if (isDouble) mandatoryDoubleJumps++;
	const movingInterval = Math.max(7,20-level*2);
	if (row >= 50 && row < 95 && row % movingInterval === 0 && !isDouble) movingPlatforms++;
    previousX = x;
    previousY = y;
  }
  if (level < LEVELS-1 && CHECKPOINT_GAP > MAX_SINGLE_VERTICAL_GAP) {
    failures.push({transition:`${level+1}-${level+2}`,dy:CHECKPOINT_GAP});
  }
	// Checkpoint is aligned with row 100 and 200 px above it.
	previousY = (level+1)*19200;
}

if (failures.length) {
  console.error('IMPASSABLE ROUTE CANDIDATES', failures);
  process.exit(1);
}
console.log(JSON.stringify({
  status:'PASS', levels:LEVELS, checkedRouteJumps:LEVELS*ROWS,
  checkedLevelTransitions:LEVELS-1,
  mandatoryDoubleJumps,
  movingPlatforms,
  rule:'all platforms are one-way; obstacles remain solid',
  maxAllowedCenterShift:MAX_CENTER_SHIFT,
  maxSingleJumpVerticalGap:MAX_SINGLE_VERTICAL_GAP,
  maxMandatoryDoubleVerticalGap:MAX_DOUBLE_VERTICAL_GAP
},null,2));
