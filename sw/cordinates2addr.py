def coordinates_to_txt_index(row, col, matrix_size=31):
    """
    (row, column) of the matrix cordinates converts to row index of txt file.
    
    Args:
        row (int): Row cordinate on the matrix
        col (int): Column cordinate on the matrix
        matrix_size (int): Matrix size (default: 31)
        
    Returns:
        int: Row index of txt file
    """
    return row * matrix_size + col

def main():
    matrix_size = 31
    
    while True:
        try:
            row_input = input("Enter row ('q' for quit): ")
            
            if row_input.lower() == 'q':
                break
                
            row = int(row_input)
            
            col_input = input("Enter column: ")
            col = int(col_input)
            
            if row < 0 or row >= matrix_size or col < 0 or col >= matrix_size:
                print(f"Error: Cordinates must between 0 and {matrix_size - 1}!")
                continue
                
            txt_index = coordinates_to_txt_index(row, col, matrix_size)
            print(f"Addr: {txt_index}")
            
        except ValueError:
            print("Try again!")

if __name__ == "__main__":
    main()