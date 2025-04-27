def txt_index_to_coordinates(txt_index, matrix_size=31):
    """
    Row index in txt file of an image translates to image cordinates as s(row, column).
    
    Args:
        txt_index (int): Row index in txt file (Decimal)
        matrix_size (int): Matrix size (default: 31)
        
    Returns:
        tuple: (row, column) of the matrix
    """
    row = txt_index // matrix_size
    col = txt_index % matrix_size
    return (row, col)

def main():
    matrix_size = 31
    
    while True:
        try:
            user_input = input("Enter addr (q to quit): ")
            
            if user_input.lower() == 'q':
                break
                
            txt_index = int(user_input)
            if txt_index < 0 or txt_index >= matrix_size * matrix_size:
                print(f"Error: Index should be inside {matrix_size * matrix_size - 1}")
                continue
                
            row, col = txt_index_to_coordinates(txt_index, matrix_size)
            print(f"s({row},{col})")
            
        except ValueError:
            print("Try again.")

if __name__ == "__main__":
    main()