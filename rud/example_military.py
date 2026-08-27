import matplotlib.pyplot as plt
import numpy as np

# Настройка углов РУД Су-35: от положения СТОП (-10°) до ПОЛНОГО ФОРСАЖА (+60°)
angle = np.linspace(-10, 60, 1000)
force = np.zeros_like(angle)

# Базовое трение на истребителе выше из-за перегрузок (около 25 Ньютон = 2.5 кг)
base_friction = 25.0

for i, a in enumerate(angle):
    f = base_friction
    
    # 1. Положение "Малый Газ" (0 градусов)
    # Переход из СТОП в Малый Газ при запуске требует преодоления фиксатора
    if -2 <= a <= 2:
        f += 20 * np.exp(-((a - 0)/0.7)**2)
        
    # 2. Упор "Максимал" / Вход в Форсаж (около 40 градусов)
    # Пилот должен жестко толкнуть рычаг вперед (усилие около 60 Н = 6 кг)
    elif 38 <= a <= 42:
        f += 35 * np.exp(-((a - 40)/0.8)**2)
        
    # 3. Зона Форсажа (от 41 до 60 градусов)
    # Внутри форсажной зоны ход идет с базовым трением, плавно наращивая тягу камеры
    elif a > 41:
        f = base_friction + (a - 41) * 0.1 # легкое нарастание плотности хода
        
    # 4. Зона "СТОП" (от -10 до 0 градусов) - Блокировка выключения
    # Без поднятия РУД вверх усилие уходит в бесконечность (механический тупик)
    if a < 0:
        f += 50 * np.exp(-((a - 0)/2.0)**2) + (a**2) * 2

    force[i] = f

# Построение графика
plt.figure(figsize=(10, 5))
plt.plot(angle, force, label='Усилие на РУД Су-35 (Н)', color='darkred', linewidth=3)

# Добавление ключевых боевых режимов
plt.axvline(x=0, color='black', linestyle='--', alpha=0.5)
plt.text(0.5, 50, 'Малый Газ\n(МГ)', color='black', fontsize=10)

plt.axvline(x=40, color='blue', linestyle='--', alpha=0.7)
plt.text(35, 63, 'Упор Максимала\n(Вход в форсаж)', color='blue', fontsize=10, weight='bold')

# Выделение зоны форсажа
plt.axvspan(40, 60, color='orange', alpha=0.15, label='Зона Форсажа')
plt.text(46, 30, 'ФОРСАЖ\n(Мин -> Полный)', color='darkorange', fontsize=12, weight='bold')

# Оформление графика
plt.title('График тактильного усилия на РУД истребителя Су-35', fontsize=12, fontweight='bold')
plt.xlabel('Положение рычага двигателя (Угол в градусах)', fontsize=10)
plt.ylabel('Требуемое усилие пилота (в Ньютонах, Н)', fontsize=10)
plt.grid(True, linestyle=':', alpha=0.6)
plt.ylim(0, 80)
plt.xlim(-15, 65)
plt.legend(loc='upper left')

# Вывод
plt.tight_layout()
plt.show()
