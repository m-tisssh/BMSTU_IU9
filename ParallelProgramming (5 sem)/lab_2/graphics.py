import matplotlib.pyplot as plt
import numpy as np

# Data
processors = np.array([1, 2, 4, 8, 16, 32])
times = np.array([28.731112, 25.263491, 24.8330473, 26.5138931, 27.484934, 29.4598234])

# Calculate speedup and efficiency
speedup = times[0] / times  # Speedup = T1 / Tp
efficiency = speedup / processors  # Efficiency = Speedup / p

# Plot
plt.figure(figsize=(15, 5))

# Time vs Processors
plt.subplot(1, 3, 1)
plt.plot(processors, times, marker='o', color='b', label='Execution Time')
plt.xlabel('Number of Processors')
plt.ylabel('Execution Time (s)')
plt.title('Execution Time vs Number of Processors')
plt.grid(True)
plt.legend()

# Efficiency vs Processors
plt.subplot(1, 3, 2)
plt.plot(processors, efficiency, marker='o', color='g', label='Efficiency')
plt.xlabel('Number of Processors')
plt.ylabel('Efficiency')
plt.title('Efficiency vs Number of Processors')
plt.grid(True)
plt.legend()

# Speedup vs Processors
plt.subplot(1, 3, 3)
plt.plot(processors, speedup, marker='o', color='r', label='Speedup')
plt.xlabel('Number of Processors')
plt.ylabel('Speedup')
plt.title('Speedup vs Number of Processors')
plt.grid(True)
plt.legend()

plt.tight_layout()
plt.show()
