import sys
import re
import os

def extract_machine_code_from_comments(input_file):
    """
    Extracts machine code from comments in assembly file.
    The file format should have machine code in hex after the instruction.
    Handles nop instructions by assigning them the standard encoding.
    
    Example:
        addi x2, x0, 5          # ... Machine Code
        nop                     # Encodes to 00000013
    
    Args:
        input_file (str): The path to the input assembly file.
    
    Returns:
        list: List of machine code words (hex strings).
    """
    machine_codes = []
    with open(input_file, 'r') as f:
        for line in f:
            # Skip empty lines and full comment lines
            if not line.strip() or line.strip().startswith('#'):
                continue
            
            # Handle nop instructions explicitly
            if 'nop' in line.lower():
                machine_codes.append('00000013')  # Standard nop encoding
                continue
            
            # Try to extract hex machine code from the end of the line
            # Pattern: look for 8-character hex numbers
            hex_pattern = r'[0-9A-Fa-f]{8}'
            matches = re.findall(hex_pattern, line)
            
            if matches:
                # Take the first (or last) match - usually the machine code
                # Filter for lines that look like instructions
                if any(instr in line for instr in ['addi', 'add', 'sub', 'and', 'or', 'slt', 'lw', 'sw', 'beq', 'jal']):
                    machine_codes.append(matches[-1])  # Take the last hex number
    
    return machine_codes

def assemble_file_to_txt(input_file, output_file=None):
    """
    Extracts machine code from RISC-V assembly file and saves to text file.
    
    Args:
        input_file (str): The path to the input assembly file.
        output_file (str): The path to the output text file. If None, uses same name with .txt extension.
    """
    if output_file is None:
        # Default output: same filename with .txt extension
        output_file = os.path.splitext(input_file)[0] + '.txt'
    
    machine_codes = extract_machine_code_from_comments(input_file)
    
    if not machine_codes:
        print(f"Warning: No machine code found in '{input_file}'")
        return
    
    # Write machine codes to output file
    os.makedirs(os.path.dirname(output_file) or '.', exist_ok=True)
    with open(output_file, 'w') as f:
        for code in machine_codes:
            f.write(code + '\n')
    
    print(f"Assembly file '{input_file}' processed.")
    print(f"Machine code extracted: {len(machine_codes)} instructions")
    print(f"Machine code text file saved to '{output_file}'")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python assemble.py <input_assembly_file.s>")
        sys.exit(1)
    
    input_filename = sys.argv[1]
    assemble_file_to_txt(input_filename)

