# UI Depth, Color & Motion System

## Purpose

Design modern interfaces using: - Neutral color systems - Depth
layering - Realistic shadows - Motion principles - Structured animation
logic

------------------------------------------------------------------------

## 1. Color System

### Philosophy

You only need: - Neutral shades (background, surfaces, text) - One
primary brand color - Optional semantic colors (danger, success,
warning, info)

Avoid random HEX values. Use structured color models.

------------------------------------------------------------------------

### Recommended Format

Use **OKLCH** (preferred) or HSL.

OKLCH format:

    oklch(lightness chroma hue)

Ranges: - Lightness: 0 → 1 - Chroma: 0 → 0.2 (UI safe range) - Hue: 0 →
360

------------------------------------------------------------------------

### Neutral Palette Strategy

Set chroma to 0.

Create layers using lightness:

#### Dark Mode

- bg-dark → 0.1
- bg → 0.2
- bg-light → 0.3
- text → 0.96
- text-muted → 0.76

#### Light Mode

Flip values:

    newLightness = 1 - oldLightness

Then adjust manually for visual logic.

------------------------------------------------------------------------

### CSS Theme Architecture

``` css
:root {
  --bg-dark: oklch(0.1 0 264);
  --bg: oklch(0.2 0 264);
  --bg-light: oklch(0.3 0 264);

  --text: oklch(0.96 0 264);
  --text-muted: oklch(0.76 0 264);
}

body.light {
  --bg-dark: oklch(0.92 0 264);
  --bg: oklch(0.96 0 264);
  --bg-light: oklch(1 0 264);

  --text: oklch(0.15 0 264);
  --text-muted: oklch(0.4 0 264);
}
```

------------------------------------------------------------------------

## 2. Depth System

### Core Rule

Depth = layers + shadows

Step 1: Create 3--4 shades of same color\
Step 2: Add shadow structure

------------------------------------------------------------------------

### Shadow Model

Each shadow should combine:

- Top highlight (inset)
- Dark shadow
- Soft extended shadow

Example:

``` css
--shadow-s:
  inset 0 1px 2px #ffffff30,
  0 1px 2px #00000030,
  0 2px 4px #00000015;
```

Variants: - Small → subtle UI - Medium → cards - Large → modals

------------------------------------------------------------------------

### Elevation Rules

- Darkest = base layer
- Lighter = raised
- Lightest = interactive
- Remove borders if depth is clear
- Use inset shadows to push inward
- Use outer shadows to pull forward

------------------------------------------------------------------------

## 3. Motion System

### Animation Shorthand

``` css
animation: name duration timing count;
```

Example:

``` css
animation: slide 2s ease-in-out infinite;
```

------------------------------------------------------------------------

### Keyframes

``` css
@keyframes slide {
  0% { transform: translateX(0); }
  50% { transform: translateX(2rem); }
  100% { transform: translateX(0); }
}
```

------------------------------------------------------------------------

### Transition

``` css
transition: all 0.3s ease;
```

Use for: - Hover effects - Sliding highlights - Button states

------------------------------------------------------------------------

## 4. Sliding Navigation Technique

Use a ghost element.

1. Absolute positioned background
2. JS measures:
    - clientWidth
    - clientHeight
    - offsetLeft
    - offsetTop
3. Update ghost position
4. Use CSS transition for smooth motion

------------------------------------------------------------------------

## 5. 3D Card System

``` css
.container {
  perspective: 800px;
}

.card {
  transform-style: preserve-3d;
  transition: transform 0.6s cubic-bezier(.2,.8,.2,1);
}

.face {
  backface-visibility: hidden;
}

.back {
  transform: rotateY(180deg);
}
```

Principles: - Perspective controls depth realism - Preserve-3d prevents
flattening - Backface hidden prevents reverse bleed

------------------------------------------------------------------------

## 6. Path Animations

Use:

    offset-path
    offset-distance

Or SVG:

    <animateMotion>

For: - Flying cart effects - Icon tracing - Scroll path effects

------------------------------------------------------------------------

## Design Strategy

Improving average UI → good UI is easy.

Improving good UI → perfect UI is expensive.

Depth is the highest ROI improvement: - Minimal code - Large perceived
quality gain
