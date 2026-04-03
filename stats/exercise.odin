package stats 

import "core:fmt"
import "core:strings"
import "core:strconv"

get_exercise :: proc(line: string) -> (Exercise, bool) {
    exercise: Exercise
    tokens := strings.split(line, " ")
    defer delete(tokens)

    index, ok := strconv.parse_uint(tokens[0])
    score_ok, tries_ok: bool
    if ok {
        exercise.score, score_ok = get_score(line)
        exercise.tries, tries_ok = get_tries(line)
        return exercise, score_ok && tries_ok
    }

    return exercise, false
}

get_score :: proc(line: string) -> (f32, bool) {
    tokens := strings.split(line, " ")
    defer delete(tokens)

    score, ok := strconv.parse_f32(tokens[len(tokens) - 1])
    if !ok {
        return 0, false
    }

    if score > 1 {
        return 0, false
    }

    return score, true
}

get_tries :: proc(line: string) -> (u8, bool) {
    tokens := strings.split(line, " ")
    defer delete(tokens)

    return u8(len(tokens) - 1), true
}

// Tests for this file
import "core:testing"

@(test)
get_exercise_test :: proc(t: ^testing.T) {
    exercise, ok := get_exercise("1 0.50 1.00")

    testing.expect_value(t, exercise, Exercise{1.00, 2})
}
