import matplotlib.pyplot as plt
import numpy as np

# Настройка углов (от реверса -20° до взлетного +50°)
angle = np.linspace(-20, 50, 1000)
force = np.zeros_like(angle)

# 1. Базовое вязкое трение (постоянное сопротивление около 15 Ньютон)
base_friction = 15.0

for i, a in enumerate(angle):
    # Базовое усилие
    f = base_friction
    
    # Детент: Малый Газ (IDLE) около 0 градусов
    # Пилоту нужно приложить усилие, чтобы преодолеть ступеньку
    if -2 <= a <= 2:
        f += 25 * np.exp(-((a - 0)/0.8)**2)
        
    # Детент: Набор высоты (CLIMB) около 30 градусов
    elif 28 <= a <= 32:
        f += 20 * np.exp(-((a - 30)/0.8)**2)
        
    # Детент: Взлетный / Чрезвычайный режим (TOGA / MAX) около 45 градусов
    elif 43 <= a <= 47:
        f += 30 * np.exp(-((a - 45)/0.8)**2)
        
    # Зона Реверса (от -20 до 0 градусов)
    # Симулируем резкий подъем усилия при попытке уйти глубоко в реверс без защелки
    if a < 0:
        f += 0.5 * (a**2) # усилие растет параболически
        
    force[i] = f

# Построение графика
plt.figure(figsize=(10, 5))
plt.plot(angle, force, label='Усилие на рычаге (Н)', color='blue', linewidth=2.5)

# Добавление ключевых точек (детентов)
plt.axvline(x=0, color='red', linestyle='--', alpha=0.7)
plt.text(0, 43, ' Малый Газ\n (IDLE)', color='red', fontsize=10)

plt.axvline(x=30, color='green', linestyle='--', alpha=0.7)
plt.text(30, 38, ' Набор высоты\n (CLIMB)', color='green', fontsize=10)

plt.axvline(x=45, color='purple', linestyle='--', alpha=0.7)
plt.text(45, 48, ' Взлет / Макс\n (TOGA)', color='purple', fontsize=10)

# Оформление
plt.title('График изменения усилия на РУД гражданского лайнера', fontsize=12, fontweight='bold')
plt.xlabel('Положение рычага (Угол наклона в градусах)', fontsize=10)
plt.ylabel('Требуемое усилие пилота (в Ньютонах, Н)', fontsize=10)
plt.grid(True, linestyle=':', alpha=0.6)
plt.ylim(0, 60)
plt.xlim(-25, 55)

# Вывод
plt.tight_layout()
plt.show()

