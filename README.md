# UVM  D-flipflop
Behavior of a D-Flip-Flop:
A D-flip-flop is a sequential logic element that captures the value of its input (din) at the rising edge of the clock and propagates it to the output (dout) after one clock cycle. The behavior can be summarized as:

At the rising edge of the clock:

If rst is high, dout is reset to 0.

If rst is low, dout takes the value of din.
A D-flip-flop is a sequential logic element that:

Captures the input (din) at the rising edge of the clock.

Propagates the captured input to the output (dout) after one clock cycle.

This means:

The output (dout) at time t is equal to the input (din) at time t-1 (the previous clock cycle).

Example:
Consider the following sequence of inputs and outputs for a D-flip-flop:

Clock Cycle	din (Input)	dout (Output)
0	1	X (initial state, unknown)
1	0	1 (captured from cycle 0)
2	1	0 (captured from cycle 1)
3	1	1 (captured from cycle 2)
4	0	1 (captured from cycle 3)
Here:

At cycle 1, dout is 1 (from din at cycle 0).

At cycle 2, dout is 0 (from din at cycle 1).

At cycle 3, dout is 1 (from din at cycle 2).

At cycle 4, dout is 1 (from din at cycle 3).

![image](https://github.com/user-attachments/assets/c2c77de7-acc2-4f61-a18f-0845529e8843)
