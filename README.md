# Design of Computer Systems 1. project - Processor with a simple instruction set

The aim of this project is to implement a VHDL processor that will be able to execute a program written in the extended version of the BrainF*ck language. Although the language uses only eight simple instructions, it is a computationally complete set, with the help of which any algorithm can be implemented.

The language uses instructions encoded using printable 8-bit characters. The implemented processor will process these characters. For simplicity, we will consider only 10 commands listed in the table below. The program consists of a sequence of these commands. Unknown commands are ignored, which makes it possible to insert text comments directly into the program. Program execution starts with the first instruction and ends as soon as the end of the sequence (character with ASCII value 0) is detected. The program and data are stored in the same memory with a capacity of 8192 8-bit items. The program is stored from address 0 and is executed non-linearly (it may contain jumps). Data is stored from address 0x1000. Let the memory content be initialized to zero for simplicity. To access the memory, a pointer (ptr) is used, which can be moved by a position to the left or right. Memory is understood as a circular buffer storing 8-bit and unsigned numbers. Moving to the left from address 0x1000 means moving the pointer to the end of memory corresponding to address 0x1FFF.

Let the implemented processor support the commands defined in the following table. Operation codes that are not in the table are ignored by the processor.

In the case of commands manipulating a pointer to the program code (PC instruction reader), such as [, ], ( a ), it is necessary to detect the corresponding the right, or the left, from the avork. There are several options, the simplest is to gradually increment (or decrement) the pointer and count the number of brackets (see below). After the reset, the ptr pointer points to address 0x1000.

| instruction | operating code | meaning | equivalent in C |
| --- | --- | --- | --- |
| > | 0x3E | incrementing the pointer value | ptr += 1; |
| < | 0x3C | decrementing the pointer value | ptr -= 1; |
| + | 0x2B | incrementing the value of the current cell | *ptr += 1; |
| - | 0x2D | decrementing the value of the current cell | *ptr -= 1; |
| ] | 0x5B | if the value of the current cell is zero, jump after the corresponding command ] otherwise continue with the next character | while (*ptr) { |
| [ | 0x5D | if the value of the current cell is not zero, jump after the corresponding command [ otherwise continue with the next character | } |
| ( | 0x28 | the beginning of the do-while cycle | do { |
| ) | 0x29 | if the value of the current cell is not zero, jump after the corresponding command  ( otherwise, continue with the next character | } while (*ptr) |
| . | 0x2E | print the value of the current cell| putchar(*ptr); |
| , | 0x2C | read the value and store it in the current cell | *ptr = getchar(); |
| null | 0x00 | stop program execution | return;|

## Microcontroller
In order to be able to execute a meaningful program, it is necessary to supplement the processor with program memory, data memory and an input-output interface enabling data to be read and written out. In our case, we will consider a common program and data memory with a total capacity of 8kB.

In practice, it would be possible to solve the input using a matrix keyboard typically containing the characters 0-9 and two special symbols. As soon as the processor encounters an instruction to load a value (operation code from 0x2C), execution is suspended until one of the keyboard keys is pressed. The keyboard would be served by a controller that would give an 8-bit value to the input of the processor, which corresponds to the ASCII code of the pressed keys.
The data output can be solved using the LCD display, where characters are gradually written out. Moving the cursor on the display would be handled automatically.

In order to facilitate code development, you have prepared an environment emulating the above-mentioned peripherals and a set of basic tests.
