# Graph-Traversal-ASIC
Simple ASIC with instructions optimized for traversing between nodes per iteration

Write programs into ```./programs/program.in```

Assemble program by running ```./cpu/conv.py```

**Memory Map**
- 32-bit CPU
- Stores up to 2^11 nodes
- Can form a strongly connected component (2^22 edges)
- 2^11 memory addresses for tracking visited nodes
- 2^11 memory addresses for stack (DFS)

**Details**
- 6 clock cycles per instruction (unpipelined)
  - Instruction fetch, register fetch, decode, execute, write back check, parallel write backs
- Node register:
  - 1 bit for traversal type (DFS or BFS)
  - 11 bits for current node
  - 11 bits for current child
 - Stack pointer:
   - Stores address of current node register
