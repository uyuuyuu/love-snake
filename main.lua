-- --- Deque Helper Functions ---
local function deque_appendleft(tbl, val)
    table.insert(tbl, 1, val)
end

local function deque_pop(tbl)
    return table.remove(tbl, #tbl)
end

-- --- Constants and Enums ---
-- PointType: Represents the type of content in a grid cell
PointType = {
    EMPTY = 0,
    FOOD = 1,
    BODY = 3
}

-- Direc: Represents directions (x, y offsets)
Direc = {
    UP = {x = 0, y = -1, name = "UP"},
    DOWN = {x = 0, y = 1, name = "DOWN"},
    LEFT = {x = -1, y = 0, name = "LEFT"},
    RIGHT = {x = 1, y = 0, name = "RIGHT"}
}

-- Add opposite method for Direc
function Direc.opposite(dir)
    if dir == Direc.UP then return Direc.DOWN
    elseif dir == Direc.DOWN then return Direc.UP
    elseif dir == Direc.LEFT then return Direc.RIGHT
    elseif dir == Direc.RIGHT then return Direc.LEFT
    end
    return nil
end
Direc.ALL = {Direc.UP, Direc.DOWN, Direc.LEFT, Direc.RIGHT}

-- Pos: Represents a position (x, y) on the grid
Pos = {}
Pos.__index = Pos

function Pos.new(x, y)
    local o = {x = x, y = y}
    setmetatable(o, Pos)
    return o
end

function Pos.__eq(a, b)
    if not b then return false end
    return a.x == b.x and a.y == b.y
end

-- Get adjacent position in a given direction
function Pos:adj(direc)
    return Pos.new(self.x + direc.x, self.y + direc.y)
end

-- Get all adjacent positions
function Pos:all_adj()
    local adjs = {}
    for _, dir in ipairs(Direc.ALL) do
        table.insert(adjs, self:adj(dir))
    end
    return adjs
end

-- Get direction from self to a destination position
function Pos:direc_to(des)
    for _, dir in ipairs(Direc.ALL) do
        if self.x + dir.x == des.x and self.y + dir.y == des.y then
            return dir
        end
    end
    return nil
end

-- Calculate Manhattan distance between two positions
function Pos.manhattan_dist(pos1, pos2)
    return math.abs(pos1.x - pos2.x) + math.abs(pos1.y - pos2.y)
end

--- Map Class ---
Map = {}
Map.__index = Map

function Map.new(num_rows, num_cols)
    local o = {
        num_rows = num_rows,
        num_cols = num_cols,
        food = nil,
        grid = {}
    }
    setmetatable(o, Map)
    o:reset_grid()
    return o
end

function Map:reset_grid()
    self.grid = {}
    for r = 0, self.num_rows - 1 do
        self.grid[r] = {}
        for c = 0, self.num_cols - 1 do
            self.grid[r][c] = PointType.EMPTY
        end
    end
end

-- Check if a position is within map bounds
function Map:is_in_bounds(pos)
    return pos.x >= 0 and pos.x < self.num_rows and pos.y >= 0 and pos.y < self.num_cols
end

-- Check if a position is safe (empty or food)
function Map:is_safe(pos)
    if not self:is_in_bounds(pos) then
        return false
    end
    local p_type = self.grid[pos.x][pos.y]
    return p_type == PointType.EMPTY or p_type == PointType.FOOD
end

-- Check if map is full
function Map:is_full()
    for r = 0, self.num_rows - 1 do
        for c = 0, self.num_cols - 1 do
            if self.grid[r][c] == PointType.EMPTY then
                return false
            end
        end
    end
    return true
end

-- Map copy method
function Map:copy()
    local new_map = Map.new(self.num_rows, self.num_cols)
    for r = 0, self.num_rows - 1 do
        for c = 0, self.num_cols - 1 do
            new_map.grid[r][c] = self.grid[r][c]
        end
    end
    if self.food then
        new_map.food = Pos.new(self.food.x, self.food.y)
    end
    return new_map
end

--- Snake Class ---
Snake = {}
Snake.__index = Snake

function Snake.new(map_obj, initial_pos, initial_direc)
    local o = {
        map = map_obj,
        body = {}, -- deque of Pos objects
        direc = initial_direc,
        len = 1
    }
    setmetatable(o, Snake)
    deque_appendleft(o.body, initial_pos)
    o.map.grid[initial_pos.x][initial_pos.y] = PointType.BODY
    return o
end

function Snake:head()
    return self.body[1]
end

function Snake:tail()
    return self.body[#self.body]
end

-- Simulate snake movement along a path (used for virtual snakes)
function Snake:move_path(path_direcs)
    for _, direc in ipairs(path_direcs) do
        local new_head_pos = self:head():adj(direc)
        deque_appendleft(self.body, new_head_pos)
        self.map.grid[new_head_pos.x][new_head_pos.y] = PointType.BODY
        
        if not (self.map.food and new_head_pos == self.map.food) then
            local tail_pos = deque_pop(self.body)
            self.map.grid[tail_pos.x][tail_pos.y] = PointType.EMPTY
        else
            self.map.grid[self.map.food.x][self.map.food.y] = PointType.BODY
            self.map.food = nil
        end
        self.len = #self.body
    end
end

-- Snake copy method
function Snake:copy()
    local new_map = self.map:copy()
    local new_snake = Snake.new(new_map, Pos.new(self:head().x, self:head().y), self.direc)
    new_snake.body = {}

    for i = 1, #self.body do
        deque_appendleft(new_snake.body, Pos.new(self.body[#self.body - i + 1].x, self.body[#self.body - i + 1].y)) 
    end
    new_snake.len = self.len

    new_map:reset_grid()
    for _, pos in ipairs(new_snake.body) do
        new_map.grid[pos.x][pos.y] = PointType.BODY
    end
    if self.map.food then
        new_map.grid[self.map.food.x][self.map.food.y] = PointType.FOOD
    end

    new_snake.map = new_map
    return new_snake, new_map
end

--- Solver Base Class (for inheritance) ---
BaseSolver = {}
BaseSolver.__index = BaseSolver

function BaseSolver.new(snake_obj)
    local o = {
        snake = snake_obj,
        map = snake_obj.map
    }
    setmetatable(o, BaseSolver)
    return o
end

--- TableCell for PathSolver ---
_TableCell = {}
_TableCell.__index = _TableCell

function _TableCell.new()
    local o = {}
    setmetatable(o, _TableCell)
    o:reset()
    return o
end

function _TableCell:reset()
    self.parent = nil
    self.dist = math.huge
    self.visit = false
end

--- PathSolver ---
PathSolver = {}
PathSolver.__index = PathSolver
setmetatable(PathSolver, BaseSolver)

function PathSolver.new(snake_obj)
    local o = BaseSolver.new(snake_obj)
    setmetatable(o, PathSolver)
    o._table = {}
    for r = 0, snake_obj.map.num_rows - 1 do
        o._table[r] = {}
        for c = 0, snake_obj.map.num_cols - 1 do
            o._table[r][c] = _TableCell.new()
        end
    end
    return o
end

function PathSolver:shortest_path_to_food()
    return self:path_to(self.map.food, "shortest")
end

function PathSolver:longest_path_to_tail()
    return self:path_to(self.snake:tail(), "longest")
end

function PathSolver:path_to(des_pos, path_type)
    if not des_pos then return {} end

    local original_des_type = self.map.grid[des_pos.x][des_pos.y]
    self.map.grid[des_pos.x][des_pos.y] = PointType.EMPTY

    local path = {}
    if path_type == "shortest" then
        path = self:shortest_path_to(des_pos)
    elseif path_type == "longest" then
        path = self:longest_path_to(des_pos)
    end

    self.map.grid[des_pos.x][des_pos.y] = original_des_type
    return path
end

function PathSolver:shortest_path_to(des_pos)
    self:_reset_table()

    local head = self.snake:head()
    self._table[head.x][head.y].dist = 0
    local queue = {}
    deque_appendleft(queue, head)

    while #queue > 0 do
        local cur = deque_pop(queue)
        if cur == des_pos then
            return self:_build_path(head, des_pos)
        end

        local first_direc
        if cur == head then
            first_direc = self.snake.direc
        else
            first_direc = self._table[cur.x][cur.y].parent:direc_to(cur)
        end

        local adjs = cur:all_adj()
        for i = #adjs, 2, -1 do
            local j = math.random(1, i)
            adjs[i], adjs[j] = adjs[j], adjs[i]
        end
        local straight_idx = nil
        for i, pos in ipairs(adjs) do
            if first_direc == cur:direc_to(pos) then
                straight_idx = i
                break
            end
        end
        if straight_idx and straight_idx ~= 1 then
            adjs[1], adjs[straight_idx] = adjs[straight_idx], adjs[1]
        end

        for _, pos in ipairs(adjs) do
            if self:_is_valid(pos) then
                local adj_cell = self._table[pos.x][pos.y]
                if adj_cell.dist == math.huge then
                    adj_cell.parent = cur
                    adj_cell.dist = self._table[cur.x][cur.y].dist + 1
                    deque_appendleft(queue, pos)
                end
            end
        end
    end
    return {}
end

function PathSolver:longest_path_to(des_pos)
    local path = self:shortest_path_to(des_pos)
    if #path == 0 then
        return {}
    end

    self:_reset_table()
    local cur = self.snake:head()

    self._table[cur.x][cur.y].visit = true
    for _, direc in ipairs(path) do
        cur = cur:adj(direc)
        self._table[cur.x][cur.y].visit = true
    end

    local idx = 1
    cur = self.snake:head()
    while true do
        if not path[idx] then break end

        local cur_direc = path[idx]
        local nxt = cur:adj(cur_direc)

        local tests = {}
        if cur_direc == Direc.LEFT or cur_direc == Direc.RIGHT then
            tests = {Direc.UP, Direc.DOWN}
        elseif cur_direc == Direc.UP or cur_direc == Direc.DOWN then
            tests = {Direc.LEFT, Direc.RIGHT}
        end

        local extended = false
        for _, test_direc in ipairs(tests) do
            local cur_test = cur:adj(test_direc)
            local nxt_test = nxt:adj(test_direc)
            
            if self:_is_valid(cur_test) and self:_is_valid(nxt_test) then
                self._table[cur_test.x][cur_test.y].visit = true
                self._table[nxt_test.x][nxt_test.y].visit = true
                table.insert(path, idx, test_direc)
                table.insert(path, idx + 2, Direc.opposite(test_direc))
                extended = true
                break
            end
        end

        if not extended then
            cur = nxt
            idx = idx + 1
            if idx > #path then
                break
            end
        end
    end

    return path
end

function PathSolver:_reset_table()
    for r = 0, self.map.num_rows - 1 do
        for c = 0, self.map.num_cols - 1 do
            self._table[r][c]:reset()
        end
    end
end

function PathSolver:_build_path(src, des)
    local path = {}
    local tmp = des
    while not (tmp.x == src.x and tmp.y == src.y) do
        local parent = self._table[tmp.x][tmp.y].parent
        if not parent then return {} end
        table.insert(path, 1, parent:direc_to(tmp))
        tmp = parent
    end
    return path
end

function PathSolver:_is_valid(pos)
    return self.map:is_safe(pos) and not self._table[pos.x][pos.y].visit
end

--- GreedySolver ---
GreedySolver = {}
GreedySolver.__index = GreedySolver
setmetatable(GreedySolver, BaseSolver)

function GreedySolver.new(snake_obj)
    local o = BaseSolver.new(snake_obj)
    setmetatable(o, GreedySolver)
    o._path_solver = PathSolver.new(snake_obj)
    return o
end

function GreedySolver:next_direc()
    local current_snake_ref = self.snake
    local current_map_ref = self.map

    self._path_solver.snake = current_snake_ref
    local path_to_food = self._path_solver:shortest_path_to_food()

    if #path_to_food > 0 then
        local s_copy, m_copy = current_snake_ref:copy()
        s_copy:move_path(path_to_food)

        if m_copy:is_full() then
            ai_path = path_to_food
            return path_to_food[1]
        end

        self._path_solver.snake = s_copy
        local path_to_tail_after_food = self._path_solver:longest_path_to_tail()
        
        if #path_to_tail_after_food > 0 then
            ai_path = path_to_food
            return path_to_food[1]
        end
    end

    self._path_solver.snake = current_snake_ref
    local path_to_tail_survival = self._path_solver:longest_path_to_tail()
    if #path_to_tail_survival > 0 then
        ai_path = path_to_tail_survival
        return path_to_tail_survival[1]
    end

    ai_path = {}

    local head = current_snake_ref:head()
    local fallback_direc = current_snake_ref.direc
    local max_dist = -1

    for _, adj_pos in ipairs(head:all_adj()) do
        if current_map_ref:is_safe(adj_pos) then 
            local dist = Pos.manhattan_dist(adj_pos, current_map_ref.food)
            if dist > max_dist then
                max_dist = dist
                fallback_direc = head:direc_to(adj_pos)
            end
        end
    end
    return fallback_direc
end

--- Game Core ---
local GRID_SIZE_X = 128
local GRID_SIZE_Y = 72
local CELL_SIZE = 15
local WIDTH = GRID_SIZE_X * CELL_SIZE
local HEIGHT = GRID_SIZE_Y * CELL_SIZE

-- Colors (Optimized for better contrast and vibrancy)
local BACKGROUND_COLOR = {0.1, 0.1, 0.1, 1} -- Dark background
local GRID_LINE_COLOR = {0.2, 0.2, 0.2, 1} -- Slightly lighter grid lines
local SNAKE_HEAD_COLOR = {0.2, 0.8, 0.2, 1} -- Vibrant green for head
local SNAKE_BODY_COLOR = {0.15, 0.6, 0.15, 1} -- Slightly darker green for body
local FOOD_COLOR = {1, 0.2, 0.2, 1} -- Bright red for food
local AI_PATH_COLOR = {0.2, 0.5, 1, 1} -- Sky blue for AI path
local TEXT_COLOR = {1, 1, 1, 1} -- White text

-- Game states
local GAME_RUNNING = 0
local GAME_OVER = 1

-- Game variables
local game_map
local snake
local greedy_solver
local game_state
local ai_path = {} -- Global for drawing the path

--- Game Functions ---
function love.load()
    love.window.setTitle("Snake")
    love.window.setFullscreen(true)
    love.keyboard.setKeyRepeat(false)
    math.randomseed(os.time())
    resetGame()
end

function resetGame()
    game_map = Map.new(GRID_SIZE_X, GRID_SIZE_Y)
    snake = Snake.new(game_map, Pos.new(math.floor(GRID_SIZE_X / 2), math.floor(GRID_SIZE_Y / 2)), Direc.RIGHT)
    
    game_map.food = generateFoodPos()
    game_map.grid[game_map.food.x][game_map.food.y] = PointType.FOOD

    greedy_solver = GreedySolver.new(snake)

    game_state = GAME_RUNNING
    ai_path = {}
end

function generateFoodPos()
    while true do
        local food_pos = Pos.new(math.random(0, GRID_SIZE_X - 1), math.random(0, GRID_SIZE_Y - 1))
        local occupied_by_snake = false
        for _, segment_pos in ipairs(snake.body) do
            if segment_pos == food_pos then
                occupied_by_snake = true
                break
            end
        end
        if not occupied_by_snake then
            return food_pos
        end
    end
end

function love.update(dt)
    if game_state == GAME_RUNNING then
        local next_direc = greedy_solver:next_direc()
        local head = snake:head()
        local new_head_pos = head:adj(next_direc)

        local is_colliding = false
        if not game_map:is_in_bounds(new_head_pos) then
            is_colliding = true
        else
            for i = 1, #snake.body - 1 do
                if new_head_pos == snake.body[i] then
                    is_colliding = true
                    break
                end
            end
        end
        
        if is_colliding then
            game_state = GAME_OVER
            return
        end

        snake.direc = next_direc

        deque_appendleft(snake.body, new_head_pos)
        game_map.grid[new_head_pos.x][new_head_pos.y] = PointType.BODY

        if new_head_pos == game_map.food then
            snake.len = snake.len + 1
            game_map.food = generateFoodPos()
            game_map.grid[game_map.food.x][game_map.food.y] = PointType.FOOD
        else
            local tail_pos = deque_pop(snake.body)
            game_map.grid[tail_pos.x][tail_pos.y] = PointType.EMPTY
        end
    end
end

function love.draw()
    love.graphics.clear(BACKGROUND_COLOR)

    -- Draw grid lines
    love.graphics.setColor(GRID_LINE_COLOR)
    love.graphics.setLineWidth(1)
    for x = 0, WIDTH, CELL_SIZE do
        love.graphics.line(x, 0, x, HEIGHT)
    end
    for y = 0, HEIGHT, CELL_SIZE do
        love.graphics.line(0, y, WIDTH, y)
    end

    -- Draw AI path
    if #ai_path > 0 then
        love.graphics.setColor(AI_PATH_COLOR)
        love.graphics.setLineWidth(2)
        local current_draw_pos = snake:head()
        for i, direc in ipairs(ai_path) do
            local next_draw_pos = current_draw_pos:adj(direc)
            love.graphics.line(
                current_draw_pos.x * CELL_SIZE + CELL_SIZE / 2, current_draw_pos.y * CELL_SIZE + CELL_SIZE / 2,
                next_draw_pos.x * CELL_SIZE + CELL_SIZE / 2, next_draw_pos.y * CELL_SIZE + CELL_SIZE / 2
            )
            current_draw_pos = next_draw_pos
        end
        love.graphics.setLineWidth(1)
    end

    -- Draw snake body
    for i, segment_pos in ipairs(snake.body) do
        local color = SNAKE_BODY_COLOR
        if i == 1 then -- Head
            color = SNAKE_HEAD_COLOR
        end
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", segment_pos.x * CELL_SIZE, segment_pos.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
    end

    -- Draw food
    if game_map.food then
        love.graphics.setColor(FOOD_COLOR)
        love.graphics.rectangle("fill", game_map.food.x * CELL_SIZE, game_map.food.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
    end

    -- Draw score
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.setFont(love.graphics.newFont(20)) -- Slightly larger font for better readability
    love.graphics.print("Score: " .. snake.len - 1, 10, 10)

    -- Game Over message
    if game_state == GAME_OVER then
        love.graphics.setFont(love.graphics.newFont(30))
        love.graphics.setColor(TEXT_COLOR)
        local text = "Game Over! Score: " .. snake.len - 1 .. " (Press R to restart)"
        local font_width = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, (WIDTH - font_width) / 2, HEIGHT / 2 - 15)
    end
end

function love.keypressed(key)
    if key == "r" or game_state == GAME_OVER then
        resetGame()
    end
end
