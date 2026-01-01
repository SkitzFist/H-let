package game

import "core:time"
import "core:fmt"

import rl "vendor:raylib"

SAMPLES :: 100

BENCH       : [dynamic][SAMPLES]time.Duration
AVG         : [dynamic]time.Duration
TITLES      : [dynamic]string
TIME_START  : [dynamic]time.Time
LENGTH      : int = 0
INDEX       : int = 0
OPEN        : [dynamic]int
FRAME       : int = 0

bench_init :: proc() {
	BENCH = make([dynamic][SAMPLES]time.Duration, 0, 10)
	AVG = make([dynamic]time.Duration, 0, 10)
	TITLES = make([dynamic]string, 0, 10) 
	TIME_START = make([dynamic]time.Time, 0, 10)
	OPEN = make([dynamic]int, 0, 10)
}

bench_delete :: proc() {
	delete(BENCH)
	delete(TITLES)
	delete(AVG)
	delete(TIME_START)
	delete(OPEN)
}

bench_start :: proc(title:string) {
	if INDEX >= LENGTH {
		append_nothing(&BENCH)
		append_nothing(&AVG)
		append(&TITLES, title)
		append_nothing(&TIME_START)
		LENGTH += 1
	}

	TIME_START[INDEX] = time.now()
	append(&OPEN, INDEX)
	INDEX += 1
}

bench_end :: proc() {
	close := OPEN[len(OPEN) - 1]
	BENCH[close][FRAME % SAMPLES] = time.diff(TIME_START[close], time.now())

	ordered_remove(&OPEN, len(OPEN) - 1)
	
}

bench_frame_end :: proc() {
	INDEX = 0 
	FRAME += 1
}

bench_draw :: proc(x,y:f32) {
	//calc avg
	for &bench, i in BENCH {
		avg:i64
		for sample in bench {
			avg += i64(sample)
		}

		avg /= SAMPLES
		AVG[i] = time.Duration(avg)
	} 

	FONT_SIZE :: 20
	text_height := rl.MeasureTextEx(rl.GetFontDefault(), fmt.ctprintf("%s", TITLES[0]), FONT_SIZE, 1.0).y

	rl.DrawRectangle(i32(x), i32(y), 400, i32(text_height) * i32(LENGTH), rl.Color{130, 130, 130, 100})

	for &avg, i in AVG {
		rl.DrawText(
			fmt.ctprintf("%s %.4fms", TITLES[i], (f64(avg) / 1_000_000)),
			i32(x),
			(i32(y) + i32(i) * i32(text_height)),

			FONT_SIZE,
			rl.BLACK
		)
	}
}

calc_average_ms :: proc(times: []time.Duration) -> f64 {

	sum: f64

	for time in times {
		sum += f64(time)
	}

	return (sum / f64(len(times))) / 1_000_000
}
