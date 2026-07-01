"""ParkCraft 关卡生成器 — 链式阻挡法，保证可解并控制步数范围。

规则：
- 网格 6×6 固定
- 出口不可在拐角（行 1~4）
- 初阶 15~20 步 | 中阶 21~29 步 | 高阶 30~44 步
"""

import json, os, copy, random
from collections import deque

random.seed(42)

OUTPUT_DIR = 'assets/levels'
GRID_SIZE = 6
EXIT_COL = GRID_SIZE - 1  # 5
VALID_EXIT_ROWS = [1, 2, 3, 4]


class Car:
    def __init__(self, id, row, col, length, orient, is_target=False):
        self.id = id
        self.row = row
        self.col = col
        self.length = length
        self.orient = orient
        self.is_target = is_target

    def cells(self):
        return [(self.row + (i if self.orient == 'vertical' else 0),
                 self.col + (i if self.orient == 'horizontal' else 0))
                for i in range(self.length)]

    def copy(self):
        return Car(self.id, self.row, self.col, self.length, self.orient, self.is_target)


def find_car(cars, car_id):
    for c in cars:
        if c.id == car_id:
            return c
    return None


def check_collision(cars, car, steps, gs):
    for i in range(car.length):
        r = car.row + (i if car.orient == 'vertical' else 0) + (steps if car.orient == 'vertical' else 0)
        c = car.col + (i if car.orient == 'horizontal' else 0) + (steps if car.orient == 'horizontal' else 0)
        if r < 0 or r >= gs or c < 0 or c >= gs:
            if car.is_target and ((car.orient == 'horizontal' and c >= gs) or
                                  (car.orient == 'vertical' and r >= gs)):
                continue
            return True
        for other in cars:
            if other.id == car.id:
                continue
            if (r, c) in other.cells():
                return True
    return False


def get_state_key(cars):
    return '|'.join(sorted(f'{c.id}:{c.row}:{c.col}' for c in cars))


def is_solved(cars, gs):
    t = find_car(cars, 'T')
    if t.orient == 'horizontal':
        return t.col + t.length > gs
    return t.row + t.length > gs


def bfs_solve(cars, gs, max_states=50000):
    start_key = get_state_key(cars)
    q = deque()
    q.append((copy.deepcopy(cars), 0))
    visited = {start_key}
    while q and len(visited) < max_states:
        state, depth = q.popleft()
        if is_solved(state, gs):
            return depth
        for car in state:
            for step in [-1, 1]:
                if not check_collision(state, car, step, gs):
                    new_cars = copy.deepcopy(state)
                    c = find_car(new_cars, car.id)
                    if c.orient == 'horizontal':
                        c.col += step
                    else:
                        c.row += step
                    key = get_state_key(new_cars)
                    if key not in visited:
                        visited.add(key)
                        q.append((new_cars, depth + 1))
    return -1


def generate_level(level_id, difficulty, min_steps, max_steps):
    """链式阻挡法生成关卡。

    策略：在目标车前方逐个放置垂直阻挡车，每个垂直车用一个水平车挡住，
    形成"拆链"型关卡。这样每层至少贡献 2 步。
    """
    for _ in range(500):
        target_row = random.choice(VALID_EXIT_ROWS)
        cars = []
        occupied = set()

        # 目标车初始在起点
        t = Car('T', target_row, 0, 2, 'horizontal', True)
        cars.append(t)
        for cell in t.cells():
            occupied.add(cell)

        # 目标步数需要的"层数"
        layers_needed = max(3, (min_steps + max_steps) // 5)
        layers_needed = min(layers_needed, 8)

        letters = [chr(ord('A') + i) for i in range(26)]
        idx = 0

        # 每层：一个垂直车（阻挡 T）+ 一个水平车（阻挡垂直车）
        for layer in range(layers_needed):
            if idx >= 24:
                break

            # 垂直车放在 T 的行上，blocking T's path
            v_col = 1 + layer  # 从 col=1 开始逐个往后
            if v_col >= EXIT_COL:
                break

            # 检查这个垂直格子的位置
            for v_row_candidate in range(GRID_SIZE - 1):
                v_row = v_row_candidate
                v_car = Car(letters[idx], v_row, v_col, 2, 'vertical')
                valid = True
                for cell in v_car.cells():
                    if cell in occupied:
                        valid = False
                        break
                    cr, cc = cell
                    if cr < 0 or cr >= GRID_SIZE or cc < 0 or cc >= GRID_SIZE:
                        valid = False
                        break
                if valid:
                    cars.append(v_car)
                    for cell in v_car.cells():
                        occupied.add(cell)
                    idx += 1

                    # 添加一个水平车从下方挡住垂直车
                    h_row = v_row + 2
                    h_car = Car(letters[idx], h_row, v_col, 2, 'horizontal')
                    h_valid = True
                    for cell in h_car.cells():
                        if cell in occupied:
                            h_valid = False
                            break
                        cr, cc = cell
                        if cr < 0 or cr >= GRID_SIZE or cc < 0 or cc >= GRID_SIZE:
                            h_valid = False
                            break
                    if h_valid:
                        cars.append(h_car)
                        for cell in h_car.cells():
                            occupied.add(cell)
                        idx += 1
                    break

        # 再额外添加 1~2 辆随机车增加复杂度
        extra = random.randint(0, 2)
        for _ in range(extra):
            for _ in range(50):
                r = random.randint(0, GRID_SIZE - 1)
                c = random.randint(0, GRID_SIZE - 1)
                length = random.choice([2, 3])
                orient = random.choice(['horizontal', 'vertical'])
                temp = Car(letters[idx], r, c, length, orient)
                ok = True
                for cell in temp.cells():
                    cr, cc = cell
                    if cr < 0 or cr >= GRID_SIZE or cc < 0 or cc >= GRID_SIZE:
                        ok = False
                        break
                    if cell in occupied:
                        ok = False
                        break
                if ok:
                    cars.append(temp)
                    for cell in temp.cells():
                        occupied.add(cell)
                    idx += 1
                    break

        if len(cars) < 3:
            continue

        # BFS 验证
        steps = bfs_solve(cars, GRID_SIZE)
        if min_steps <= steps <= max_steps:
            blocking = [c for c in cars if not c.is_target]
            level = {
                'levelId': level_id, 'difficulty': difficulty,
                'gridSize': GRID_SIZE,
                'exit': {'row': target_row, 'col': EXIT_COL, 'orientation': 'horizontal'},
                'targetCar': {'id': 'T', 'row': t.row, 'col': t.col,
                              'length': t.length, 'orientation': t.orient},
                'blockingCars': [
                    {'id': c.id, 'row': c.row, 'col': c.col,
                     'length': c.length, 'orientation': c.orient}
                    for c in blocking],
            }
            return level, steps

    return None, 0


def main():
    configs = [
        ('level_001', 'easy',   15, 20),
        ('level_002', 'easy',   15, 20),
        ('level_003', 'easy',   15, 20),
        ('level_004', 'easy',   15, 20),
        ('level_005', 'medium', 21, 29),
        ('level_006', 'medium', 21, 29),
        ('level_007', 'medium', 21, 29),
        ('level_008', 'medium', 21, 29),
        ('level_009', 'hard',   30, 44),
        ('level_010', 'hard',   30, 44),
        ('level_011', 'hard',   30, 44),
        ('level_012', 'hard',   30, 44),
    ]

    success = 0
    for level_id, diff, mn, mx in configs:
        level, steps = generate_level(level_id, diff, mn, mx)
        if level is None:
            print(f'  ❌ {level_id} ({diff}): 生成失败')
            continue
        subdir = diff
        filepath = os.path.join(OUTPUT_DIR, subdir, f'{level_id}.json')
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, 'w') as f:
            json.dump(level, f, indent=2)
        bc = len(level['blockingCars'])
        print(f'  ✅ {level_id} ({diff}) — {bc}辆堵塞车, {steps}步')
        success += 1

    print(f'\n{"═" * 40}')
    print(f'生成完成: {success}/{len(configs)}  网格: {GRID_SIZE}×{GRID_SIZE}')
    print(f'出口行范围: {VALID_EXIT_ROWS}（无拐角）')


if __name__ == '__main__':
    main()
