# INP project 1 - Processor with a simple instruction set

## Author

- **Name:** Maksim Kalutski
- **Login:** xkalut00

## Project Overview

This project involves the implementation of a VHDL processor capable of executing programs written in an extended version of the BrainF*ck language. This language utilizes a computationally complete set of eight simple instructions, enabling the implementation of any algorithm.

## Features

- **Processor Design**: Implementation in VHDL, simulating an 8-bit CPU capable of interpreting the extended BrainF*ck language.
- **Memory Management**: Unified memory for program and data storage with a capacity of 8192 8-bit items, starting from address 0 for programs and 0x1000 for data.
- **Input/Output**: Incorporates an interface for input via a keypad and output through an LCD display, handling ASCII characters.
- **Error Handling**: Ignores unknown commands, allowing text comments to be inserted directly in the program.
- **Program Execution**: Non-linear execution with support for jumps; terminates when an ASCII null (value 0) character is detected.

## Instructions
## Instructions

| instruction | operating code | meaning                                                                                                                           | equivalent in C   |
|-------------|----------------|-----------------------------------------------------------------------------------------------------------------------------------|-------------------|
| >           | 0x3E           | incrementing the pointer value                                                                                                    | ptr += 1;         |
| <           | 0x3C           | decrementing the pointer value                                                                                                    | ptr -= 1;         |
| +           | 0x2B           | incrementing the value of the current cell                                                                                        | *ptr += 1;        |
| -           | 0x2D           | decrementing the value of the current cell                                                                                        | *ptr -= 1;        |
| ]           | 0x5B           | if the value of the current cell is zero, jump after the corresponding command ] otherwise continue with the next character       | while (*ptr) {    |
| [           | 0x5D           | if the value of the current cell is not zero, jump after the corresponding command [ otherwise continue with the next character   | }                 |
| (           | 0x28           | the beginning of the do-while cycle                                                                                               | do {              |
| )           | 0x29           | if the value of the current cell is not zero, jump after the corresponding command  ( otherwise, continue with the next character | } while (*ptr)    |
| .           | 0x2E           | print the value of the current cell                                                                                               | putchar(*ptr);    |
| ,           | 0x2C           | read the value and store it in the current cell                                                                                   | *ptr = getchar(); |
| null        | 0x00           | stop program execution                                                                                                            | return;           |

## Hardware Requirements

- **Microcontroller Integration**: Supplemental program memory, data memory, and input-output interfaces for reading and
  writing data.
- **Peripheral Emulation**: The development environment includes emulation of the necessary peripherals and a set of
  basic tests.

## File Structure

- `cpu.vhd`: Contains the VHDL code for the processor implementation.
- `login.b`: A BrainF*ck program file that prints a specified string.
