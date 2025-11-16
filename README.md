# 🕹️ VGA Pong Game Processor  
### Real-time FPGA-based video game engine with custom VGA controller (640×480 @ 60Hz)

<p align="center">
<img src="https://github.com/user-attachments/assets/2699aab1-c573-43dd-a231-1b4ed187fef2" width="450" alt="Pong Game Screenshot"/>
</p>

> **A fully hardware-implemented Pong game running on an Xilinx Spartan-3E FPGA. Everything is rendered pixel-by-pixel using VHDL and custom sync timing logic.**

---

## 🎯 Overview  

This project implements a **real-time, two-player Pong system** using VHDL on the Xilinx Spartan-3E FPGA, generating a **640×480 VGA signal at 60Hz**.  
All graphics, timing, game logic, collisions, scoring, and resets are executed in hardware through synchronous digital logic.

**📅 Course:** COE758 – Digital Systems Engineering  
**🗓️ Date:** November 2025  

---

## ✨ Key Features  

- **Real-time gameplay** with physically controlled board switches  
- **Custom VGA controller** — HSYNC / VSYNC generation + active video region  
- **Pixel-level graphics engine** using RGB output  
- **Finite State Machine gameplay logic** (Gameplay → Scoring → Reset)  
- **Collision physics** for boundaries + paddles  
- **Automatic scoring + visual feedback** (ball turns red on goal)  
- **Timing validation via ChipScope Analyzer**

---

## 🧩 Game Design & Visual Elements  

| Component | Description |
|----------|-------------|
| Field | Green grass-style background |
| Paddles | Blue (P1) & Purple (P2) |
| Ball | Yellow (normal) → Red (goal scored) |
| Boundaries | White border + dashed center line |
| Controls | SW0/SW1 (P1), SW2/SW3 (P2) |

---

## 🛠️ Technical Breakdown  

### Hardware & Tools
- **FPGA:** Xilinx Spartan-3E  
- **IDE:** Xilinx ISE 13.4  
- **Language:** VHDL  
- **Input Clock:** 50 MHz  
- **Pixel Clock:** 25 MHz (internal divider)

### VGA Timing Specs
| Parameter | Value |
|-----------|-------|
| Resolution | 640×480 active |
| Full Frame | 800×525 cycles |
| Refresh Rate | ~59.5 Hz |
| HSYNC Pulse | 96 cycles |
| VSYNC Pulse | 2 lines |

### System Architecture  
- Clock Divider  
- Display Scan Counters  
- Sync Pulse Generator  
- Paddle Controller  
- Collision Engine  
- RGB Pixel Renderer  
- FSM Game Controller  
