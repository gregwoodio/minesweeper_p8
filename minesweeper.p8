pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
function _init()
    cursor={
        x=8,
        y=8
    }
    grid={}
    num_mines=50
    rows=16
    cols=16
    timer=0
    gamestate=0
    state_menu=0
    state_playing=1
    state_game_lost=2
    state_game_won=3
    difficulty=1
    first_click=true

    -- sprites
    cursor_icon1 = 1
    cursor_icon2 = 2
    square = 3
    clicked_square = 4
    clicked_square_1 = 5
    clicked_square_2 = 6
    clicked_square_3 = 7
    clicked_square_4 = 8
    clicked_square_5 = 9
    clicked_square_6 = 10
    clicked_square_7 = 11
    clicked_square_8 = 12
    flag = 13
    bomb = 14
    menu_pointer = 15

    --explosion particles
    ps={}
    num_particles=100
    gravity=0.1
    max_lifetime=100
    min_lifetime=60
    velocity=4
    ticker=0
    colors={2,8,8,8,9,9,9,10,10,10}

    setup_grid()
end

function _draw()
    cls()

    -- for testing
    --for row = 1, rows do
    --    for col = 1, cols do
    --        spr(get_square_sprite(row, col), (col-1)*8, (row-1)*8)
    --    end
    --end

    draw_grid()

    if gamestate == state_playing then
        draw_cursor()
    end

    foreach(ps, draw_particle)

    if gamestate == state_menu then
        draw_menu()
    elseif gamestate == state_game_lost then
        draw_lost()
    elseif gamestate == state_game_won then
        draw_won()
    end
end

function _update60()
    foreach(ps, update_particle)

    if gamestate == state_menu then
        if btnp(2) then
            difficulty -= 1
            if (difficulty < 1) difficulty = 1
        elseif btnp(3) then
            difficulty += 1
            if (difficulty >= 3) difficulty = 3
        elseif btnp(5) then
            setup_grid()
            gamestate = state_playing
        end
    elseif gamestate == state_game_lost or gamestate == state_game_won then
        if btnp(5) then
            gamestate = state_menu
        end
    elseif gamestate == state_playing then
        timer += 1
        if (timer % 60 == 0) timer = 0

        -- cursor movement
        if btnp(0) then --left
            cursor.x-=1
            if (cursor.x <= 0) cursor.x = 1
        elseif (btnp(1)) then -- right
            cursor.x+=1
            if (cursor.x > cols) cursor.x = cols
        elseif (btnp(2)) then -- up
            cursor.y-=1
            if (cursor.y <= 0) cursor.y = 1
        elseif (btnp(3)) then -- down
            cursor.y+=1
            if (cursor.y > rows) cursor.y = rows
        end

        -- button pushes
        if (btnp(4)) then -- Z
            -- flag current spot if not selected
            if grid[cursor.y][cursor.x].clicked == false then
                if grid[cursor.y][cursor.x].flagged then
                    grid[cursor.y][cursor.x].flagged = false
                else 
                    grid[cursor.y][cursor.x].flagged = true 
                end
            end
        elseif (btnp(5)) then -- X
            -- select square
            if grid[cursor.y][cursor.x].flagged == false then
                sfx(2, -1)
                select_square(cursor.y, cursor.x)
            end
        end

        -- check for win
        if gamestate == state_playing then
            local clicked_squares = 0
            for row = 1, rows do
                for col = 1, cols do
                    if (grid[row][col].clicked == true) clicked_squares += 1
                end
            end

            if clicked_squares == rows * cols - num_mines then
                gamestate = state_game_won
                sfx(0, -1)
            end
        end
    end
end

function setup_grid()
    if (difficulty == 1) num_mines = 10
    if (difficulty == 2) num_mines = 32
    if (difficulty == 3) num_mines = 64 

    first_click = true
    cursor={
        x=8,
        y=8
    }

    grid = {}

    -- make table of mines to shuffle
    local all_squares = {}
    for i = 1, num_mines do
        add(all_squares, {mined=true, neighbours=0, clicked=false, flagged=false})
    end

    for i = num_mines + 1, rows*cols do
        add(all_squares, {mined=false, neighbours=0, clicked=false, flagged=false})
    end

    -- shuffle
    for index = 1, rows*cols do
        rand = flr(rnd(rows*cols)) + 1
        tmp = all_squares[rand]
        all_squares[rand] = all_squares[index]
        all_squares[index] = tmp
    end

    -- put into grid
    index = 1
    for row = 1, rows do
        add(grid, {})
        for col = 1, cols do
            add(grid[row], all_squares[index])
            index+=1
        end
    end

    -- calculate neighbours
    calculate_neighbours()
end

function get_square_sprite(x, y)
    if (grid[x][y].flagged == true) return flag
    if (grid[x][y].clicked == false) return square
    if (grid[x][y].mined) return bomb
    if (grid[x][y].neighbours == 0) return clicked_square
    if (grid[x][y].neighbours == 1) return clicked_square_1
    if (grid[x][y].neighbours == 2) return clicked_square_2
    if (grid[x][y].neighbours == 3) return clicked_square_3
    if (grid[x][y].neighbours == 4) return clicked_square_4
    if (grid[x][y].neighbours == 5) return clicked_square_5
    if (grid[x][y].neighbours == 6) return clicked_square_6
    if (grid[x][y].neighbours == 7) return clicked_square_7
    if (grid[x][y].neighbours == 8) return clicked_square_8
    return square
end

function draw_grid()
    for row = 1, rows do
        for col = 1, cols do
            spr(get_square_sprite(row, col), (col-1)*8, (row-1)*8)
        end
    end
end

function draw_cursor()
    local cursor_icon = cursor_icon1
    if (timer > 30) cursor_icon = cursor_icon2
    spr(cursor_icon, (cursor.x-1)*8, (cursor.y-1)*8)
end

function draw_won()
    map(0, 0, 20, 56, 11, 2)
    print('press x to play again', 25, 97, 0)
end

function draw_lost()
    map(0, 2, 16, 56, 12, 2)
    print('press x to play again', 25, 97, 0)
end

function draw_menu()
    -- title 
    map(0, 4, 39, 16, 7, 2)
    map(0, 6, 20, 32, 11, 8)

    print('easy', 33, 65, 0)
    print('medium', 33, 73, 0)
    print('hard', 33, 81, 0)
    print('press x to start', 33, 97, 0)

    spr(menu_pointer, 25, 64 + (difficulty - 1) * 8)
end

function select_square(y, x)
    if grid[y][x].clicked == true then
        return
    end

    grid[y][x].clicked = true
    if grid[y][x].mined then
        if first_click then
            -- shouldn't lose on the first click
            grid[y][x].mined = false

            -- find an unmined square, mine it
            local row = 1
            local col = 1
            local continue = true

            while continue do
                if grid[row][col].mined == false then
                    grid[row][col].mined = true
                    continue = false
                else 
                    col += 1
                    if col >= cols then
                        col = 1
                        row += 1
                    end
                end
            end

            -- need calculate_neighboursed to recalculate neighbours now
            calculate_neighbours()
        else
            sfx(1)
            add_particles(y, x)
            gamestate=state_game_lost
            return
        end
    end
    first_click = false

    if grid[y][x].neighbours == 0 then
       if (y - 1 > 0 and x - 1 > 0) select_square(y-1, x-1)
       if (y - 1 > 0) select_square(y-1, x)
       if (y - 1 > 0 and x + 1 <= cols) select_square(y-1, x+1)
       if (x - 1 > 0) select_square(y, x-1)
       if (x + 1 <= cols) select_square(y, x+1)
       if (y + 1 <= rows and x - 1 > 0) select_square(y+1, x-1)
       if (y + 1 <= rows) select_square(y+1, x)
       if (y + 1 <= rows and x + 1 <= cols) select_square(y+1, x+1)
    end
end

function calculate_neighbours()
    for row = 1, rows do
        for col = 1, cols do
            grid[row][col].neighbours = 0
        end
    end

    for row = 1, rows do
        for col = 1, cols do
            if (row - 1 > 0 and col - 1 > 0 and grid[row - 1][col - 1].mined) grid[row][col].neighbours+=1
            if (row - 1 > 0 and grid[row - 1][col].mined) grid[row][col].neighbours+=1
            if (row - 1 > 0 and col + 1 <= cols and grid[row - 1][col + 1].mined) grid[row][col].neighbours+=1
            if (col - 1 > 0 and grid[row][col - 1].mined) grid[row][col].neighbours+=1
            if (col + 1 <= cols and grid[row][col + 1].mined) grid[row][col].neighbours+=1
            if (row + 1 <= rows and col - 1 > 0 and grid[row + 1][col - 1].mined) grid[row][col].neighbours+=1
            if (row + 1 <= rows and grid[row + 1][col].mined) grid[row][col].neighbours+=1
            if (row + 1 <= rows and col + 1 <= cols and grid[row + 1][col + 1].mined) grid[row][col].neighbours+=1
        end
    end
end

function add_particles(y, x)
    local ax = (x-1)*8+4
    local ay = (y-1)*8+4
    for p = 1, num_particles do
        local veloX = rnd(velocity)
        local veloY = rnd(velocity)
        if (rnd() > 0.5) veloX *= -1
        if (rnd() > 0.5) veloY *= -1

        local p={
            x=ax,
            y=ay,
            dy=veloY,
            dx=veloX,
            lifetime=rnd_between(min_lifetime, max_lifetime),
            col=flr(rnd(colors)) + 1
        }
        add(ps, p)
    end
end

function update_particle(p)
    if p.lifetime <= 0 then
        del(ps, p)
    else
        p.dy += gravity
        --if p.x + p.dx > 127 then
        --    p.dx *= -0.8
        --end
        p.x += p.dx
        p.y += p.dy
        p.lifetime -= 1
    end
end

function draw_particle(p)
    pset(p.x, p.y, p.col)
end

function rnd_between(low, high)
    return flr(rnd(high - low + 1) + low)
end

__gfx__
00000000bb0000bbbbb00bbb66666665666666676666666766666667666666676666666766666667666666676666666766666667666666656666666600000000
00000000b000000bb000000b66666675666666666666c66666633366668886666616666666222266666bbb666600000666655566665886756666679600bb0000
0070070000000000b000000b6666667566666667666cc6676636663766666867661661676626666766b666676666660766566657665888756600766600bbb000
00077000000000000000000066666675666666666666c6666666636666688666661661666622266666bbbb666666606666655566665886756050006600bbbb00
00077000000000000000000066666675666666676666c6676666366766666867661111176666626766b666b76666066766566657665666756000006600bbb000
0070070000000000b000000b66666675666666666666c6666663666666666866666661666666626666b666b66666066666566656665666756000006600bb0000
00000000b000000bb000000b6777777566666667666ccc6766333337668886676666616766222667666bbb676666066766655567677777756600066600000000
00000000bb0000bbbbb00bbb55555555767676767676767676767676767676767676767676767676767676767676767676767676555555556666666600000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111000011110001111110001111000111000000011111000000001111101111101111100011111011111000011111000000000011111100000111111111001
01771000017710017777771001771000171000000017771000000001777101777101777100017771017771000017771000000000177777710001777777777101
01771000017710177771177101771000171000000017771000000001777101777101777100017771017771000017771000000001777711771017777111177101
01777100177710177710017101771000171000000017771001111001777101777101777710017771017771000017771000000001777100171017771000111101
00177711777100177710017101771000171000000017771001771001777101777101777771017771017771000017771000000001777100171017771000000001
00017777771000177710017101771000171000000017771001771001777101777101777777117771017771000017771000000001777100171017771111100001
00001777710000177710017101771000171000000017771017777101777101777101777777717771017771000017771000000001777100171017777777711001
00000177100000177710017101771000171000000017771017777101777101777101777777777771017771000017771000000001777100171001177777777101
00000177100000177710017101771000171000000017777177777717777101777101777177777771017771000017771000000001777711771000011117777101
00000177100000177771177101771000171000000001777177777717771001777101777117777771011111000017771001111101777777771000000001777101
00000177100000177777777101777111771000000001777777117777771001777101777101777771017771000017771001777101777777771011100001777101
00000177100000177777777101777777771000000001777777117777771001777101777100177771017771000017771111777101777777771017711117777101
00000177100000017777771000177777710000000000177771001777710001777101777100017771017771000017777777777100177777710017777777771001
00000111100000001111110000011111100000000000111111001111110001111101111100011111011111000011111111111100011111100001111111110001
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111101111001111100000001111101111101111100001111101111111111000000000000000000000000000000000000000000000000000000000000000
77777777101771001777100000001777101777101777100001777101777777771000000000000000000000000000000000000000000000000000000000000000
77711111101771001777710000017777101777101777100001777101777111111000000000000000000000000000000000000000000000000000000000000000
77710000001771001777710000017777101777101777710001777101777100000000000000000000000000000000000000000000000000000000000000000000
77711110001771001777771000177777101777101777771001777101777111100000000000000000000000000000000000000000000000000000000000000000
77777710001771001777771000177777101777101777777101777101777777100000000000000000000000000000000000000000000000000000000000000000
77711110001771001777777101777777101777101777777711777101777111100000000000000000000000000000000000000000000000000000000000000000
77710000001771001777777717777777101777101777777771777101777100000000000000000000000000000000000000000000000000000000000000000000
77710000001771001777177777771777101777101777177777777101777100000000000000000000000000000000000000000000000000000000000000000000
77711111101771001777117777711777101777101777117777777101777111111000000000000000000000000000000000000000000000000000000000000000
77777777101111001777117777711777101777101777101777777101777777771000000000000000000000000000000000000000000000000000000000000000
77777777101771001777101777101777101777101777100177777101777777771000000000000000000000000000000000000000000000000000000000000000
77777777101771001777101111101777101777101777100017777101777777771000000000000000000000000000000000000000000000000000000000000000
11111111101111001111100000001111101111101111100011111101111111111000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111111001111100000000111110111111111101111111111011111111000111111111101111111110000000000000000000000000000000000000000000
01777777777101777100000000177710177777777101777777771017777777100177777777101777777771000000000000000000000000000000000000000000
17777111177101777100000000177710177711111101777111111017711117710177711111101777111177100000000000000000000000000000000000000000
17771000111101777100111100177710177710000001777100000017710001710177710000001777100017100000000000000000000000000000000000000000
17771000000001777100177100177710177711110001777111100017710001710177711110001777100017100000000000000000000000000000000000000000
17771111100001777100177100177710177777710001777777100017710001710177777710001777100017100000000000000000000000000000000000000000
17777777711001777101777710177710177711110001777111100017710001710177711110001777100017100000000000000000000000000000000000000000
01177777777101777101777710177710177710000001777100000017711117710177710000001777111177100000000000000000000000000000000000000000
00011117777101777717777771777710177710000001777100000017777777100177710000001777777771000000000000000000000000000000000000000000
00000001777100177717777771777100177711111101777111111017711111000177711111101777777710000000000000000000000000000000000000000000
11100001777100177777711777777100177777777101777777771017711000000177777777101777777771000000000000000000000000000000000000000000
17711117777100177777711777777100177777777101777777771017711000000177777777101777117777100000000000000000000000000000000000000000
17777777771000017777100177771000177777777101777777771017711000000177777777101777101777100000000000000000000000000000000000000000
01111111110000011111100111111000111111111101111111111011111000000111111111101111100111100000000000000000000000000000000000000000
__label__
0cc00cc0ccc0ccc0ccc0cc00cc000cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c000c0c0ccc0ccc0c0c0c0c0c0c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c000c0c0c0c0c0c0ccc0c0c0c0c0ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c000c0c0c0c0c0c0c0c0c0c0c0c000c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc0cc00c0c0c0c0c0c0c0c0ccc0cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000660666066000000006066606660600066606600666066606660600000000000066066606060666000000060666066606000666066006660666066606000
60006060606060600000060060000600600060006060606066606000060000000000600060606060600000000600600006006000600060606060666060000600
60006060666060600000600066000600600066006060666060606600006000000000666066606060660000006000660006006000660060606660606066000060
60006060606060600000060060000600600060006060606060606000060000000000006060606660600000000600600006006000600060606060606060000600
66606600606066600000006060006660666066606060606060606660600000000000660060600600666000000060600066606660666060606060606066606000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606060660000000600066066600000066066606660600000006660060000000000666066600660606066606660000000000000000000000000000000000000
60606060606000006000606060600000600006006060600000006060006000000000606060006000606066606000000000000000000000000000000000000000
66006060606000006000606066000000600006006600600066606600006000000000660066006660606060606600000000000000000000000000000000000000
60606060606000006000606060600000600006006060600000006060006000000000606060000060606060606000000000000000000000000000000000000000
60600660606000000600660060600000066006006060666000006060060000000000606066606600066060606660000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06606060606066606600066060606600000000000000000000000000000000000000666066606660066006606660000000000000000000000000000000000000
60006060606006006060606060606060000000000000000000000000000000000000606060006060606060600600000000000000000000000000000000000000
66606660606006006060606060606060000000000000000000000000000000000000660066006600606060600600000000000000000000000000000000000000
00606060606006006060606066606060000000000000000000000000000000000000606060006060606060600600000000000000000000000000000000000000
66006060066006006660660066606060000000000000000000000000000000000000606066606660660066000600000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606600066066606660600060000000660066606660066006600000000000000000600006600000000000000000000000000000000000000000000000000000
06006060600006006060600060000000606060006660606060000000000000000000600060000000000000000000000000000000000000000000000000000000
06006060666006006660600060000000606066006060606066600000000000000000600066600000000000000000000000000000000000000000000000000000
06006060006006006060600060000000606060006060606000600000000000000000600000600000000000000000000000000000000000000000000000000000
66606060660006006060666066606660666066606060660066000000000000000000666066000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06606600000000606600666066606600666066606660600000000000000000000000666060606600666066600000006066006660666066006660666066606000
60006060000006006060060060606060606066606000060000000000000000000000666060606060060060600000060060600600606060606060666060000600
60006060000060006060060066006060666060606600006000000000000000000000606066006060060066000000600060600600660060606660606066000060
60006060000006006060060060606060606060606000060000000000000000000000606060606060060060600000060060600600606060606060606060000600
06606660000000606660666060606060606060606660600000000000000000000000606060606660666060600000006066606660606060606060606066606000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06606600000000000000000000000000000000000000666006600000066006600000606066600000666000006600666066606660066066600660666060600000
60006060000000000000000000000000000000000000060060600000600060600000606060600000606000006060060060606000600006006060606060600000
60006060000000000000000000000000000000000000060060600000600060600000606066600000666000006060060066006600600006006060660066600000
60006060000000000000000000000000000000000000060060600000606060600000606060000000606000006060060060606000600006006060606000600000
06606660000006000600000000000000000000000000060066000000666066000000066060000000606000006660666060606660066006006600606066600000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60606660606006600660660066606660066000000000666006600000066060600660066006606660000066606060666066600660660006600000000000000000
60606000606060006060606060000600600000000000060060600000600060606060606060006000000060606060060006006060606060000000000000000000
66006600666060006060606066000600600000000000060060600000600066606060606066606600000066006060060006006060606066600000000000000000
60606000006060006060606060000600606000000000060060600000600060606060606000606000000060606060060006006060606000600000000000000000
60606660666006606600606060006660666000000000060066000000066060606600660066006660000066600660060006006600606066000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ee0eee0e0000ee0eee0eee000000000000000000000eee00ee00000eee0e0e0eee0e0000ee0eee0eee000000ee0eee0eee0eee0eee0eee0ee000ee0eee00ee0
e000e0e0e000e0e0e0e0e000000000000000000000000e00e0e00000e000e0e0e0e0e000e0e0e0e0e0000000e000e0e0e0e00e00e0e00e00e0e0e000e000e000
eee0eee0e000e0e0ee00ee00000000000000000000000e00e0e00000ee000e00eee0e000e0e0ee00ee000000e000eee0ee000e00ee000e00e0e0e000ee00eee0
00e0e000e000e0e0e0e0e000000000000000000000000e00e0e00000e000e0e0e000e000e0e0e0e0e0000000e000e0e0e0e00e00e0e00e00e0e0e0e0e00000e0
ee00e000eee0ee00e0e0eee0000000000000000000000e00ee000000eee0e0e0e000eee0ee00e0e0eee000000ee0e0e0e0e00e00e0e0eee0eee0eee0eee0ee00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606660666006600660000066600660066000006660066000006660066006600660600066600000666066006660666006606660000060606660666060600000
60606060600060006000000060006000600000000600606000000600606060006000600060000000600060600600060060606060000060600600600060600000
66606600660066606660000066006660600000000600606000000600606060006000600066000000660060600600060060606600000060600600660060600000
60006060600000600060000060000060600000000600606000000600606060606060600060000000600060600600060060606060000066600600600066600000
60006060666066006600000066606600066000000600660000000600660066606660666066600000666066606660060066006060000006006660666066600000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606000666000006660660066606660666000006660066000006660066006600660600066600000666060606000600006600660666066606660660000000000
60606000060006006000606006006000606000000600606000000600606060006000600060000000600060606000600060006000606060006000606000000000
66606000060066606600606006006600660000000600606000000600606060006000600066000000660060606000600066606000660066006600606000000000
60606000060006006000606006006000606000000600606000000600606060606060600060000000600060606000600000606000606060006000606000000000
60606660060000006660606006006660606000000600660000000600660066606660666066600000600006606660666066000660606066606660606000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606000666000006660606000000660666000000660666066606000000006000000666006600000666066600660666006006060666066600000000000000000
60606000060006006000606000006060606000006000060060606000000060600000060060600000600060606000060060606060060006000000000000000000
66606000060066606600666000006060660000006000060066006000666060600000060060600000660066606660060060606060060006000000000000000000
60606000060006006000006000006060606000006000060060606000000066000000060060600000600060600060060066006060060006000000000000000000
60606660060000006000006000006600606000000660060060606660000006600000060066000000600060606600060006600660666006000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc0ccc0ccc00000ccc0ccc00cc00cc0ccc00000ccc0c0c0ccc00000ccc00cc0ccc00000ccc00cc0ccc0ccc00000ccc0cc00ccc00cc000000000000000000000
c000c000c0000000c0c00c00c000c0c0c0c000000c00c0c00c000000c000c0c0c0c00000ccc0c0c0c0c0c00000000c00c0c0c000c0c000000000000000000000
ccc0cc00cc000000ccc00c00c000c0c0ccc000000c000c000c000000cc00c0c0cc000000c0c0c0c0cc00cc0000000c00c0c0cc00c0c000000000000000000000
00c0c000c0000000c0000c00c000c0c0c0c000000c00c0c00c000000c000c0c0c0c00000c0c0c0c0c0c0c00000000c00c0c0c000c0c000000000000000000000
cc00ccc0ccc00000c000ccc00cc0cc00ccc00c000c00c0c00c000000c000cc00c0c00000c0c0cc00c0c0ccc00000ccc0c0c0c000cc0000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0cc0ccc00000c0c0ccc00cc0ccc0ccc000000000c0c0c0c0c0c00000ccc0ccc00cc00cc00000ccc000000cc00cc0ccc000000000000000000000000000000000
c0c0c0c00000c0c00c00c0000c000c000c000000c0c0c0c0c0c00000c0c00c00c000c0c00000c0c00000c000c0c0ccc000000000000000000000000000000000
c0c0cc000000c0c00c00ccc00c000c0000000000c0c0c0c0c0c00000ccc00c00c000c0c0ccc0ccc00000c000c0c0c0c000000000000000000000000000000000
c0c0c0c00000ccc00c0000c00c000c000c000000ccc0ccc0ccc00000c0000c00c000c0c00000c0c00000c000c0c0c0c000000000000000000000000000000000
cc00c0c000000c00ccc0cc00ccc00c0000000000ccc0ccc0ccc00c00c000ccc00cc0cc000000ccc00c000cc0cc00c0c000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000777070707770077077707770000077707770770077700770707077707770777077707770000070707770777070000000000000000000000000000000
07000000700070707070707070700700000077700700707070007000707070007000707070007070000070700700777070000000000000000000000000000000
00700000770007007770707077000700000070700700707077007770707077007700777077007700000077700700707070000000000000000000000000000000
07000000700070707000707070700700000070700700707070000070777070007000700070007070000070700700707070000000000000000000000000000000
70000000777070707000770070700700000070707770707077707700777077707770700077707070070070700700707077700000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66606000666066600660666000000660666066606660606066606660000066600000600066606660666060000000666066606660066066600000000000000000
60606000600060606000600000006000606060600600606060606000000060600000600060606060600060000000600006006060600006000000000000000000
66606000660066606660660000006000666066600600606066006600000066600000600066606600660060000000660006006600666006000000000000000000
60006000600060600060600000006000606060000600606060606000000060600000600060606060600060000000600006006060006006000000000000000000
60006660666060606600666000000660606060000600066060606660000060600000666060606660666066600000600066606060660006000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
101112131415161718191a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
202122232425262728292a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10111213141b1c1d1e1f30310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20212223242b2c2d2e2f40410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3233343536373800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4243444546474800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505152535455565758595a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
606162636465666768696a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000500001b0301b030000003e0502105021050210002c0002505025050250002c0002e0502e0502b00000000000000000018050180500f0000f0002c0502c0502c0502c0502c0500000000000000000000000000
00020000136102f6202d6302b64022640286402a6502665024650226601e6601d6501b650176501565012640116400d6400c6300a620096200762006610056100461004610046100361003610036100461004610
00020000100501205015050180501b0501d0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
