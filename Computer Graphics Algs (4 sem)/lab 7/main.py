import glfw
from OpenGL.GL import *
from OpenGL.GLUT import *
from OpenGL.GL.shaders import compileProgram, compileShader
from PIL import Image
from math import cos, sin, pi
import time
import math
import matplotlib.pyplot as plt
import numpy as np
import tkinter as tk
from tkinter import ttk
import pandas as pd

initial_velocity = 0.00000000000000003
acceleration_due_to_gravity = -0.0003
elasticity_coefficient = 1.0

position_y = 0.0
velocity_y = initial_velocity
light0_position = (-1.0, 1.0, 1.0, 0.0)
rotation_x = 0.0
rotation_y = 0.0
rotation_z = 0.0
texture_enabled = True
cylinder_list = None
use_display_list = False
use_vbo = False
use_ebo = False
use_shaders = False
vertex_vbo = None
index_vbo = None
num_indices = 0
shader_program = None
show_performance_graph = False  # Новая глобальная переменная для отображения графика

cx, cy, cz = 0.0, 0.0, 0.0  # Центр гиперболоида
a, b = 0.2, 0.3             # Полуоси гиперболоида
p = 20                      # Количество сегментов

vertex_shader_src = """
#version 120
attribute vec3 position;
attribute vec3 normal;
attribute vec2 texcoord;
varying vec3 fragNormal;
varying vec2 fragTexcoord;
varying vec3 lightDir;
void main()
{
    fragNormal = normal;
    fragTexcoord = texcoord;
    vec4 lightPosition = vec4(1.0, 1.0, 1.0, 0.0);
    lightDir = normalize(vec3(gl_ModelViewMatrix * lightPosition));
    gl_Position = gl_ModelViewProjectionMatrix * vec4(position, 1.0);
}
"""

fragment_shader_src = """
#version 120
varying vec3 fragNormal;
varying vec2 fragTexcoord;
varying vec3 lightDir;
uniform sampler2D tex;
void main()
{
    vec3 normal = normalize(fragNormal);
    float diff = max(dot(normal, lightDir), 0.0);
    vec4 texColor = texture2D(tex, fragTexcoord);
    vec4 ambient = 0.3 * texColor;
    vec4 diffuse = diff * texColor;
    gl_FragColor = ambient + diffuse;
}
"""

def create_cylinder_list():
    global cylinder_list
    cylinder_list = glGenLists(1)
    glNewList(cylinder_list, GL_COMPILE)
    draw_hyperboloid(cx, cy, cz, a, b, p)
    glEndList()

def draw_hyperboloid(cx, cy, cz, a, b, p):
    vertices = []
    indices = []

    PI = math.pi
    TWOPI = 2 * PI
    
    for i in range(p // 2 + 1):
        theta1 = i * TWOPI / p - PI / 2
        theta2 = (i + 1) * TWOPI / p - PI / 2

        for j in range(p + 1):
            theta3 = j * TWOPI / p

            # First point on the strip
            ex = a * math.cosh(theta2) * math.cos(theta3)
            ey = b * math.sinh(theta2)
            ez = a * math.cosh(theta2) * math.sin(theta3)
            px = cx + ex
            py = cy + ey
            pz = cz + ez
            vertices.extend([px, py, pz, ex, ey, ez, -(j / p), 2 * (i + 1) / p])

            # Second point on the strip
            ex = a * math.cosh(theta1) * math.cos(theta3)
            ey = b * math.sinh(theta1)
            ez = a * math.cosh(theta1) * math.sin(theta3)
            px = cx + ex
            py = cy + ey
            pz = cz + ez
            vertices.extend([px, py, pz, ex, ey, ez, -(j / p), 2 * i / p])

    # Generate indices
    for i in range(p // 2):
        for j in range(p):
            idx = i * (p + 1) * 2 + j * 2
            indices.extend([idx, idx + 1, idx + 2])
            indices.extend([idx + 2, idx + 1, idx + 3])

    vertices = np.array(vertices, dtype=np.float32)
    indices = np.array(indices, dtype=np.uint32)

    return vertices, indices


def draw_hyperboloid_optimized(cx, cy, cz, a, b, p):
    vertices = []
    indices = []

    PI = math.pi
    TWOPI = 2 * PI
    
    for i in range(p // 2 + 1):
        theta1 = i * TWOPI / p - PI / 2
        theta2 = (i + 1) * TWOPI / p - PI / 2

        for j in range(p + 1):
            theta3 = j * TWOPI / p

            # First point on the strip
            ex = a * math.cosh(theta2) * math.cos(theta3)
            ey = b * math.sinh(theta2)
            ez = a * math.cosh(theta2) * math.sin(theta3)
            px = cx + ex
            py = cy + ey
            pz = cz + ez
            vertices.extend([px, py, pz])

            # Second point on the strip
            ex = a * math.cosh(theta1) * math.cos(theta3)
            ey = b * math.sinh(theta1)
            ez = a * math.cosh(theta1) * math.sin(theta3)
            px = cx + ex
            py = cy + ey
            pz = cz + ez
            vertices.extend([px, py, pz])

    # Generate indices
    for i in range(p // 2):
        for j in range(p):
            idx = i * (p + 1) * 2 + j * 2
            indices.extend([idx, idx + 1, idx + 2])
            indices.extend([idx + 2, idx + 1, idx + 3])

    vertices = np.array(vertices, dtype=np.float32)
    indices = np.array(indices, dtype=np.uint32)

    return vertices, indices


def load_texture(filename):
    image = Image.open(filename).convert('RGB')
    image_data = image.tobytes("raw", "RGBX", 0, -1)

    texture = glGenTextures(1)
    glBindTexture(GL_TEXTURE_2D, texture)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image.width, image.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, image_data)

    return texture

def update_position_and_velocity():
    global position_y, velocity_y

    position_y += velocity_y
    velocity_y += acceleration_due_to_gravity

    if position_y < -0.4:
        velocity_y *= -elasticity_coefficient

def display(window, texture_id):
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()

    glPushMatrix()
    glTranslatef(0.0, position_y, 0.0)

    glRotatef(rotation_x, 1.0, 0.0, 0.0)
    glRotatef(rotation_y, 0.0, 1.0, 0.0)
    glRotatef(rotation_z, 0.0, 0.0, 1.0)

    glEnable(GL_LIGHTING)
    glEnable(GL_LIGHT0)

    setup_material()

    if texture_enabled:
        glEnable(GL_TEXTURE_2D)
        glBindTexture(GL_TEXTURE_2D, texture_id)
    else:
        glDisable(GL_TEXTURE_2D)

    if use_display_list:
        glCallList(cylinder_list)
    elif use_vbo:
        glBindBuffer(GL_ARRAY_BUFFER, vertex_vbo)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_vbo)

        glEnableClientState(GL_VERTEX_ARRAY)
        glEnableClientState(GL_NORMAL_ARRAY)
        glEnableClientState(GL_TEXTURE_COORD_ARRAY)

        glVertexPointer(3, GL_FLOAT, 8 * sizeof(GLfloat), ctypes.c_void_p(0))
        glNormalPointer(GL_FLOAT, 8 * sizeof(GLfloat), ctypes.c_void_p(3 * sizeof(GLfloat)))
        glTexCoordPointer(2, GL_FLOAT, 8 * sizeof(GLfloat), ctypes.c_void_p(6 * sizeof(GLfloat)))

        glDrawElements(GL_TRIANGLES, num_indices, GL_UNSIGNED_INT, None)

        glDisableClientState(GL_VERTEX_ARRAY)
        glDisableClientState(GL_NORMAL_ARRAY)
        glDisableClientState(GL_TEXTURE_COORD_ARRAY)

        glBindBuffer(GL_ARRAY_BUFFER, 0)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
    elif use_ebo:
        glBindBuffer(GL_ARRAY_BUFFER, vertex_vbo)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_vbo)

        glEnableClientState(GL_VERTEX_ARRAY)
        glEnableClientState(GL_NORMAL_ARRAY)
        glEnableClientState(GL_TEXTURE_COORD_ARRAY)

        glVertexPointer(3, GL_FLOAT, 8 * sizeof(GLfloat), ctypes.c_void_p(0))
        glNormalPointer(GL_FLOAT, 8 * sizeof(GLfloat), ctypes.c_void_p(3 * sizeof(GLfloat)))
        glTexCoordPointer(2, GL_FLOAT, 8 * sizeof(GLfloat), ctypes.c_void_p(6 * sizeof(GLfloat)))

        glDrawElements(GL_TRIANGLES, num_indices, GL_UNSIGNED_INT, None)

        glDisableClientState(GL_VERTEX_ARRAY)
        glDisableClientState(GL_NORMAL_ARRAY)
        glDisableClientState(GL_TEXTURE_COORD_ARRAY)

        glBindBuffer(GL_ARRAY_BUFFER, 0)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)
    elif use_shaders:
        glUseProgram(shader_program)
        
        position_location = glGetAttribLocation(shader_program, 'position')
        normal_location = glGetAttribLocation(shader_program, 'normal')
        texcoord_location = glGetAttribLocation(shader_program, 'texcoord')

        glBindBuffer(GL_ARRAY_BUFFER, vertex_vbo)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_vbo)

        glEnableVertexAttribArray(position_location)
        glEnableVertexAttribArray(normal_location)
        glEnableVertexAttribArray(texcoord_location)

        glVertexAttribPointer(position_location, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), ctypes.c_void_p(0))
        glVertexAttribPointer(normal_location, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), ctypes.c_void_p(3 * sizeof(GLfloat)))
        glVertexAttribPointer(texcoord_location, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), ctypes.c_void_p(6 * sizeof(GLfloat)))

        glDrawElements(GL_TRIANGLES, num_indices, GL_UNSIGNED_INT, None)

        glDisableVertexAttribArray(position_location)
        glDisableVertexAttribArray(normal_location)
        glDisableVertexAttribArray(texcoord_location)

        glBindBuffer(GL_ARRAY_BUFFER, 0)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

        glUseProgram(0)
    else:
        vertices, indices = draw_hyperboloid(cx, cy, cz, a, b, p)
        glEnableClientState(GL_VERTEX_ARRAY)
        glEnableClientState(GL_NORMAL_ARRAY)
        glEnableClientState(GL_TEXTURE_COORD_ARRAY)

        glVertexPointer(3, GL_FLOAT, 8 * sizeof(GLfloat), vertices)
        glNormalPointer(GL_FLOAT, 8 * sizeof(GLfloat), vertices[3:])
        glTexCoordPointer(2, GL_FLOAT, 8 * sizeof(GLfloat), vertices[6:])

        glDrawElements(GL_TRIANGLES, len(indices), GL_UNSIGNED_INT, indices)

        glDisableClientState(GL_VERTEX_ARRAY)
        glDisableClientState(GL_NORMAL_ARRAY)
        glDisableClientState(GL_TEXTURE_COORD_ARRAY)

    glDisable(GL_TEXTURE_2D)
    glPopMatrix()

    glLightfv(GL_LIGHT0, GL_POSITION, light0_position)

    glfw.swap_buffers(window)

def setup_material():
    ambient = (0.3, 0.3, 0.3, 1.0)
    diffuse = (0.8, 0.8, 0.8, 1.0)
    specular = (1.0, 1.0, 1.0, 1.0)
    shininess = 100.0

    glMaterialfv(GL_FRONT, GL_AMBIENT, ambient)
    glMaterialfv(GL_FRONT, GL_DIFFUSE, diffuse)
    glMaterialfv(GL_FRONT, GL_SPECULAR, specular)
    glMaterialfv(GL_FRONT, GL_SHININESS, shininess)

def key_callback(window, key, scancode, action, mods):
    global rotation_x, rotation_y, rotation_z, texture_enabled, use_display_list, use_vbo, use_ebo, use_shaders, show_performance_graph
    if action == glfw.PRESS:
        if key == glfw.KEY_UP:
            rotation_x += 5.0
        elif key == glfw.KEY_DOWN:
            rotation_x -= 5.0
        elif key == glfw.KEY_LEFT:
            rotation_y += 5.0
        elif key == glfw.KEY_RIGHT:
            rotation_y -= 5.0
        elif key == glfw.KEY_PAGE_UP:
            rotation_z += 5.0
        elif key == glfw.KEY_PAGE_DOWN:
            rotation_z -= 5.0
        elif key == glfw.KEY_T:
            texture_enabled = not texture_enabled
        elif key == glfw.KEY_D:
            use_display_list = not use_display_list
        elif key == glfw.KEY_V:
            use_vbo = not use_vbo
        elif key == glfw.KEY_E:
            use_ebo = not use_ebo
        elif key == glfw.KEY_S:
            use_shaders = not use_shaders
        elif key == glfw.KEY_P:  # Обработка нажатия клавиши 'P' для отображения графика
            show_performance_graph = True

def compile_shaders():
    global shader_program
    vertex_shader = compileShader(vertex_shader_src, GL_VERTEX_SHADER)
    fragment_shader = compileShader(fragment_shader_src, GL_FRAGMENT_SHADER)
    shader_program = compileProgram(vertex_shader, fragment_shader)

def measure_performance(window, texture_id, num_frames=100):
    start_time = time.time()
    for _ in range(num_frames):
        glfw.poll_events()
        update_position_and_velocity()
        display(window, texture_id)
    end_time = time.time()
    return (end_time - start_time) / num_frames

def plot_performance_graph(data):
    labels = list(data.keys())
    times = list(data.values())

    plt.figure(figsize=(8, 4))  # изменяем размер окна графика
    plt.bar(labels, times, color='skyblue')
    plt.xlabel('Optimization Method')
    plt.ylabel('Average Frame Time (seconds)')
    plt.title('Performance Comparison of Different Optimization Methods')
    plt.show()


def main():
    if not glfw.init():
        return

    window = glfw.create_window(640, 640, "Lab7", None, None)
    if not window:
        glfw.terminate()
        return

    glfw.make_context_current(window)
    glfw.set_key_callback(window, key_callback)

    glEnable(GL_DEPTH_TEST)

    texture_id = load_texture("texture.jpeg")
    create_cylinder_list()
    compile_shaders()

    global vertex_vbo, index_vbo, num_indices
    vertices, indices = draw_hyperboloid(cx, cy, cz, a, b, p)
    num_indices = len(indices)
    vertex_vbo = glGenBuffers(1)
    index_vbo = glGenBuffers(1)
    
    glBindBuffer(GL_ARRAY_BUFFER, vertex_vbo)
    glBufferData(GL_ARRAY_BUFFER, vertices.nbytes, vertices, GL_STATIC_DRAW)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_vbo)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.nbytes, indices, GL_STATIC_DRAW)
    
    glBindBuffer(GL_ARRAY_BUFFER, 0)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

    # Вызовем функцию display один раз для начальной отрисовки
    display(window, texture_id)
    glfw.swap_buffers(window)

    performance_data = {}

    global use_display_list, use_vbo, use_ebo, use_shaders
    # Проведение измерений производительности для оптимизации
    use_display_list = False
    use_vbo = False
    use_ebo = False
    use_shaders = False
    performance_without_dl_vbo_ebo_shaders_optimized = measure_performance(window, texture_id)
    print(f"Average frame time optimization: {performance_without_dl_vbo_ebo_shaders_optimized:.6f} seconds")
    performance_data['No opt.'] = performance_without_dl_vbo_ebo_shaders_optimized

    # Включение оптимизации передачи данных
    vertices_optimized, indices_optimized = draw_hyperboloid_optimized(cx, cy, cz, a, b, p)
    num_indices_optimized = len(indices_optimized)
    vertex_vbo_optimized = glGenBuffers(1)
    index_vbo_optimized = glGenBuffers(1)

    glBindBuffer(GL_ARRAY_BUFFER, vertex_vbo_optimized)
    glBufferData(GL_ARRAY_BUFFER, vertices_optimized.nbytes, vertices_optimized, GL_STATIC_DRAW)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index_vbo_optimized)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices_optimized.nbytes, indices_optimized, GL_STATIC_DRAW)

    glBindBuffer(GL_ARRAY_BUFFER, 0)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

    # Проведение измерений производительности с оптимизацией передачи данных
    performance_with_optimization = measure_performance(window, texture_id)
    print(f"Average frame time with optimized data transfer: {performance_with_optimization:.6f} seconds")
    performance_data['Data Transfer'] = performance_with_optimization

    use_display_list = True
    performance_with_dl = measure_performance(window, texture_id)
    print(f"Average frame time with display lists: {performance_with_dl:.6f} seconds")
    performance_data['Display Lists'] = performance_with_dl

    use_display_list = False
    use_vbo = True
    performance_with_vbo = measure_performance(window, texture_id)
    print(f"Average frame time with arrsys of vertexes: {performance_with_vbo:.6f} seconds")
    performance_data['Vertexes'] = performance_with_vbo

    use_vbo = False
    use_ebo = True
    performance_with_ebo = measure_performance(window, texture_id)
    print(f"Average frame time with elements: {performance_with_ebo:.6f} seconds")
    performance_data['Elements'] = performance_with_ebo

    use_ebo = False
    use_shaders = True
    performance_with_shaders = measure_performance(window, texture_id)
    print(f"Average frame time with textures: {performance_with_shaders:.6f} seconds")
    performance_data['Textures'] = performance_with_shaders

    global show_performance_graph

    while not glfw.window_should_close(window):
        glfw.poll_events()
        update_position_and_velocity()
        display(window, texture_id)
        if show_performance_graph:
            plot_performance_graph(performance_data)
            show_performance_graph = False

    glfw.destroy_window(window)
    glfw.terminate()

if __name__ == "__main__":
    main()
