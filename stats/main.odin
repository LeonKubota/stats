package stats

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

EXERCISE_MAX_COUNT :: 512

VARIABLES :: enum u8{
    TOTAL,
    FINISHED,
    TRIES,
    TOTAL_SCORE,
    BEGAN,
}

variables: [len(VARIABLES)]u16

Category :: struct{
    name: string,
    index: u8,
    contains_copy: bool,
    total_tries: u16,
    total_exercises: u16,
    began_exercises: u16,
    finished_exercises: u8,
    total_score: f32,
    total: u16,
    subcategories: [64]Subcategory,
}

Subcategory :: struct{
    name: string,
    index: f32,
    is_copy: bool,
    total_tries: u16,
    total_exercises: u8,
    began_exercises: u16,
    finished_exercises: u8,
    total_score: f32,
    total: u16,
    exercises: [EXERCISE_MAX_COUNT]Exercise,
}

Exercise :: struct{
    score: f32,
    tries: u8,
}

winsize :: struct{
    ws_row: u16,
    ws_col: u16,
    ws_xpixel: u16,
    ws_ypixel: u16,
}

main :: proc() {
    // Parse input arguments:
    options: Options
    if !parse_console(&options) {
        return
    }

    // Open the selected file
    data, err := os.read_entire_file_from_file(options.file, context.allocator)
    if err != nil {
        fmt.printf("error: could not open file '%s'\n", options.file)
        return
    }
    defer delete(data)

    lines := string(data)

    categories: [dynamic]Category

    category: Category
    subcategory: Subcategory
    exercise: Exercise

    category_index: u8
    subcategory_index: u8

    line_number: u8 = 1

    for line in strings.split_lines_iterator(&lines) {
        tokens := strings.split(line, " ")

        _, is_number := strconv.parse_uint(tokens[0])
        
        // Category
        if tokens[0] == "=" {
            // Get name
            category.name = strings.split_after_n(line, " ", 3)[2]
            category.index = category_index + 1

            append(&categories, category)
            category_index += 1
            subcategory_index = 0

            category.total_exercises = 0
            category.began_exercises = 0

        // Subcategory
        } else if tokens[0] == "==" {
            categories[category_index - 1].subcategories[subcategory_index].total_exercises = 0
            subcategory.name = strings.cut(line, 3)

            // Get index (== >5.2< Random subcategory)
            parse_ok: bool
            subcategory.index, parse_ok = strconv.parse_f32(tokens[2])
            if !parse_ok {
                fmt.printf("error [%i]: could not parse subcategory index\n", line_number)
                return
            }

            categories[category_index - 1].subcategories[subcategory_index] = subcategory

            // Total exercises
            total_exercises, ok := strconv.parse_uint(tokens[1])
            if !ok {
                fmt.printf("error [%i]: could not parse total exercises\n", line_number)
                return
            }

            categories[category_index - 1].subcategories[subcategory_index].total_exercises = u8(total_exercises)
            categories[category_index - 1].total_exercises += u16(total_exercises)
            variables[VARIABLES.TOTAL] += u16(total_exercises)

            subcategory_index += 1
            exercise = Exercise{ score = 0.0, tries = 0 }
            for i: u8; i < 255; i += 1 {
                subcategory.exercises[i] = exercise
            }

        // Subcategory link
        } else if tokens[0] == ">>" {
            // Get the linked subcategory index
            linking_index, ok := strconv.parse_f32(tokens[1])
            if !ok {
                fmt.printf("error [%i]: could not parse subcategory linking index\n", line_number)
                return
            }

            // Find the linked subcategory
            found: bool
            linked_subcategory: Subcategory
            for category in categories {
                for subcategory in category.subcategories {
                    if (subcategory.index == linking_index) {
                        found = true
                        linked_subcategory = subcategory
                    }
                }
            }


            if found {
                // Copy over the data
                subcategory = linked_subcategory
                subcategory.is_copy = true

                // Add it to a category
                categories[category_index - 1].subcategories[subcategory_index] = subcategory

                // Copy data to parent category
                categories[category_index - 1].total_tries += u16(subcategory.total_tries)              // Total tries
                categories[category_index - 1].total_exercises += u16(subcategory.total_exercises)      // Total exercises
                categories[category_index - 1].began_exercises += subcategory.began_exercises           // Began exercises
                categories[category_index - 1].finished_exercises += u8(subcategory.finished_exercises) // Finished exercises

                // Manage score
                categories[category_index - 1].total_score += subcategory.total_score

                // Says the category contains a copy
                categories[category_index - 1].contains_copy = true

                subcategory_index += 1
                exercise = Exercise{ score = 0.0, tries = 0 }
                for i: u8; i < 255; i += 1 {
                    subcategory.exercises[i] = exercise
                }
            } else {
                // Did not find a linked subcategory
                fmt.printf("error [%i]: could not find the subcategory, ensure it is defined before\n", line_number)
                return
            }

        // Exercise
        } else if is_number {
            exercise, ok := get_exercise(line)
            if !ok {
                fmt.printf("error [%i]: failed to parse exercise\n", line_number)
                return
            }

            exercise_index, _ := strconv.parse_uint(tokens[0])

            subcategory.exercises[exercise_index] = exercise

            // Tries
            categories[category_index - 1].subcategories[subcategory_index - 1].total_tries += u16(exercise.tries)
            categories[category_index - 1].total_tries += u16(exercise.tries)
            variables[VARIABLES.TRIES] += u16(exercise.tries)

            // Finished
            if exercise.score == 1 {
                categories[category_index - 1].subcategories[subcategory_index - 1].finished_exercises += 1
                categories[category_index - 1].finished_exercises += 1
                variables[VARIABLES.FINISHED] += 1
            }

            // Began
            categories[category_index - 1].subcategories[subcategory_index - 1].began_exercises += 1
            categories[category_index - 1].began_exercises += 1
            variables[VARIABLES.BEGAN] += 1

            // Score
            categories[category_index - 1].subcategories[subcategory_index - 1].total_score += exercise.score
            categories[category_index - 1].total_score += exercise.score
            variables[VARIABLES.TOTAL_SCORE] += u16(exercise.score * 100)

            exercise_index += 1
        }
        line_number += 1
    }

    if options.f || options.failed { // Print failed
        if options.category == 0 && options.c == 0 {
            print_all_failed(categories)
        } else {
            // Check existance
            if options.category > len(categories) {
                fmt.println("error: category of index `%i` does not exist.\n", options.category)
                return
            } else if options.c > len(categories) {
                fmt.println("error: category of index `%i` does not exist.\n", options.c)
                return
            }
            print_single_failed(categories[options.category + options.c - 1])
        }
    } else { // Print all
        if options.category == 0 && options.c == 0 {
            print_all(categories)
        } else {
            // If category doesn't exist
            if options.category > len(categories) {
                fmt.printf("error: category of index `%i` does not exist.\n", options.category)
                return
            } else if options.c > len(categories) {
                fmt.printf("error: category of index `%i` does not exist.\n", options.c)
                return
            }
            print_single(categories[options.category + options.c - 1]) // -1 for "human" indexing
        }
    }
}
