# VGA-Pong-Game-Processor
A real-time two-player Pong game implemented on an Xilinx Spartan-3E FPGA using VHDL, generating VGA output at 640×480 resolution and 60 Hz refresh rate.

<img width="681" height="718" alt="image" src="https://github.com/user-attachments/assets/2699aab1-c573-43dd-a231-1b4ed187fef2" />



Project Overview

This project implements a complete video game processor that interfaces with a VGA monitor to display a functional Pong game. The system generates proper horizontal and vertical synchronization signals, renders dynamic game elements in real-time, and responds to user input through physical switches on the FPGA board.
Course: COE-758 Digital Systems Engineering
Date: November 2025

Features
VGA Signal Generation: 640×480 pixel display at 60 Hz with proper HSYNC and VSYNC timing
Real-Time Rendering: 25 MHz pixel clock driving frame-by-frame graphics updates

Game Elements:
Green playing field with white boundaries
Two colored paddles (blue and purple) with switch-based controls
Yellow ball with physics-based movement
Goal detection with visual feedback (ball turns red)
Automatic game reset after scoring


Collision Detection: Real-time detection and trajectory adjustment for ball-paddle and ball-boundary collisions
Finite State Machine: Three-state gameplay controller (Gameplay, Scoring, Reset)

Technical Implementation
Hardware

FPGA Board: Xilinx Spartan-3E
Development Tools: Xilinx ISE 13.4
Language: VHDL
Clock: 50 MHz input, divided to 25 MHz pixel clock

VGA Timing Specifications

Resolution: 640×480 (active region)

Total Frame: 800×525 clock cycles

Refresh Rate: ~59.5 Hz

Horizontal Sync: 96 clock cycles (negative polarity)

Vertical Sync: 2 lines (negative polarity)


Architecture

The design consists of multiple concurrent VHDL processes:

Clock Divider: Generates 25 MHz pixel clock from 50 MHz input

Display Controller: Manages horizontal and vertical counters

Sync Pulse Generator: Produces HSYNC and VSYNC signals

Collision Detection: Calculates ball trajectory changes

Paddle Controller: Handles switch inputs for player movement

Pixel Renderer: Generates RGB colour outputs for each pixel

Controls

SW0: Move left paddle up

SW1: Move left paddle down

SW2: Move right paddle up

SW3: Move right paddle down

