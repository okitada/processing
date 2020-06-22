/*
2048 Game

2019/10/05 Start porting from C# to Processing
 */
 
int auto_mode = 4; // >=0 depth
int calc_gap_mode = 0; // gap mode(0:normal 1:gap+1 2:*2 3:+gap 4:+gap/10 5:+gap)
int print_mode = 100;
int print_mode_turbo = 1;
int pause_mode = 0;
int one_time = 1;
int seed = 1;
int turbo_minus_percent       = 55;
int turbo_minus_percent_level = 1;
int turbo_minus_score         = 20000;
int turbo_minus_score_level   = 1;
int turbo_plus_percent        = 10;
int turbo_plus_percent_level  = 1;
int turbo_plus_score          = 200000;
int turbo_plus_score_level    = 1;

int D_BONUS = 10;
boolean D_BONUS_USE_MAX = true;
int GAP_EQUAL = 0;

int INIT2 = 1;
int INIT4 = 2;
int RNDMAX = 4;
double GAP_MAX = 100000000.0;
int XMAX = 4;
int YMAX = 4;
int XMAX_1 = (XMAX-1);
int YMAX_1 = (YMAX-1);

int [][] board = new int[XMAX][YMAX];
int sp = 0;

int [] pos_x = new int[XMAX*YMAX];
int [] pos_y = new int[XMAX*YMAX];
int [] pos_val = new int[XMAX*YMAX];
int score;
int gen;
int count_2 = 0;
int count_4 = 0;
int count_calcGap = 0;
int count_getGap = 0;

long start_time;
long last_time;
long total_start_time;
long total_last_time;

int count = 1;
int sum_score = 0;
int max_score = 0;
long max_seed = 0;
int min_score = (int)GAP_MAX;
long min_seed = 0;
double ticks_per_sec = 1000;

int CELLSIZE_X;
int CELLSIZE_Y;
int COLORMAX = 255*8;
color [] color_table = new color[COLORMAX];
int color_index_max;
boolean running = true;

void init_color_table() {
  int index = 0, i, r, g, b;
  // red
  r = 255;
  g = 0;
  b = 0;
  for (i = 0; i < 255; i++) {
    // red => yellow
    color_table[index++] = color(r, g++, b);
  }
  for (i = 0; i < 255; i++) {
    // yellow => green
    color_table[index++] = color(r--, g, b);
  }
  for (i = 0; i < 255; i++) {
    // green => cyan
    color_table[index++] = color(r, g, b++);
  }
  for (i = 0; i < 255; i++) {
    // cyan => white
    color_table[index++] = color(r++, g, b);
  }
  for (i = 0; i < 255; i++) {
    // white => mazenta
    color_table[index++] = color(r, g--, b);
  }
  for (i = 0; i < 255; i++) {
    // mazenta => blue
    color_table[index++] = color(r--, g, b);
  }
  color_index_max = index;
}

int getCell(int x, int y) {
    return (board[x][y]);
}

int setCell(int x, int y, int n) {
    board[x][y] = (n);
    return (n);
}

void clearCell(int x, int y) {
    setCell(x, y, 0);
}

int copyCell(int x1, int y1, int x2, int y2) {
    return (setCell(x2, y2, getCell(x1, y1)));
}

void moveCell(int x1, int y1, int x2, int y2) {
    copyCell(x1, y1, x2, y2);
    clearCell(x1, y1);
}

void addCell(int x1, int y1, int x2, int y2) {
    board[x2][y2]++;
    clearCell(x1, y1);
    if (sp < 1) {
        addScore(1 << getCell(x2, y2));
    }
}

boolean isEmpty(int x, int y) {
    return (getCell(x, y) == 0);
}

boolean isNotEmpty(int x, int y) {
    return (!isEmpty(x, y));
}

boolean isGameOver() {
    int [] _nEmpty = {0};
    double [] _nBonus = {0.0};
    boolean ret = isMovable(_nEmpty, _nBonus);
    if (ret) {
        return false;
    } else {
        return true;
    }
}

int getScore() {
    return (score);
}

int setScore(int sc) {
    score = (sc);
    return (score);
}

int addScore(int sc) {
    score += (sc);
    return score;
}

void clear() {
    for (int y = 0; y < YMAX; y++) {
        for (int x = 0; x < XMAX; x++) {
            clearCell(x, y);
        }
    }
}

void disp(double gap, boolean debug) {
    long now = millis();
    if (count == 0) {
        print(String.format("[%d:%d] %d (%.2f/%.1f sec) %.6f %s seed=%d 2=%.2f%%\n", count, gen, getScore(), (double)(now-last_time)/ticks_per_sec, (double)(now-start_time)/ticks_per_sec, gap, getTime(), seed, (double)(count_2)/(double)(count_2+count_4)*100));
    } else {
        print(String.format("[%d:%d] %d (%.2f/%.1f sec) %.6f %s seed=%d 2=%.2f%% Ave.=%d\n", count, gen, getScore(), (double)(now-last_time)/ticks_per_sec, (double)(now-start_time)/ticks_per_sec, gap, getTime(), seed, (double)(count_2)/(double)(count_2+count_4)*100, (sum_score+getScore())/count));
    }
    last_time = now;
    if (running && debug) {
        background(0);
        //println("");
        for (int y = 0; y < YMAX; y++) {
            for (int x = 0; x < XMAX; x++) {
                int v = getCell(x, y);
                if (v > 0) {
                    String s = str(1<<v);
                    fill(color_table[color_index_max*(v-1)/16]);
                    rect(x * CELLSIZE_X, y * CELLSIZE_Y, CELLSIZE_X, CELLSIZE_Y);
                    fill(0,0,0);
                    textSize(CELLSIZE_X/5);
                    text(s, x * CELLSIZE_X+(CELLSIZE_X-(s.length())*10)/2, y * CELLSIZE_Y+CELLSIZE_Y/2+CELLSIZE_Y/5/2);
                    print(String.format("%5s ",s));
                } else {
                    //fill(0,0,0);
                    //rect(x * CELLSIZE_X, y * CELLSIZE_Y, CELLSIZE_X, CELLSIZE_Y);
                    print(String.format("%5s ","."));
                }
            }
            println("");
        }
    }
}

void init_game() {
    gen = 1;
    setScore(0);
    start_time = millis();
    last_time = start_time;
    clear();
    appear();
    appear();
    count_2 = 0;
    count_4 = 0;
    count_calcGap = 0;
    count_getGap = 0;
    disp(0.0, print_mode == 1);
}

String getTime() {
//        return DateTime.Now.ToString("yyyy/MM/dd HH:mm:ss");
    return str(year())+"/"+nf(month(),2)+"/"+nf(day(),2)+" "+nf(hour(),2)+":"+nf(minute(),2)+":"+nf(second(),2);
}

boolean appear() {
    int n = 0;
    for (int y = 0; y < YMAX; y++) {
        for (int x = 0; x < XMAX; x++) {
            if (isEmpty(x, y)) {
                pos_x[n] = x;
                pos_y[n] = y;
                n++;
            }
        }
    }
    if (n> 0) {
        int v;
        int i = (int)(random(65535) % n);
        if ((random(65535) % RNDMAX) >= 1) {
            v = INIT2;
            count_2++;
        } else {
            v = INIT4;
            count_4++;
        }
        int x = pos_x[i];
        int y = pos_y[i];
        setCell(x, y, v);
        return true;
    }
    return false;
}

int countEmpty() {
    int ret = 0;
    for (int y = 0; y < YMAX; y++) {
        for (int x = 0; x < XMAX; x++) {
            if (isEmpty(x, y)) {
                ret++;
            }
        }
    }
    return ret;
}

int move_up() {
    int move = 0;
    int yLimit;
    int yNext;
    for (int x = 0; x < XMAX; x++) {
        yLimit = 0;
        for (int y = 1; y < YMAX; y++) {
            if (isNotEmpty(x, y)) {
                yNext = y - 1;
                while (yNext >= yLimit) {
                    if (isNotEmpty(x, yNext)) {
                        break;
                    }
                    if (yNext == 0) {
                        break;
                    }
                    yNext = yNext - 1;
                }
                if (yNext < yLimit) {
                    yNext = yLimit;
                }
                if (isEmpty(x, yNext)) {
                    moveCell(x, y, x, yNext);
                    move++;
                } else {
                    if (getCell(x, yNext) == getCell(x, y)) {
                        addCell(x, y, x, yNext);
                        move++;
                        yLimit = yNext + 1;
                    } else {
                        if (yNext+1 != y) {
                            moveCell(x, y, x, yNext+1);
                            move++;
                            yLimit = yNext + 1;
                        }
                    }
                }
            }
        }
    }
    return move;
}

int move_left() {
    int move = 0;
    int xLimit;
    int xNext;
    for (int y = 0; y < YMAX; y++) {
        xLimit = 0;
        for (int x = 1; x < XMAX; x++) {
            if (isNotEmpty(x, y)) {
                xNext = x - 1;
                while (xNext >= xLimit) {
                    if (isNotEmpty(xNext, y)) {
                        break;
                    }
                    if (xNext == 0) {
                        break;
                    }
                    xNext = xNext - 1;
                }
                if (xNext < xLimit) {
                    xNext = xLimit;
                }
                if (isEmpty(xNext, y)) {
                    moveCell(x, y, xNext, y);
                    move++;
                } else {
                    if (getCell(xNext, y) == getCell(x, y)) {
                        addCell(x, y, xNext, y);
                        move++;
                        xLimit = xNext + 1;
                    } else {
                        if (xNext+1 != x) {
                            moveCell(x, y, xNext+1, y);
                            move++;
                            xLimit = xNext + 1;
                        }
                    }
                }
            }
        }
    }
    return move;
}

int move_down() {
    int move = 0;
    int yLimit;
    int yNext;
    for (int x = 0; x < XMAX; x++) {
        yLimit = YMAX_1;
        for (int y = YMAX - 2; y >= 0; y--) {
            if (isNotEmpty(x, y)) {
                yNext = y + 1;
                while (yNext <= yLimit) {
                    if (isNotEmpty(x, yNext)) {
                        break;
                    }
                    if (yNext == YMAX_1) {
                        break;
                    }
                    yNext = yNext + 1;
                }
                if (yNext > yLimit) {
                    yNext = yLimit;
                }
                if (isEmpty(x, yNext)) {
                    moveCell(x, y, x, yNext);
                    move++;
                } else {
                    if (getCell(x, yNext) == getCell(x, y)) {
                        addCell(x, y, x, yNext);
                        move++;
                        yLimit = yNext - 1;
                    } else {
                        if (yNext-1 != y) {
                            moveCell(x, y, x, yNext-1);
                            move++;
                            yLimit = yNext - 1;
                        }
                    }
                }
            }
        }
    }
    return move;
}

int move_right() {
    int move = 0;
    int xLimit;
    int xNext;
    for (int y = 0; y < YMAX; y++) {
        xLimit = XMAX_1;
        for (int x = XMAX - 2; x >= 0; x--) {
            if (isNotEmpty(x, y)) {
                xNext = x + 1;
                while (xNext <= xLimit) {
                    if (isNotEmpty(xNext, y)) {
                        break;
                    }
                    if (xNext == XMAX_1) {
                        break;
                    }
                    xNext = xNext + 1;
                }
                if (xNext > xLimit) {
                    xNext = xLimit;
                }
                if (isEmpty(xNext, y)) {
                    moveCell(x, y, xNext, y);
                    move++;
                } else {
                    if (getCell(xNext, y) == getCell(x, y)) {
                        addCell(x, y, xNext, y);
                        move++;
                        xLimit = xNext - 1;
                    } else {
                        if (xNext-1 != x) {
                            moveCell(x, y, xNext-1, y);
                            move++;
                            xLimit = xNext - 1;
                        }
                    }
                }
            }
        }
    }
    return move;
}

double moveAuto(int autoMode) {
    int empty = countEmpty();
    int sc = getScore();
    if (empty >= XMAX*YMAX*turbo_minus_percent/100) {
        autoMode -= turbo_minus_percent_level;
    } else if (empty < XMAX*YMAX*turbo_plus_percent/100) {
        autoMode += turbo_plus_percent_level;
    }
    if (sc < turbo_minus_score) {
        autoMode -=turbo_minus_score_level;
    } else if (sc >= turbo_plus_score) {
        autoMode += turbo_plus_score_level;
    }
    return moveBest(autoMode, true);
}

void copy_board(int [][] to, int [][] from) {
    for (int y = 0; y < YMAX; y++) {
        for (int x = 0; x < XMAX; x++) {
            to[x][y] = from[x][y];
        }
    }
}

double moveBest(int nAutoMode, boolean move)  {
    double nGap;
    double nGapBest;
    int nDirBest = 0;
    int nDir = 0;
    int [][] board_bak = new int[XMAX][YMAX];
    copy_board(board_bak, board);
    sp++;
    nGapBest = GAP_MAX;
    if (move_up() > 0) {
        nDir = 1;
        nGap = getGap(nAutoMode, nGapBest);
        if (nGap < nGapBest) {
            nGapBest = nGap;
            nDirBest = 1;
        }
    }
    copy_board(board, board_bak);
    if (move_left() > 0) {
        nDir = 2;
        nGap = getGap(nAutoMode, nGapBest);
        if (nGap < nGapBest) {
            nGapBest = nGap;
            nDirBest = 2;
        }
    }
    copy_board(board, board_bak);
    if (move_down() > 0) {
        nDir = 3;
        nGap = getGap(nAutoMode, nGapBest);
        if (nGap < nGapBest) {
            nGapBest = nGap;
            nDirBest = 3;
        }
    }
    copy_board(board, board_bak);
    if (move_right() > 0) {
        nDir = 4;
        nGap = getGap(nAutoMode, nGapBest);
        if (nGap < nGapBest) {
            nGapBest = nGap;
            nDirBest = 4;
        }
    }
    copy_board(board, board_bak);
    sp--;
    if (move) {
        if (nDirBest == 0) {
            print("\n***** Give UP *****\n");
            nDirBest = nDir;
        }
        switch (nDirBest) {
        case 1:
            move_up();
            break;
        case 2:
            move_left();
            break;
        case 3:
            move_down();
            break;
        case 4:
            move_right();
            break;
        }
    }
    return nGapBest;
}

double getGap(int nAutoMode, double nGapBest) {
    double ret = 0.0;
    int [] nEmpty = {0};
    double [] nBonus = {0.0};
    count_getGap++;
    boolean movable = isMovable(nEmpty, nBonus);
    if (! movable) {
        ret = GAP_MAX;
    } else if (nAutoMode <= 1) {
        ret = getGap1(nGapBest, nEmpty[0], nBonus[0]);
    } else {
        double alpha = nGapBest * (double)(nEmpty[0]);
        for (int x = 0; x < XMAX; x++) {
            for (int y = 0; y < YMAX; y++) {
                if (isEmpty(x, y)) {
                    setCell(x, y, INIT2);
                    ret += moveBest(nAutoMode-1, false) * (RNDMAX - 1) / RNDMAX;
                    if (ret >= alpha) {
                        return GAP_MAX;
                    }
                    setCell(x, y, INIT4);
                    ret += moveBest(nAutoMode-1, false) / RNDMAX;
                    if (ret >= alpha) {
                        return GAP_MAX;
                    }
                    clearCell(x, y);
                }
            }
        }
        ret /= (double)(nEmpty[0]);
    }
    return ret;
}

double getGap1(double nGapBest, int nEmpty, double nBonus) {
    double ret = 0.0;
    double ret_appear = 0.0;
    double alpha = nGapBest * nBonus;
    boolean edgea = false;
    boolean edgeb = false;
    for (int x = 0; x < XMAX; x++) {
        for (int y = 0; y < YMAX; y++) {
            int v = getCell(x, y);
            edgea = (x == 0 || y == 0) || (x == XMAX - 1 || y == YMAX_1);
            if (v > 0) {
                if (x < XMAX_1) {
                    int x1 = getCell(x+1, y);
                    edgeb = (y == 0) || (x+1 == XMAX - 1 || y == YMAX_1);
                    if (x1 > 0) {
                        ret += calcGap(v, x1, edgea, edgeb);
                    } else {
                        ret_appear += calcGap(v, INIT2, edgea, edgeb) * (RNDMAX - 1) / RNDMAX;
                        ret_appear += calcGap(v, INIT4, edgea, edgeb) / RNDMAX;
                    }
                }
                if (y < YMAX_1) {
                    int y1 = getCell(x, y+1);
                    edgeb = (x == 0) || (x == XMAX - 1 || y+1 == YMAX_1);
                    if (y1 > 0) {
                        ret += calcGap(v, y1, edgea, edgeb);
                    } else {
                        ret_appear += calcGap(v, INIT2, edgea, edgeb) * (RNDMAX - 1) / RNDMAX;
                        ret_appear += calcGap(v, INIT4, edgea, edgeb) / RNDMAX;
                    }
                }
            } else {
                if (x < XMAX_1) {
                    int x1 = getCell(x+1, y);
                    edgeb = (y == 0) || (x+1 == XMAX - 1 || y == YMAX_1);
                    if (x1 > 0) {
                        ret_appear += calcGap(INIT2, x1, edgea, edgeb) * (RNDMAX - 1) / RNDMAX;
                        ret_appear += calcGap(INIT4, x1, edgea, edgeb) / RNDMAX;
                    }
                }
                if (y < YMAX_1) {
                    int y1 = getCell(x, y+1);
                    edgeb = (x == 0) || (x == XMAX - 1 || y+1 == YMAX_1);
                    if (y1 > 0) {
                        ret_appear += calcGap(INIT2, y1, edgea, edgeb) * (RNDMAX - 1) / RNDMAX;
                        ret_appear += calcGap(INIT4, y1, edgea, edgeb) / RNDMAX;
                    }
                }
            }
            if (ret + ret_appear/(double)(nEmpty) > alpha) {
                return GAP_MAX;
            }
        }
    }
    ret += ret_appear / (double)(nEmpty);
    ret /= nBonus;
    return ret;
}

double calcGap(int a, int b, boolean edgea, boolean edgeb) {
    count_calcGap++;
    double ret = 0;
    if (a > b) {
        ret = (double)(a - b);
        if (calc_gap_mode > 0 && ! edgea && edgeb) {
            switch (calc_gap_mode) {
            case 1:
                ret += 1;
                break;
            case 2:
                ret *= 2;
                break;
            case 3:
                ret += (double)(a);
                break;
            case 4:
                ret += (double)(a)/10;
                break;
            case 5:
                ret += (double)(a+b);
                break;
            }
        }
    } else if (a < b) {
        ret = (double)(b - a);
        if (calc_gap_mode > 0 && edgea && ! edgeb) {
            switch (calc_gap_mode) {
            case 1:
                ret += 1;
                break;
            case 2:
                ret *= 2;
                break;
            case 3:
                ret += (double)(b);
                break;
            case 4:
                ret += (double)(b)/10;
                break;
            case 5:
                ret += (double)(a+b);
                break;
            }
        }
    } else {
        ret = GAP_EQUAL;
    }
    return ret;
}

boolean isMovable(int [] ref_nEmpty, double [] ref_nBonus) {
    boolean ret = false;
    int nEmpty = 0;
    double nBonus = 1.0;
    int max_x = 0, max_y = 0;
    int max = 0;
    for (int y = 0; y < YMAX; y++) {
        for (int x = 0; x < XMAX; x++) {
            int val = getCell(x, y);
            if (val == 0) {
                ret = true;
                nEmpty++;
            } else {
                if (val > max) {
                    max = val;
                    max_x = x;
                    max_y = y;
                }
                if (! ret) {
                    if (x < XMAX_1) {
                        int x1 = getCell(x+1, y);
                        if (val == x1 || x1 == 0) {
                            ret = true;
                        }
                    }
                    if (y < YMAX_1) {
                        int y1 = getCell(x, y+1);
                        if (val == y1 || y1 == 0) {
                            ret = true;
                        }
                    }
                }
            }
        }
    }
    if ((max_x == 0 || max_x == XMAX_1) &&
        (max_y == 0 || max_y == YMAX_1)) {
        if (D_BONUS_USE_MAX) {
            nBonus = (double)(max);
        } else {
            nBonus = D_BONUS;
        }
    }
    ref_nEmpty[0] = nEmpty;
    ref_nBonus[0] = nBonus;
    return ret;
}

void setup() {
    size(400, 400);
    CELLSIZE_X = width / XMAX;
    CELLSIZE_Y = height / XMAX;
    init_color_table();

    println("auto_mode={0}", auto_mode);
    println("calc_gap_mode={0}", calc_gap_mode);
    println("print_mode={0}", print_mode);
    println("print_mode_turbo={0}", print_mode_turbo);
    println("pause_mode={0}", pause_mode);
    println("seed={0}", seed);
    println("one_time={0}", one_time);
    println("turbo_minus_percent={0}", turbo_minus_percent);
    println("turbo_minus_percent_level={0}", turbo_minus_percent_level);
    println("turbo_minus_score={0}", turbo_minus_score);
    println("turbo_minus_score_level={0}", turbo_minus_score_level);
    println("turbo_plus_percent={0}", turbo_plus_percent);
    println("turbo_plus_percent_level={0}", turbo_plus_percent_level);
    println("turbo_plus_score={0}", turbo_plus_score);
    println("turbo_plus_score_level={0}", turbo_plus_score_level);

    if (seed > 0) {
        randomSeed(seed);
    } else {
        randomSeed(hour()*3600+minute()*60+second()+millis());
    }
    total_start_time = millis();
    init_game();
}

void draw() {
    if (running) {
        double gap = moveAuto(auto_mode);
        gen++;
        appear();
        disp(gap, print_mode > 0 &&
            (gen%print_mode==0 ||
                (print_mode_turbo==1 && score>turbo_minus_score) ||
                (print_mode_turbo==2 && score>turbo_plus_score)));
        if (isGameOver()) {
            int sc = getScore();
            sum_score += sc;
            if (sc > max_score) {
                max_score = sc;
                max_seed = seed;
            }
            if (sc < min_score) {
                min_score = sc;
                min_seed = seed;
            }
            println("Game Over! (level="+auto_mode+" seed="+seed+") "+getTime()+" #"+count+" Ave.="+sum_score/count+" Max="+max_score+"(seed="+max_seed+") Min="+min_score+"(seed="+min_seed+")");
            println("getGap="+count_getGap+" calcGap="+count_calcGap+" "+(double)(D_BONUS)+","+(double)(GAP_EQUAL)+" "+
            turbo_minus_percent+"%,"+turbo_minus_percent_level+" "+
            turbo_minus_score+","+turbo_minus_score_level+" "+
            turbo_plus_percent+"%,"+turbo_plus_percent_level+" "+
            turbo_plus_score+","+turbo_plus_score_level+" "+
            print_mode_turbo+" calc_gap_mode="+calc_gap_mode);
            disp(gap, true);
            if (one_time > 0) {
                one_time--;
                if (one_time == 0) {
                    one_time = 1;
                    running = false;
                    total_last_time = millis();
                    print("Total time = "+(double)(total_last_time-total_start_time)/ticks_per_sec+" (sec)\n");
                }
            }
            if (pause_mode > 0) {
              // do nothing
            } else {
                seed++;
                randomSeed(seed);
                init_game();
                count++;
            }
        }
    }
}

void mousePressed() {
    running = true;
    seed++;
    randomSeed(seed);
    init_game();
    count++;
}
