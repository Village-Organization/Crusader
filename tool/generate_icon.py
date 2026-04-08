"""Generate the Crusader app icon — v2.

A premium, modern shield + cross on a deep black background.
Rendered at 4x supersampling for smooth anti-aliasing.

Design:
  - Elegant heater shield shape with smooth curves
  - Cyan-to-magenta vertical gradient fill
  - Thin white cross with rounded proportions
  - Layered glow effects (outer ambient + inner highlight)
  - Subtle glass-like inner bevel on the shield
  - Deep black background with soft radial vignette
"""

from PIL import Image, ImageDraw, ImageFilter, ImageChops
import math
import os

# Final output size
OUTPUT_SIZE = 1024
# Render at 4x for anti-aliasing
SCALE = 4
SIZE = OUTPUT_SIZE * SCALE

# ── Colors ──────────────────────────────────────────────────────────────────
CYAN = (0, 229, 255)
MAGENTA = (255, 45, 186)
DEEP_BLACK = (10, 10, 14)
SOFT_BLACK = (17, 17, 24)
WHITE = (255, 255, 255)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_color(c1: tuple, c2: tuple, t: float) -> tuple:
    t = max(0.0, min(1.0, t))
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def ease_in_out(t: float) -> float:
    """Smooth ease-in-out curve."""
    return t * t * (3 - 2 * t)


def shield_half_width(t: float, max_w: float) -> float:
    """Return the half-width of the shield at normalized y position t (0=top, 1=bottom).

    Shape: rounded top shoulders, straight sides, smooth taper to pointed bottom.
    """
    # Top cap (0.0 .. 0.08): rounded shoulders
    if t < 0.08:
        p = t / 0.08
        # Quarter-circle ease-in
        return max_w * math.sqrt(1 - (1 - p) ** 2)

    # Upper body (0.08 .. 0.50): full width, very slight inward curve
    if t < 0.50:
        return max_w

    # Lower body (0.50 .. 1.0): smooth taper to point
    p = (t - 0.50) / 0.50
    # Use a power curve for elegant taper
    taper = 1 - p ** 1.6
    return max_w * max(taper, 0)


def build_shield_mask(size: int, cx: int, cy: int, w: int, h: int) -> Image.Image:
    """Build a smooth grayscale mask of the shield shape."""
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)

    top = cy - h // 2
    bottom = cy + h // 2
    half_w = w / 2.0

    for y in range(top, bottom):
        t = (y - top) / (bottom - top)
        hw = shield_half_width(t, half_w)
        if hw > 0.5:
            x0 = int(cx - hw)
            x1 = int(cx + hw)
            draw.line([(x0, y), (x1, y)], fill=255)

    return mask


def build_gradient(size: int, top: int, bottom: int) -> Image.Image:
    """Build a vertical gradient image from CYAN (top) to MAGENTA (bottom)."""
    img = Image.new('RGB', (size, size), (0, 0, 0))
    draw = ImageDraw.Draw(img)

    for y in range(size):
        if y < top:
            t = 0.0
        elif y > bottom:
            t = 1.0
        else:
            t = (y - top) / max(bottom - top, 1)

        # Slightly ease the gradient for smoother transition
        t = ease_in_out(t)
        color = lerp_color(CYAN, MAGENTA, t)
        draw.line([(0, y), (size - 1, y)], fill=color)

    return img


def build_cross_mask(size: int, cx: int, cy: int, w: int, h: int) -> Image.Image:
    """Build a smooth cross mask with rounded ends, properly positioned on the shield."""
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)

    shield_top = cy - h // 2
    shield_bottom = cy + h // 2
    half_w = w / 2.0

    # Cross dimensions — refined proportions
    arm_thickness = int(w * 0.10)  # thinner arms
    half_arm = arm_thickness // 2
    corner_r = arm_thickness // 2  # rounded ends

    # Cross center — slightly above shield center for visual balance
    cross_cy = cy - int(h * 0.04)

    # Vertical bar extents
    v_top = shield_top + int(h * 0.16)
    v_bottom = shield_bottom - int(h * 0.18)

    # Horizontal bar extents
    h_left = cx - int(w * 0.26)
    h_right = cx + int(w * 0.26)

    # Clip horizontal bar to shield at cross center y
    t_h = (cross_cy - shield_top) / (shield_bottom - shield_top)
    shield_hw = shield_half_width(t_h, half_w)
    h_left = max(h_left, int(cx - shield_hw + w * 0.06))
    h_right = min(h_right, int(cx + shield_hw - w * 0.06))

    # Clip bottom of vertical bar to shield
    t_vb = (v_bottom - shield_top) / (shield_bottom - shield_top)
    shield_hw_bottom = shield_half_width(t_vb, half_w)
    if shield_hw_bottom < half_arm + w * 0.04:
        # Pull bottom up if shield tapers too narrow
        for check_y in range(v_bottom, cross_cy, -1):
            t_check = (check_y - shield_top) / (shield_bottom - shield_top)
            if shield_half_width(t_check, half_w) >= half_arm + w * 0.04:
                v_bottom = check_y
                break

    # Draw vertical bar with rounded caps
    draw.rounded_rectangle(
        [cx - half_arm, v_top, cx + half_arm, v_bottom],
        radius=corner_r,
        fill=255,
    )

    # Draw horizontal bar with rounded caps
    draw.rounded_rectangle(
        [h_left, cross_cy - half_arm, h_right, cross_cy + half_arm],
        radius=corner_r,
        fill=255,
    )

    return mask


def build_background(size: int) -> Image.Image:
    """Deep black background with subtle radial vignette."""
    img = Image.new('RGB', (size, size), DEEP_BLACK)
    cx, cy = size // 2, size // 2
    max_dist = size * 0.7

    for y in range(size):
        for x in range(size):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx * dx + dy * dy) / max_dist
            dist = min(dist, 1.0)
            color = lerp_color(SOFT_BLACK, DEEP_BLACK, dist)
            img.putpixel((x, y), color)

    return img


def build_glow(size: int, cx: int, cy: int, color: tuple, radius: int, intensity: float) -> Image.Image:
    """Build a soft radial glow."""
    glow = Image.new('RGB', (size, size), (0, 0, 0))
    draw = ImageDraw.Draw(glow)

    # Draw a filled ellipse then blur it
    r = radius
    draw.ellipse(
        [cx - r, cy - r, cx + r, cy + r],
        fill=tuple(int(c * intensity) for c in color),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=r * 0.6))
    return glow


def build_inner_bevel(mask: Image.Image, blur_radius: int = 20) -> tuple:
    """Build inner highlight and shadow from a mask for glass-like bevel effect.

    Returns (highlight_img, shadow_img) as RGB images.
    """
    size = mask.size[0]

    # Shift mask up for highlight (light from top)
    highlight_mask = Image.new('L', (size, size), 0)
    highlight_mask.paste(mask, (0, -blur_radius // 2))
    # Subtract original to get top edge
    from PIL import ImageChops
    highlight_edge = ImageChops.subtract(highlight_mask, mask)
    highlight_edge = highlight_edge.filter(ImageFilter.GaussianBlur(radius=blur_radius))

    # Shift mask down for shadow (dark at bottom)
    shadow_mask = Image.new('L', (size, size), 0)
    shadow_mask.paste(mask, (0, blur_radius // 2))
    shadow_edge = ImageChops.subtract(shadow_mask, mask)
    shadow_edge = shadow_edge.filter(ImageFilter.GaussianBlur(radius=blur_radius))

    # Convert to RGB
    highlight = Image.new('RGB', (size, size), (0, 0, 0))
    white = Image.new('RGB', (size, size), (255, 255, 255))
    highlight = Image.composite(white, highlight, highlight_edge)

    shadow = Image.new('RGB', (size, size), (0, 0, 0))
    # Shadow stays black, just use the mask for compositing later

    return highlight, shadow_edge


def generate_icon():
    """Generate the main app icon at 4x then downscale."""

    # ── Shield geometry ──
    cx, cy = SIZE // 2, SIZE // 2 + int(SIZE * 0.015)
    shield_w = int(SIZE * 0.44)
    shield_h = int(SIZE * 0.54)

    # ── 1. Background ──
    # For speed, build a small background and upscale
    bg_small = build_background(SIZE // 4)
    bg = bg_small.resize((SIZE, SIZE), Image.BILINEAR)

    # ── 2. Shield mask ──
    shield_mask = build_shield_mask(SIZE, cx, cy, shield_w, shield_h)
    # Slight blur for anti-aliased edges
    shield_mask_soft = shield_mask.filter(ImageFilter.GaussianBlur(radius=2))

    # ── 3. Gradient fill ──
    shield_top = cy - shield_h // 2
    shield_bottom = cy + shield_h // 2
    gradient = build_gradient(SIZE, shield_top, shield_bottom)

    # ── 4. Composite shield onto background ──
    img = bg.copy()
    img = Image.composite(gradient, img, shield_mask_soft)

    # ── 5. Inner bevel (glass-like highlight at top) ──
    bevel_highlight, bevel_shadow = build_inner_bevel(shield_mask, blur_radius=int(SIZE * 0.025))
    # Apply highlight subtly
    bevel_alpha = shield_mask_soft.point(lambda p: min(p, 60))
    img = Image.composite(bevel_highlight, img, bevel_alpha)

    # ── 6. Outer glow behind shield ──
    glow_cyan = build_glow(SIZE, cx, cy - int(SIZE * 0.05), CYAN, int(SIZE * 0.28), 0.25)
    glow_magenta = build_glow(SIZE, cx, cy + int(SIZE * 0.10), MAGENTA, int(SIZE * 0.22), 0.18)

    # Add glows (screen blend = additive)
    img = ImageChops.add(img, glow_cyan)
    img = ImageChops.add(img, glow_magenta)

    # Re-composite shield to keep it crisp above the glow
    img = Image.composite(gradient, img, shield_mask_soft)
    # Re-apply subtle highlight
    img = Image.composite(bevel_highlight, img, bevel_alpha)

    # ── 7. Cross ──
    cross_mask = build_cross_mask(SIZE, cx, cy, shield_w, shield_h)
    cross_mask_soft = cross_mask.filter(ImageFilter.GaussianBlur(radius=2))

    # Cross is semi-transparent white over the gradient
    cross_color_img = Image.new('RGB', (SIZE, SIZE), WHITE)
    # Make cross slightly translucent (let gradient show through a bit)
    cross_alpha = cross_mask_soft.point(lambda p: int(p * 0.92))
    img = Image.composite(cross_color_img, img, cross_alpha)

    # ── 8. Cross inner glow (subtle luminosity) ──
    cross_glow = Image.new('RGB', (SIZE, SIZE), (0, 0, 0))
    cross_glow_base = cross_mask.filter(ImageFilter.GaussianBlur(radius=int(SIZE * 0.015)))
    white_layer = Image.new('RGB', (SIZE, SIZE), (180, 220, 255))
    cross_glow = Image.composite(white_layer, cross_glow, cross_glow_base)
    cross_glow = cross_glow.filter(ImageFilter.GaussianBlur(radius=int(SIZE * 0.01)))
    img = ImageChops.add(img, cross_glow)

    # ── 9. Shield edge highlight (thin bright border at top) ──
    # Dilate shield mask slightly, subtract original = edge
    dilated = shield_mask.filter(ImageFilter.MaxFilter(size=5))
    edge = ImageChops.subtract(dilated, shield_mask)
    edge = edge.filter(ImageFilter.GaussianBlur(radius=3))

    # Only apply to top half for a light-from-above effect
    edge_gradient = Image.new('L', (SIZE, SIZE), 0)
    edge_draw = ImageDraw.Draw(edge_gradient)
    for y in range(SIZE):
        t = y / SIZE
        # Fade from bright at top to nothing at 60%
        if t < 0.6:
            val = int(255 * (1 - t / 0.6) * 0.35)
        else:
            val = 0
        edge_draw.line([(0, y), (SIZE - 1, y)], fill=val)

    edge_final = ImageChops.multiply(edge, edge_gradient)
    white_edge = Image.new('RGB', (SIZE, SIZE), WHITE)
    img = Image.composite(white_edge, img, edge_final)

    # ── 10. Downscale with high-quality resampling ──
    img = img.resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.LANCZOS)

    # ── Save ──
    out_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'assets', 'icon')
    os.makedirs(out_dir, exist_ok=True)

    out_path = os.path.join(out_dir, 'app_icon.png')
    img.save(out_path, 'PNG')
    print(f'Icon saved to {out_path}')

    # Foreground for adaptive icons
    fg_path = os.path.join(out_dir, 'app_icon_foreground.png')
    img.save(fg_path, 'PNG')
    print(f'Foreground saved to {fg_path}')

    return out_path


if __name__ == '__main__':
    path = generate_icon()
    print(f'Done! Icon at: {path}')
