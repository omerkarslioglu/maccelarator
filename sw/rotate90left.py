#!/usr/bin/env python3

def rotate_right_90_degrees(matrix):
    """Rotate a matrix 90 degrees to the right (counterclockwise)"""
    # Get dimensions
    rows = len(matrix)
    if rows == 0:
        return []
    cols = len(matrix[0])
    
    # Create new matrix with swapped dimensions
    rotated = [[None for _ in range(rows)] for _ in range(cols)]
    
    # Fill in the rotated matrix
    for r in range(rows):
        for c in range(cols):
            # When rotating 90 degrees right:
            # new_col = rows - 1 - original_row
            # new_row = original_col
            rotated[c][rows - 1 - r] = matrix[r][c]
    
    return rotated

def rotate_left_90_degrees(matrix):
    """Rotate a matrix 90 degrees to the left (counterclockwise)"""
    # Get dimensions
    rows = len(matrix)
    if rows == 0:
        return []
    cols = len(matrix[0])
    
    # Create new matrix with swapped dimensions
    rotated = [[None for _ in range(rows)] for _ in range(cols)]
    
    # Fill in the rotated matrix
    for r in range(rows):
        for c in range(cols):
            # When rotating 90 degrees left (counterclockwise):
            # This is the exact opposite of right rotation
            rotated[cols - 1 - c][r] = matrix[r][c]
    
    return rotated

# The provided matrix data
matrix_data = """35 CF E1 35 DC DA E2 DF E1 E2 DA DF DC 35 D7 E0 
DA DF DF CF 00 E0 DA DF D7 E2 DA E0 DF DF E2 D7 
35 E0 DF DC E1 DF E0 CC DF DC CC DA DF 00 DF 00 
E1 CC E1 E1 E2 00 CF 00 CF CC DC 00 E0 DF DC DF 
DF 35 CC E2 DF E1 E1 CF 35 E2 D7 D7 E0 00 E2 00 
E1 CC CC DC E2 E0 E2 E1 35 E1 E0 E0 DA DC E1 DF 
E1 CF 35 DC CF DA CF 00 E2 35 D7 DA 35 D7 DF CF 
E1 E2 DA DC E0 E2 E0 CC 35 00 E0 CC DF E1 DA D7 
E2 CC DC DF DA 35 CC E0 E0 E0 00 E1 CC CC CF 00 
D7 35 E0 CC CF 00 E0 E2 E1 CF E0 DF DF DA 00 CF 
35 DF 00 E2 DC DF 00 35 DF 00 35 00 35 35 D7 CF 
E0 35 CC E0 D7 D7 35 00 DA 35 CC DA CF 00 DC E2 
E0 DC 35 CC 00 E2 E0 DC DF E2 00 35 00 D7 DA E1 
D7 D7 CF D7 DC CF DA CF CC DA CC 35 DF D7 DC 35 
D7 DF D7 CC E0 E0 E1 D7 CC 35 D7 35 D7 DF CC E2 
00 CC D7 CC D7 CC DC CC D7 E2 D7 DC E0 DF DF DC"""

# Parse the matrix
matrix = []
for line in matrix_data.strip().split('\n'):
    row = line.strip().split()
    matrix.append(row)

# Get dimensions
rows = len(matrix)
cols = len(matrix[0])
print(f"Original matrix dimensions: {rows} rows x {cols} columns")

# Rotate the matrix
rotated_matrix = rotate_left_90_degrees(matrix)

# Display the result
print("\nRotated matrix (90 degrees left):")
for row in rotated_matrix:
    print(' '.join(row))

# Let's also save the result to a file
with open("rotated_matrix_result.txt", "w") as f:
    for row in rotated_matrix:
        f.write(' '.join(row) + '\n')

print("\nRotated matrix has been saved to 'rotated_matrix_result.txt'")