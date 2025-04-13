import threading
import time
import random

class Philosopher(threading.Thread):
    def __init__(self, index, left_fork, right_fork, stop_event, log):
        super().__init__()
        self.index = index
        self.left_fork = left_fork
        self.right_fork = right_fork
        self.stop_event = stop_event    # флаг остановки 
        self.log = log

    def run(self):
        while not self.stop_event.is_set():
            self.think()
            self.eat()

    def log_state(self, state):
        timestamp = time.time()
        self.log.append((timestamp, self.index + 1, state))

    def think(self):
        self.log_state("размышляет")
        time.sleep(random.uniform(0.5, 1.5))

    # Про взаимоблокировку: чет философы начинают с левой вилки, нечет - с правой  
    def eat(self):
        right_fork, left_fork = (self.left_fork, self.right_fork) if self.index % 2 == 0 else (self.right_fork, self.left_fork)
        
        with right_fork:
            self.log_state("берёт правую вилку")
            time.sleep(0.1)

            with left_fork:
                self.log_state("берёт левую вилку")
                self.log_state("ест")
                time.sleep(random.uniform(0.5, 1.0))
                
                self.log_state("кладёт вилки на место")

def main(philosopher_count=5, run_time=10, output_file="philosophers_log.txt"):
    forks = [threading.Lock() for _ in range(philosopher_count)]
    stop_event = threading.Event()
    log = []

    # Каждый филисоф - это поток
    philosophers = [
        Philosopher(i, forks[i], forks[(i + 1) % philosopher_count], stop_event, log)
        for i in range(philosopher_count)
    ]

    # Pапуск потоков
    for p in philosophers:     
        p.start()

    time.sleep(run_time)
    stop_event.set()

    # Ждем завершения всех потоков
    for p in philosophers:
        p.join()

    # Запись логов в файл
    with open(output_file, "w") as f:
        f.write("Время, Философы, Состояние\n")
        for entry in log:
            timestamp, philosopher, state = entry
            formatted_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(timestamp))
            f.write(f"{formatted_time}, Философ {philosopher}, {state}\n")

main()
