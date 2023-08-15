# Flight Lang
A toy language written while on a flight. Admittedly I worked on it when I had some downtime on the vacation, so it really wasn't just during the flight, but I liked the name so it stays.

I've written a handful of programming languages over the years and usually they are overly ambitious consisting of many complex language features like Hindly-Milner type inference, null safety, polymorphic types and so on. None of them have ever been made public due to just never really finishing them since the feature set was too large. While on vacation I was looking to burn some time, so I challenged myself to write a very simple toy language during the flight and open source it at the end of the vacation. This is the result.

Note: This was written about as fast as I could type, there are 0 comments, 0 tests and many best practices are blatantly ignored. This should not serve as an example of how to implement things properly but still can act as a basic primer on how a trivial language can be implemented.

## Design
The language is statically typed and consists of just a few different types: `int`, `float`, `string`, `bool`, `void`, `fn` and `array`. I wanted to keep the type system as simple as possible with 0 type inference. As far as compilation, for simplicity, I decided to make it an interpreted language with a very trivial tree walking interpreter.

## Installation
* Build `swift build -c release`
* Add the executable at `./.build/release/flight` to your path

## Usage
```
flight file.flight another.flight
```

## Examples
The `Examples/` directory has some sample code of the language in use.

### Hello World [hello_world.flight](./Examples/hello_world.flight)
```rust
fn main() {
    print("Hello World!")
}
```

### Fibonacci [fibonacci.flight](./Examples/fibonacci.flight)
```rust
fn fibonacci(n: int) {
    let val_1 = 0
    let val_2 = 1

    let count = 0
    while count < n {
        let tmp = val_1
        val_1 = val_2
        val_2 = tmp + val_2
        count = count + 1
        print(val_2)
    }
}
```

### Brainfuck [brainfuck.flight](./Examples/brainfuck.flight)
To really test the language I thought it would be funny to implement a Brainfuck interpreter in the language. The idea of writing a interpreter with my freshly-written language/interpreter sounded fun. Seeing as I didn't have a lot of time, I ended up having ChatGPT generate me a simple one.

The full implementation can be found in the `brainfuck.flight` file.

```rust
fn main() {
    let result = run_brainfuck("++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.")
    print(result)
}
```

### Bubble Sort [bubble_sort.flight](./Examples/bubble_sort.flight)
```rust
fn main() {
    let values = [7, 2, 4, 6, 8, 3]
    let sorted = bubble_sort(values)
    print("Input: ", values)
    print("Result: ", sorted)
}

fn bubble_sort(array: [int]) [int] {
    let n = len(array)
    
    for i in 0 to n {
        for j in 0 to n - i - 1 {
            if array[j] > array[j + 1] {
                let temp = array[j]
                array[j] = array[j + 1]
                array[j + 1] = temp
            }
        }
    }

    return array
}
```
