import math

block_sad_values = []
block_count = 0

def calculate_distance_from_center(sad_list, index):
    """Calculate squared distance from position (64,64)"""
    return (sad_list[index][1] - 64)**2 + (sad_list[index][2] - 64)**2

def hex_to_int(hex_str):
    """Convert a hexadecimal string to integer"""
    try:
        return int(hex_str, 16)
    except ValueError as e:
        print(f"Invalid hexadecimal input: {e}")
        return 0

def read_hex_file_to_2d_list(filename):
    """Read a file with hex values and convert to 2D integer list"""
    data = []
    try:
        with open(filename, 'r') as file:
            for line in file:
                row = [hex_to_int(value) for value in line.split()]
                data.append(row)
    except IOError as e:
        print(f"Error opening file: {filename}, {e}")
    return data

def calculate_sad(reference_block, search_frame, start_x, start_y, sad_results):
    """Calculate Sum of Absolute Differences between reference block and search area"""
    sad_value = 0
    for row in range(16):
        for col in range(16):
            sad_value += abs(reference_block[row][col] - search_frame[start_x + row][start_y + col])
    sad_results.append([start_y, start_x, sad_value])

def minSADFind(reference_block, search_frame):
    """Find the best matching block using Sum of Absolute Differences"""
    min_sad = math.inf
    matching_block_count = 0
    
    for start_x in range(16):
        for start_y in range(16):
            # Only process blocks at even-even or odd-odd coordinates
            if (start_x % 2 == 0 and start_y % 2 == 0) or (start_x % 2 == 1 and start_y % 2 == 1):
                block_sad_values = []
                calculate_sad(reference_block, search_frame, start_x, start_y, block_sad_values)
                print(block_sad_values, matching_block_count, end=" ")
                matching_block_count += 1
                
                # Update minimum SAD if current block has lower SAD
                if block_sad_values[0][2] < min_sad:
                    min_sad = block_sad_values[0][2]
                    best_match_y, best_match_x = block_sad_values[0][0], block_sad_values[0][1]
        print("\n")
    
    print("min sad y,x coordinates: ", best_match_y, best_match_x)
    print("min sad value: ", min_sad)

# File paths
reference_file = "reference.txt"
search_file = "search.txt"

# Read input files
reference_block = read_hex_file_to_2d_list(reference_file)
search_area = read_hex_file_to_2d_list(search_file)

# Print dimensions
print(len(reference_block), len(reference_block[0]))
print(len(search_area), len(search_area[0]))

# Perform motion estimation
minSADFind(reference_block, search_area)
