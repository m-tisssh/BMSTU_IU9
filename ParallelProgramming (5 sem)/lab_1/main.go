package main

import (
	"fmt"
	"gonum.org/v1/plot"
	"gonum.org/v1/plot/plotter"
	"gonum.org/v1/plot/vg"
	"math/rand"
	"sync"
	"time"
)

const n = 900

func generateMatrix(n int) [][]float64 {
	matrix := make([][]float64, n)
	for i := 0; i < n; i++ {
		matrix[i] = make([]float64, n)
		for j := 0; j < n; j++ {
			matrix[i][j] = rand.Float64() * 100
		}
	}
	return matrix
}

func multiplyMatricesRow(A, B [][]float64) [][]float64 {
	C := make([][]float64, n)
	for i := 0; i < n; i++ {
		C[i] = make([]float64, n)
		for j := 0; j < n; j++ {
			sum := 0.0
			for k := 0; k < n; k++ {
				sum += A[i][k] * B[k][j]
			}
			C[i][j] = sum
		}
	}
	return C
}

func multiplyMatricesCol(A, B [][]float64) [][]float64 {
	C := make([][]float64, n)
	for i := 0; i < n; i++ {
		C[i] = make([]float64, n)
		for j := 0; j < n; j++ {
			C[i][j] = 0
		}
	}
	for j := 0; j < n; j++ {
		for k := 0; k < n; k++ {
			for i := 0; i < n; i++ {
				C[i][j] += A[i][k] * B[k][j]
			}
		}
	}
	return C
}

func compareMatrices(A, B [][]float64) bool {
	for i := 0; i < n; i++ {
		for j := 0; j < n; j++ {
			if A[i][j] != B[i][j] {
				return false
			}
		}
	}
	return true
}

func multiplyMatricesParallel(A, B [][]float64, workers int) [][]float64 {
	C := make([][]float64, n)
	for i := 0; i < n; i++ {
		C[i] = make([]float64, n)
	}

	var wg sync.WaitGroup
	wg.Add(workers)
	rowsPerWorker := n / workers

	for worker := 0; worker < workers; worker++ {
		go func(worker int) {
			defer wg.Done()
			startRow := worker * rowsPerWorker
			endRow := startRow + rowsPerWorker
			if worker == workers-1 {
				endRow = n
			}
			for i := startRow; i < endRow; i++ {
				for j := 0; j < n; j++ {
					sum := 0.0
					for k := 0; k < n; k++ {
						sum += A[i][k] * B[k][j]
					}
					C[i][j] = sum
				}
			}
		}(worker)
	}

	wg.Wait()
	return C
}

// Функция для построения графика
// Функция для построения графика
func plotGraph(xVals, yVals []float64) {
	p := plot.New() // теперь возвращает только один результат

	p.Title.Text = "Время выполнения от числа потоков"
	p.X.Label.Text = "Число потоков"
	p.Y.Label.Text = "Время выполнения (секунды)"

	pts := make(plotter.XYs, len(xVals))
	for i := range pts {
		pts[i].X = xVals[i]
		pts[i].Y = yVals[i]
	}

	line, err := plotter.NewLine(pts)
	if err != nil {
		panic(err)
	}

	p.Add(line)

	if err := p.Save(6*vg.Inch, 4*vg.Inch, "plot.png"); err != nil {
		panic(err)
	}

	fmt.Println("График сохранен как plot.png")
}

func main() {
	A := generateMatrix(n)
	B := generateMatrix(n)

	start := time.Now()
	C_1 := multiplyMatricesRow(A, B)
	fmt.Println("Время умножения по строкам:", time.Since(start).Seconds())

	start = time.Now()
	C_2 := multiplyMatricesCol(A, B)
	fmt.Println("Время умножения по столбцам:", time.Since(start).Seconds())

	if compareMatrices(C_1, C_2) {
		fmt.Println("Матрицы C_1 и C_2 совпадают")
	} else {
		fmt.Println("Матрицы C_1 и C_2 НЕ совпадают")
	}

	var workersSlice []int
	var timesSlice []float64

	for _, workers := range []int{2, 4, 8, 16, 32} {
		start = time.Now()
		C_3 := multiplyMatricesParallel(A, B, workers)
		elapsed := time.Since(start).Seconds()

		fmt.Printf("%d потоков: %v секунд\n", workers, elapsed)
		workersSlice = append(workersSlice, workers)
		timesSlice = append(timesSlice, elapsed)

		// Проверка правильности
		if compareMatrices(C_1, C_3) {
			fmt.Printf("Матрицы C_1 и C_3 (%d потока) совпадают\n", workers)
		} else {
			fmt.Printf("Матрицы C_1 и C_3 (%d потока) НЕ совпадают\n", workers)
		}
	}

	// Построение графика
	plotGraph(toFloat64Slice(workersSlice), timesSlice)
}

func toFloat64Slice(intSlice []int) []float64 {
	floatSlice := make([]float64, len(intSlice))
	for i, v := range intSlice {
		floatSlice[i] = float64(v)
	}
	return floatSlice
}
