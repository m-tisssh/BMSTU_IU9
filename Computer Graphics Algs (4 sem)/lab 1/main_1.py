import glfw
from OpenGL.GL import *
import math

delta = 0.1
angle = 0
posx = 0
posy = 0
size = 1  # Изначальный размер фигуры

def main():
    if not glfw.init():
        return
    window = glfw.create_window(500, 500, "lab1", None, None)
    if not window:
        glfw.terminate()
        return
    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)
    glfw.set_mouse_button_callback(window, mouse_button_callback)  # Добавляем обработчик событий мыши
    while not glfw.window_should_close(window):
        display(window)
    glfw.destroy_window(window)
    glfw.terminate()

def display(window):
    global angle
    glClear(GL_COLOR_BUFFER_BIT)
    glLoadIdentity()
    glClearColor(1.0, 1.0, 1.0, 1.0)
    glPushMatrix()
    glScalef(size, size, 1)  # Масштабирование фигуры
    glRotatef(angle, 0.7, 0.2, 0.3)
    glBegin(GL_POLYGON)
    num_vertices = 15  # Установим 15 вершин для 15-тиугольника
    for i in range(num_vertices):
        glColor3f(math.cos(i / num_vertices), math.sin(i / num_vertices), 1.0 - math.cos(i / num_vertices))
        glVertex2f(0.8 * math.cos(2 * math.pi * i / num_vertices), 0.8 * math.sin(2 * math.pi * i / num_vertices))
    glEnd()
    glPopMatrix()
    angle += delta
    glfw.swap_buffers(window)
    glfw.poll_events()

def key_callback(window, key, scancode, action, mods):
    global delta
    global angle
    if action == glfw.PRESS:
        if key == glfw.KEY_RIGHT:
            delta = -2
        if key == glfw.KEY_S:
            delta = 0
        if key == glfw.KEY_W:
            delta = 1
        if key == 263:  # glfw.KEY_LEFT
            delta = 2

def mouse_button_callback(window, button, action, mods):
    global size
    if button == glfw.MOUSE_BUTTON_RIGHT and action == glfw.PRESS:
        size -= 0.1  
    elif button == glfw.MOUSE_BUTTON_LEFT and action == glfw.PRESS:
        size += 0.1  

main()