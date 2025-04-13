import numpy as np
from mpi4py import MPI
import time

# Parameters
N = 8000  # Size of the matrix
epsilon = 1e-6  # Convergence criterion

def initialize_system(N):
    """Initialize the system Ax = b"""
    A = np.full((N, N), 1.0)
    np.fill_diagonal(A, 2.0)
    b = np.full(N, N + 1.0)
    x = np.zeros(N)
    return A, b, x

def mat_vec_mult(A, v):
    """Matrix-vector multiplication"""
    return np.dot(A, v)

def main():
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()

    # Initialize system on process 0
    if rank == 0:
        A, b, x = initialize_system(N)
    else:
        A = np.empty((N, N), dtype=np.float64)
        b = np.empty(N, dtype=np.float64)
        x = np.empty(N, dtype=np.float64)

    # Broadcast data
    comm.Bcast(A, root=0)
    comm.Bcast(b, root=0)

    # Divide A into rows
    rows_per_process = N // size
    extra_rows = N % size

    if rank < extra_rows:
        local_rows = rows_per_process + 1
        start_row = rank * local_rows
    else:
        local_rows = rows_per_process
        start_row = rank * rows_per_process + extra_rows

    local_A = A[start_row:start_row + local_rows, :]
    local_b = b[start_row:start_row + local_rows]

    start_time = time.time()

    # Iterative process
    local_x = x  # Initialize local_x to the full size
    global_x = np.zeros(N)  # To hold the reduced results
    global_r = np.zeros(N)  # To hold the full residual

    for iteration in range(1000):  # Maximum number of iterations
        local_r = np.dot(local_A, local_x) - local_b
        
        # Sum local residuals to global
        comm.Allreduce(local_r, global_r, op=MPI.SUM)
        
        # Use the full matrix A for multiplication
        Ar = mat_vec_mult(A, global_r)  # Using the full matrix A
        
        tau_numerator = np.dot(global_r, Ar)
        tau_denominator = np.dot(Ar, Ar)
        
        if tau_denominator != 0:
            tau = tau_numerator / tau_denominator
            # Update the global x
            global_x = local_x - tau * global_r[start_row:start_row + local_rows]
            comm.Allreduce(global_x, local_x, op=MPI.SUM)

        # Check for convergence
        if np.linalg.norm(global_r) < epsilon:
            break

    # Collect result
    final_x = np.zeros(N)
    comm.Reduce(local_x, final_x, op=MPI.SUM, root=0)
    
    if rank == 0:
        end_time = time.time()
        print(f"Solution x: {final_x}")
        print(f"Number of processors used: {size}")
        print(f"Execution time: {end_time - start_time} seconds")

if __name__ == "__main__":
    main()
