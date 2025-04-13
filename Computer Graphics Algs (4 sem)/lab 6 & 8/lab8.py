import math
import time
import numpy as np
import pygame
import glfw
from PIL import Image
from OpenGL.GL import *
from OpenGL.GLUT import *

vertex_shader_source = """
#version 120

attribute vec3 aVert;
                varying vec3 n;
                varying vec3 v;
                varying vec2 uv;
                varying vec4 vertexColor;
                void main() {   
                    uv = gl_MultiTexCoord0.xy;
                    v = vec3(gl_ModelViewMatrix * gl_Vertex);
                    n = normalize(gl_NormalMatrix * gl_Normal);
                    gl_TexCoord[0] = gl_TextureMatrix[0]  * gl_MultiTexCoord0;
                    gl_Position = gl_ModelViewProjectionMatrix * vec4(gl_Vertex.x, gl_Vertex.y, gl_Vertex.z, 1);
                    vec4 vertexColor = vec4(0.5f, 0.0f, 0.0f, 1.0f);
                }
"""

fragment_shader_source = """
#version 120

varying vec3 n;
            varying vec3 v;
            varying vec4 vertexColor;

            uniform sampler2D tex;

            void main () {  
                vec3 L = normalize(gl_LightSource[0].position.xyz - v);
                vec3 E = normalize(-v); // Вектор, направленный к наблюдателю (камере)
                vec3 R = normalize(-reflect(L,n)); // Отраженный вектор света L относительно нормали n.

                vec4 Iamb = gl_FrontLightProduct[0].ambient;
                vec4 Idiff = gl_FrontLightProduct[0].diffuse * max(dot(n,L), 1.0); // 
                Idiff = clamp(Idiff, 2.0, 0.6);     
                vec4 Ispec = gl_LightSource[0].specular 
                                * pow(max(dot(R,E),0.0),0.7);
                Ispec = clamp(Ispec, 0.0, 1.0); 

                vec4 texColor = texture2D(tex, gl_TexCoord[0].st);
                gl_FragColor = (Idiff + Iamb + Ispec) * texColor;
            }
"""


scale = 0.325

animation_mode = False
texture_sides = None
texture_enabled = True

light0_position = (-1.0, 1.0, 1.0, 0.0)
light1_position = (1.0, -1.0, 1.0, 0.0)

fi=0
tetha=0

flying_speed = 0
V = 0.0009*10
acl = 0.00006*5
dist = 1

light_mode = False
texture_mode = 1
filling_mode = True

transparency = 1.0  # Initial transparency value


def main():
    if not glfw.init():
        return
    window = glfw.create_window(600, 600, "Лаба 8", None, None)
    if not window:
        glfw.terminate()
        return
    glfw.make_context_current(window)

    glfw.set_key_callback(window, key_callback)
    glfw.set_mouse_button_callback(window, mouse_callback)
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
    #generate_texture()
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    #light()
    #--------------
    setup_lighting()

    texture_id = load_texture("texture.bmp")

    # Compiling shaders
    vertex_shader = glCreateShader(GL_VERTEX_SHADER)
    glShaderSource(vertex_shader, vertex_shader_source)
    glCompileShader(vertex_shader)
    if not glGetShaderiv(vertex_shader, GL_COMPILE_STATUS):
        print(glGetShaderInfoLog(vertex_shader))
        return

    fragment_shader = glCreateShader(GL_FRAGMENT_SHADER)
    glShaderSource(fragment_shader, fragment_shader_source)
    glCompileShader(fragment_shader)
    if not glGetShaderiv(fragment_shader, GL_COMPILE_STATUS):
        print(glGetShaderInfoLog(fragment_shader))
        return

    shader_program = glCreateProgram()
    glAttachShader(shader_program, vertex_shader)
    glAttachShader(shader_program, fragment_shader)
    glLinkProgram(shader_program)
    if not glGetProgramiv(shader_program, GL_LINK_STATUS):
        print(glGetProgramInfoLog(shader_program))
        return
    glDeleteShader(vertex_shader)
    glDeleteShader(fragment_shader)
    # --------
    while not glfw.window_should_close(window):
        display(window, texture_id, shader_program)
    glfw.destroy_window(window)
    glfw.terminate()

def renderHyperboloid(cx, cy, cz, a, b, p):
    glColor4f(0.2, 1.0, 1.0, transparency)  # Set transparency here
    PI = math.pi
    TWOPI = 2 * PI
    for i in range(p // 2 + 1):
        theta1 = i * TWOPI / p - PI / 2
        theta2 = (i + 1) * TWOPI / p - PI / 2

        glBegin(GL_TRIANGLE_STRIP)
        for j in range(p + 1):
            theta3 = j * TWOPI / p

            ex = a * math.cosh(theta2) * math.cos(theta3)
            ey = b * math.sinh(theta2)
            ez = a * math.cosh(theta2) * math.sin(theta3)
            px = cx + ex
            py = cy + ey
            pz = cz + ez

            glNormal3f(ex, ey, ez)
            glTexCoord2f(-(j / p), 2 * (i + 1) / p)
            glVertex3f(px, py, pz * 1.2)

            ex = a * math.cosh(theta1) * math.cos(theta3)
            ey = b * math.sinh(theta1)
            ez = a * math.cosh(theta1) * math.sin(theta3)
            px = cx + ex
            py = cy + ey
            pz = cz + ez

            glNormal3f(ex, ey, ez)
            glTexCoord2f(-(j / p), 2 * i / p)
            glVertex3f(px, py, pz * 1.2)
        glEnd()

def display(window, texture_id, shader_program):
    global rotating_right, fi, tetha
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glDepthFunc(GL_LESS)
    glClearColor(0.0, 0.0, 0.0, 0.0)
    glLoadIdentity()
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    if animation_mode:
        move_object()

    glTranslatef(0, flying_speed, 0)
    if rotating_right:
        fi += 2  # Увеличиваем угол только если вращение происходит вправо
    glRotatef(fi, 1, 0, 0)  # Поворачиваем вокруг оси X
    glRotatef(tetha, 0, 1, 0)  # Поворачиваем вокруг оси Y

    glUseProgram(shader_program)
    if texture_enabled:
        glEnable(GL_TEXTURE_2D)
        glBindTexture(GL_TEXTURE_2D, texture_id)
    else:
        glDisable(GL_TEXTURE_2D)

    renderHyperboloid(0, 0, dist, 0.8 * dist * 0.7, 0.6 * dist * 0.7, 40)

    glDisable(GL_TEXTURE_2D)

    glLightfv(GL_LIGHT0, GL_POSITION, light0_position)
    glLightfv(GL_LIGHT1, GL_POSITION, light1_position)

    glUseProgram(0)

    glfw.swap_buffers(window)
    glfw.poll_events()


rotating_right = False 

def key_callback(window, key, scancode, action, mods):
    global x_angle, y_angle, scale, animation_mode, fi, tetha, dist, transparency, rotating_right
    if action == glfw.PRESS and key == glfw.KEY_ENTER:
        mode = glGetIntegerv(GL_POLYGON_MODE)
        if mode[1] == GL_LINE:
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
        else:
            glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
    if action == glfw.PRESS or action == glfw.REPEAT:
        if key == glfw.KEY_W:
            fi -= 2
        if key == glfw.KEY_S:
            fi += 2
        if key == glfw.KEY_A:
            tetha -= 2
        if key == glfw.KEY_D:
            tetha += 2
        if key == glfw.KEY_LEFT:
            rotating_right = False  # Прекращаем вращение при нажатии клавиши "left"
        elif key == glfw.KEY_RIGHT:
            rotating_right = True  # Начинаем вращение при нажатии клавиши "right"
        if key == glfw.KEY_UP:
            dist += 0.1
            scale += 0.05
        if key == glfw.KEY_DOWN:
            dist -= 0.1
            scale -= 0.05

        global light_mode
        if key == glfw.KEY_L:
            if glIsEnabled(GL_LIGHTING):
                glDisable(GL_LIGHTING)
            else:
                glEnable(GL_LIGHTING)
            return
        if key == glfw.KEY_SPACE:
            animation_mode = not animation_mode
            return
        if key == glfw.KEY_O:
            transparency += 0.1  # Increase transparency
            if transparency > 1.0:
                transparency = 1.0
            print("Transparency increased to", transparency)
        if key == glfw.KEY_P:
            transparency -= 0.1  # Decrease transparency
            if transparency < 0.0:
                transparency = 0.0
            print("Transparency decreased to", transparency)


def mouse_callback(window, button, action, mods):
    global filling_mode, texture_mode
    if action == glfw.PRESS:
        if button == glfw.MOUSE_BUTTON_LEFT:
            filling_mode = not filling_mode
            if filling_mode:
                glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
            else:
                glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
        elif button == glfw.MOUSE_BUTTON_RIGHT:
            texture_mode = not texture_mode
            if texture_mode:
                glBindTexture(GL_TEXTURE_2D, texture_sides)
            else:
                glBindTexture(GL_TEXTURE_2D, 0)

def move_object():
    global V, flying_speed, acl
    flying_speed -= V
    V += acl
    if flying_speed < -1 or flying_speed > 1:
        V = -V

def generate_texture():
    textureSurface = pygame.image.load('image_3.jpeg')
    textureData = pygame.image.tostring(textureSurface, "RGBA", 1)
    width = textureSurface.get_width()
    height = textureSurface.get_height()

    glEnable(GL_TEXTURE_2D)
    texid = glGenTextures(1)

    glBindTexture(GL_TEXTURE_2D, texid)

    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height,
                 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData)

def setup_lighting():
    glEnable(GL_LIGHTING)
    glEnable(GL_LIGHT0)
    glEnable(GL_LIGHT1)

    glLightfv(GL_LIGHT0, GL_DIFFUSE, (1.0, 1.0, 1.0, 1.0))

    glLightfv(GL_LIGHT1, GL_DIFFUSE, (0.5, 0.5, 0.5, 1.0))

def create_shader(shader_type, source):
    shader = glCreateShader(shader_type)
    glShaderSource(shader, source)
    glCompileShader(shader)

    result = glGetShaderiv(shader, GL_COMPILE_STATUS)
    if not result:
        error_log = glGetShaderInfoLog(shader)
        print(f"Error compiling shader type {shader_type}: {error_log}")

    return shader

def load_texture(filename):
    image = Image.open(filename).convert('RGB')
    image_data = image.tobytes("raw", "RGBX", 0, -1)

    texture = glGenTextures(1)
    glBindTexture(GL_TEXTURE_2D, texture)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image.width, image.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, image_data)

    return texture

def light():
    global dist
    glEnable(GL_LIGHTING)
    # glLightModelfv(GL_LIGHT_MODEL_AMBIENT, [[0.2, 0.2, 0.2, 1]])

    # парметры материала
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, [1, 1, 1, 1])
    glMaterialfv(GL_FRONT_AND_BACK, GL_SHININESS, 50.0)
    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, [0, 0, 0, 1])

    glEnable(GL_LIGHT0)
    glLightfv(GL_LIGHT0, GL_DIFFUSE, [0.7, 0.7, 0.7])
    glLightfv(GL_LIGHT0, GL_POSITION, [0, 0, -1, 1])
    glLightf(GL_LIGHT0, GL_CONSTANT_ATTENUATION, 1.0)
    glLightf(GL_LIGHT0, GL_LINEAR_ATTENUATION, 0.2)
    glLightf(GL_LIGHT0, GL_QUADRATIC_ATTENUATION, 0.4)

start = time.monotonic()
main()
stop = time.monotonic()
print('slow:', stop-start)
