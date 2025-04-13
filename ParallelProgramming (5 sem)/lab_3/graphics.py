import pandas as pd
import matplotlib.pyplot as plt

# Чтение данных
data = pd.read_csv("results.csv")

# Построение графика
plt.figure(figsize=(10, 6))
plt.plot(data["Threads"], data["Time"], marker='o', label="Time vs Threads")
plt.xlabel("Number of Threads")
plt.ylabel("Execution Time (seconds)")
plt.title("Execution Time vs Number of Threads")
plt.grid(True)
plt.legend()
plt.savefig("performance_plot.png")  # Сохранение графика
plt.show()
