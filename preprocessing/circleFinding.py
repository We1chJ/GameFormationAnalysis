"""
soccer_circle_detection.py

Detect soccer player circles (22 expected),
output their center coordinates with origin at lower-left,
and visualize circles + labels: ID, coordinates, radius.
Circles are filled: first 11 red, next 11 blue.

Usage:
    python soccer_circle_detection.py --image topdown.png --debug
"""

import cv2
import numpy as np
import argparse
import math
import matplotlib.pyplot as plt

##############################
# Detection Helpers
##############################

def detect_with_hough(gray, dp=1.2, minDist=20, param1=60, param2=25, minRadius=5, maxRadius=60):
    circles = cv2.HoughCircles(gray, cv2.HOUGH_GRADIENT, dp=dp, minDist=minDist,
                               param1=param1, param2=param2,
                               minRadius=minRadius, maxRadius=maxRadius)
    if circles is None:
        return []
    circles = np.round(circles[0, :]).astype(int)
    return [(int(x), int(y), int(r)) for x, y, r in circles]

def detect_with_contours(img, min_area=50, max_area=5000):
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    thr = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                cv2.THRESH_BINARY_INV, 15, 7)
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5,5))
    clean = cv2.morphologyEx(thr, cv2.MORPH_OPEN, kernel, iterations=1)
    clean = cv2.morphologyEx(clean, cv2.MORPH_CLOSE, kernel, iterations=2)

    contours, _ = cv2.findContours(clean, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    circles = []
    for c in contours:
        area = cv2.contourArea(c)
        if area < min_area or area > max_area:
            continue
        (x, y), r = cv2.minEnclosingCircle(c)
        perimeter = cv2.arcLength(c, True)
        if perimeter <= 0:
            continue
        circularity = 4 * math.pi * area / (perimeter * perimeter)
        if circularity < 0.35:
            continue
        circles.append((int(round(x)), int(round(y)), int(round(r))))
    return circles

def select_top_n_by_radius(circles, expected_n):
    if len(circles) <= expected_n:
        return circles
    radii = [c[2] for c in circles]
    med_r = np.median(radii)
    sorted_c = sorted(circles, key=lambda c: abs(c[2] - med_r))
    return sorted_c[:expected_n]

def enforce_common_radius(circles):
    if not circles:
        return circles, None
    med = int(round(np.median([c[2] for c in circles])))
    return [(x, y, med) for (x, y, _) in circles], med

def convert_to_lower_left(circles, img_h):
    return [(x, img_h - y, r) for (x, y, r) in circles]

##############################
# Main Detection Pipeline
##############################

def detect_players(image_path, expected_n=22, debug=False):
    img = cv2.imread(image_path)
    if img is None:
        raise FileNotFoundError(image_path)

    h, w = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    gray_blur = cv2.medianBlur(gray, 5)

    # 1️⃣ Try Hough Circles
    circles = detect_with_hough(
        gray_blur,
        dp=1.2,
        minDist=max(15, min(h,w)//30),
        param1=80,
        param2=28,
        minRadius=min(h,w)//120,
        maxRadius=min(h,w)//30
    )
    if debug:
        print("Hough found:", len(circles))

    # 2️⃣ If not enough, contour fallback
    if len(circles) < expected_n:
        contour_circles = detect_with_contours(
            img,
            min_area=int(0.3 * math.pi * (min(h,w)/120)**2),
            max_area=int(3.0 * math.pi * (min(h,w)/30)**2)
        )
        if debug:
            print("Contours found:", len(contour_circles))
        circles += contour_circles

    # Duplicate removal
    unique = []
    tol = max(4, min(h,w)//60)
    for x,y,r in circles:
        if all((x-cx)**2+(y-cy)**2 > tol*tol for cx,cy,_ in unique):
            unique.append((x,y,r))
    circles = unique
    if debug: print("After filter:", len(circles))

    # Keep best 22
    circles = select_top_n_by_radius(circles, expected_n)

    # Force single radius
    circles, common_r = enforce_common_radius(circles)

    # Convert to lower-left origin
    circles_ll = convert_to_lower_left(circles, h)

    # Sort left→right, bottom→top
    circles_ll.sort(key=lambda c: (c[0], c[1]))

    detected = [{
        "id": i+1,
        "x": float(x),
        "y": float(y),
        "radius": float(r)
    } for i,(x,y,r) in enumerate(circles_ll)]

    return {
        "image_shape": (w, h),
        "detected": detected,
        "common_radius": float(common_r) if common_r is not None else None,
        "original": img
    }

##############################
# Visualization
##############################

def plot_detected_players(result, save_path=None):
    players = result["detected"]
    img_w, img_h = result["image_shape"]

    plt.figure(figsize=(12, 7))
    ax = plt.gca()

    for p in players:
        x, y, r = p["x"], p["y"], p["radius"]
        # First 11 players red, next 11 blue
        color = 'red' if p["id"] <= 11 else 'blue'
        ax.add_patch(plt.Circle((x, y), r, fill=True, color=color, alpha=0.5))  # Filled circle
        ax.add_patch(plt.Circle((x, y), r, fill=False, color='black', lw=1))  # Black outline
        plt.text(x, y+r+4, f"ID {p['id']}", ha="center", va="bottom", fontsize=9, color="black")
        plt.text(x+r+3, y, f"({x:.0f},{y:.0f})\nr={r:.0f}",
                 ha="left", va="center", fontsize=7, color="black")

    plt.xlim(0, img_w)
    plt.ylim(0, img_h)
    plt.gca().set_aspect("equal")
    plt.grid(True)
    plt.title("Detected Soccer Players — Origin at Lower Left")
    plt.xlabel("X (px)")
    plt.ylabel("Y (px)")

    if save_path:
        plt.savefig(save_path, dpi=300)
        print("Plot saved to:", save_path)

    plt.show()

##############################
# Main run
##############################

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True)
    parser.add_argument("--expected", type=int, default=22)
    parser.add_argument("--debug", action="store_true")
    args = parser.parse_args()

    result = detect_players(args.image, expected_n=args.expected, debug=args.debug)

    print("\nDetected Players:")
    for p in result["detected"]:
        print(f"ID {p['id']:02d}: x={p['x']:.1f}, y={p['y']:.1f}, r={p['radius']:.1f}")

    plot_detected_players(result, save_path="player_plot.png")