fin = open('../programs/program.in', 'r')
fmt = open('fmt.v', 'r')

fmt_map = {}

word = 32

for f in fmt:
    line = f.split()
    if len(line)<3 : continue
    if "3'" in line[2] or "6'" in line[2]: line[2] = line[2][3:]
    fmt_map[line[1]] = line[2]

for key in fmt_map:
    print(key, " ", fmt_map[key])

def twoscomp(num):
    return str((1<<word) + int(num))

# read input program
fout = open("input.txt", 'w')
for l in fin:
    instr = ""
    line = l.split()
    opcode = fmt_map[line[0].upper()]
    reg1 = ""
    reg2 = ""
    filler = ""
    imm = ""
    imm2 = ""
    next_val = ""
    if len(line) == 4:
        reg1 = line[1][:-1]
        if reg1 in fmt_map:
            filler = '0'*(word-6-3)
            instr = opcode+fmt_map[reg1]+filler
            line[2] = line[2][:-1]
            imm = '00'+'0'*(15-len(bin(int(line[2]))[2:]))+bin(int(line[2]))[2:] + '0'*(15-len(bin(int(line[3]))[2:]))+ bin(int(line[3]))[2:]
            imm2 = '0'*word
        else:
            line[1] = line[1][:-1]
            line[2] = line[2][:-1]
            next_val = bin(int(line[1]))[2:]
            filler = '0'*(word-6)
            instr = opcode+filler
            imm = '0'*(15-len(next_val))+next_val +'0'*(15-len(bin(int(line[2]))[2:]))+bin(int(line[2]))[2:]
            imm2 = bin(int(line[3]))[2:]
            
            imm = '0'*(word-len(imm)) + imm
            imm2 = '0'*(word-len(imm2)) + imm2
            imm = '0'*(word-len(imm)) + imm
            imm2 = '0'*(word-len(imm2)) + imm2
    elif len(line) == 3: 
        reg1 = line[1][:-1]
        reg2 = line[2]
        if reg1 in fmt_map:
            reg1 = fmt_map[line[1][:-1]]
            if reg2 in fmt_map:
                reg2 = fmt_map[reg2]
                filler = '0'*20
                instr = opcode+reg1+reg2+filler
                imm = '0'*word
            else: 
                # handle negative numbers
                if int(reg2)<0:
                    reg2 = twoscomp(reg2)
                imm = bin(int(reg2))[2:]
                imm = '0'*(word-len(imm)) + imm
                filler = '0'*(word-9)
                instr = opcode+reg1+filler
        else:
            instr = opcode + '0'*(word-6-len(bin(int(reg1))[2:])) + bin(int(reg1))[2:]
            imm = bin(int(reg2))[2:]
            imm = '0'*(word-len(imm)) + imm

        imm2 = '0'*word
    elif len(line) == 2:
        reg1 = line[1]
        if reg1 in fmt_map:
            reg1 = fmt_map[reg1]
            filler = '0'*(word-9)
            instr = opcode+reg1+filler
            imm = '0'*word
        else:
            # handle negative number
            if int(reg1)<0:
                reg1 = twoscomp(reg1)
            imm = bin(int(reg1))[2:]
            # print("imm: ", bin(int(reg1)))
            imm = '0'*(word-len(imm)) + imm
            filler = '0'*(word-6)
            instr = opcode+filler
        imm2 = '0'*word
    elif len(line) == 1:
        filler = '0'*(word-6)
        instr = opcode+filler
        imm = '0'*word
        imm2 = '0'*word
    
    fout.write(instr+'\n')
    fout.write(imm+'\n')
    fout.write(imm2+'\n')

fout.close()

print("Program Data Converted to bin")
