import sys
from OpenGL.GL import *
from OpenGL.GLUT import *
from OpenGL.GLU import *

WIDTH, HEIGHT = 720, 720

# Матрица для хранения изображения
pixels = [[[255, 255, 255] for _ in range(WIDTH)] for _ in range(HEIGHT)]  # Изначально все пиксели белые

# Список для хранения координат точек
points = []

fill_polygon = False
filter_polygon = False

# Функция для изменения значения пикселя в матрице pixels
def set_pixel(x, y, color):
    pixels[y][x] = color

def draw_line_based(p1, p2, color):
    x1, y1 = p1
    x2, y2 = p2

    dx = x2 - x1
    dy = y2 - y1

    # Вычисляем шаг изменения координаты
    if abs(dx) > abs(dy):
        steps = abs(dx)
    else:
        steps = abs(dy)

    x_increment = dx / steps
    y_increment = dy / steps

    x, y = x1, y1
    # Рисуем каждую точку линии
    for _ in range(int(steps)):
        set_pixel(int(x), int(y), color)
        x += x_increment
        y += y_increment
    set_pixel(int(x2), int(y2), color)

# Функция для отрисовки линии алгоритмом Брезенхема
def draw_line_bresenham(p1, p2, color):
    x1, y1 = p1
    x2, y2 = p2

    dx = abs(x2 - x1)
    dy = abs(y2 - y1)

    # Вычисляем начальное значение m, e и De
    m = int(round(255 * (dy / dx)))  # Доля интенсивности
    e = m // 2

    x, y = x1, y1
    sx = 1 if x1 < x2 else -1
    sy = 1 if y1 < y2 else -1

    if dx > dy:
        # Прямая ближе к горизонтальной
        e = -dx / 2
        for _ in range(dx + 1):
            set_pixel(x, y, [m for _ in color])  # Уменьшаем интенсивность в зависимости от площади пикселя
            x += sx
            e += dy
            if e >= 0:
                y += sy
                e -= dx
        # Коррекция смещения на один пиксель для горизонтальных линий
        set_pixel(x2, y2, [m for _ in color])
    else:
        # Прямая ближе к вертикальной
        e = -dy / 2
        for _ in range(dy + 1):
            set_pixel(x, y, [m for _ in color])  # Уменьшаем интенсивность в зависимости от площади пикселя
            y += sy
            e += dx
            if e >= 0:
                x += sx
                e -= dy
        # Коррекция смещения на один пиксель для вертикальных линий
        set_pixel(x2, y2, [m for _ in color])


def is_point_inside_polygon(x, y):
    odd_nodes = False
    j = len(points) - 1
    for i in range(len(points)):
        if (points[i][1] < y and points[j][1] >= y) or (points[j][1] < y and points[i][1] >= y):
            if points[i][0] + (y - points[i][1]) / (points[j][1] - points[i][1]) * (points[j][0] - points[i][0]) < x:
                odd_nodes = not odd_nodes
        j = i
    return odd_nodes

# Функция для заполнения многоугольника
def fill_polygon_scanline():
    min_y = min(point[1] for point in points)
    max_y = max(point[1] for point in points)

    # Проходим по каждой строке сканирования
    for y in range(min_y, max_y + 1):
        intersections = []
        for i in range(len(points)):
            p1 = points[i]
            p2 = points[(i + 1) % len(points)]

            # Находим пересечение текущей строки сканирования с ребром многоугольника
            if p1[1] < y <= p2[1] or p2[1] < y <= p1[1]:
                x_intersect = int(p1[0] + (y - p1[1]) / (p2[1] - p1[1]) * (p2[0] - p1[0]))
                intersections.append(x_intersect)

        # Сортируем пересечения по возрастанию x
        intersections.sort()

        # Заполняем многоугольник для данной строки сканирования, только если точка внутри многоугольника
        for i in range(0, len(intersections), 2):
            for x in range(intersections[i], intersections[i + 1] + 1):
                if is_point_inside_polygon(x, y):
                    set_pixel(x, y, [0, 0, 0])


# Функция отрисовки
def draw():
    glClear(GL_COLOR_BUFFER_BIT)
    glPointSize(1.0)

    # Отрисовка линий между точками
    if not filter_polygon:
        if len(points) >= 2:
            glColor3f(0.0, 0.0, 1.0)
            for i in range(len(points) - 1):
                draw_line_based(points[i], points[i + 1], [0, 0, 0])
    else:
        if len(points) >= 2:
            glColor3f(0.0, 0.0, 1.0)
            for i in range(len(points) - 1):
                draw_line_based(points[i], points[i + 1], [255, 255, 255])

    # Заполнение многоугольника по ребрам при нажатии клавиши "p"
    if fill_polygon:
        fill_polygon_scanline()

    # Отрисовка линий алгоритмом Брезенхема
    if filter_polygon:
        if len(points) >= 2:
            glColor3f(0.0, 0.0, 1.0)
            for i in range(len(points) - 1):
                draw_line_bresenham(points[i], points[i + 1], [0, 0, 0])

    glDrawPixels(WIDTH, HEIGHT, GL_RGB, GL_UNSIGNED_BYTE, pixels)

    glFlush()


def key_pressed(key, x, y):
    global fill_polygon
    global filter_polygon
    if key == b'w':
        fill_polygon = not fill_polygon
        glutPostRedisplay()
    if key == b's':
        filter_polygon = not filter_polygon
        draw()
        glutPostRedisplay()
    global points, pixels
    if key == b'z':
        points.clear()
        pixels = [[[255, 255, 255] for _ in range(WIDTH)] for _ in range(HEIGHT)]
        fill_polygon = not fill_polygon
        glutPostRedisplay()

# Функция обработки кликов мыши
def mouse_click(button, state, x, y):
    if button == GLUT_LEFT_BUTTON and state == GLUT_DOWN:
        y = HEIGHT - y  
        points.append((x, y))
        glutPostRedisplay()

# инициализации OpenGL
def init():
    glClearColor(1.0, 1.0, 1.0, 1.0)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    gluOrtho2D(0, WIDTH, 0, HEIGHT)

# Основная функция
def main():
    glutInit(sys.argv)
    glutInitDisplayMode(GLUT_SINGLE | GLUT_RGB)
    glutInitWindowSize(WIDTH, HEIGHT)
    glutCreateWindow(b"LAB 4 (cry)")

    init()

    glutDisplayFunc(draw)
    glutMouseFunc(mouse_click)
    glutKeyboardFunc(key_pressed)

    glutMainLoop()

if __name__ == "__main__":
    main()
