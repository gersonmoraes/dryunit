# Redefining OCaml story on Unit Testing

If you've ever written unit tests in virtually any language other than OCaml you can understand how I felt whenever I wrote my OCaml tests: *Odd*. Constantly reminded of the limitations of design choices and sometimes even the ecossystem. Usually feeling that there should propbably be a better way to define this. *If only OCaml was more be like other languages*...

*The simpler way to do things* I've always wanted would be making test code as trivial as good ol' OCaml. The same compilation process. Integrate test code with whatever tools I use for the project - that includes Merlin, since I usually want autocompletion everywhere. Dont make tests a special thing - they are not. Dont change the syntax. Don't show me boiler plate. Don't *make me* write boiler plate. Stay far away from my beautiful clean source code, *thank you very much*.

If you are familiar all of this, you may want to skip ahead to the [Dryunit](#dryunit) section.



## The workflow problem

As you probably know, OCaml doesn't have reflections. This means that the fact most frameworks require you to *redeclare* every test is because OCaml doesnt let anyone inspect things like module structrue and function names at runtime. So the job falls on the developer: *you need to write reflection related code yourself*, in order to frameworks like OUnit and Alcotest show you proper error messages.

You can still rely on some sort of witchcraft, like writing test code in comments, or putting some test code inlined with source code, using some special syntax and conventions.

In here, we're only considering the scenario where we have our source code as a library and our tests in a diferent folder as an executable using that library. Usually related to this workflow:

    1. Write your tests as normal functions, using the conventions of a popular test framework.
    2. Describe all your previously written tests to the framework, giving even a name to the current suite, since module name will be lost at compile.
    3. Compile and run the executable

The frustrating is `#2`. A really annoying point: anytime you update your test code, you have to be aware of the its effect in the bootstrapping area. Worst, havens forbid, if you add tons of tests and forget to add some of the corresponding lines in the bootstrap. Those tests will never run and you will never get a warning. There was no elegant way around it. *Until now*.



## The story behind the project

I have been wanting to write an OCaml test framework for sometime now. There is, until I gave a good look at Mirage's [Alcotest](https://github.com/mirage/alcotest) project, and then realized that, no matter how good a new test library could be, there was still the underlining bootstrapping problem.

I was toying with the idea of a non-pervasive, nearly invisible test framework. Something to make unit tests *DRY* and allow *Convention over Configuration* for what gets to be active or ignored, without bypassing compilation. To be truly *DRY*, I shouldn't even consider migrating existing tests from the most popular libraries, like OUnit or Alcotest. I wanted to create a tool that would allow you to, basically, ***cutt bootstapping off your test code***.

Dryunit is the result of that effort. In the future, maybe it will have its own corresponding unit test framework. Today, it's not even a tool. It's just a tiny dependency-free ppx.



## Dryunit

`ppx_dryunit` is an OCaml extension that automates boilerplate creation at build time, for the main unit test frameworks in OCaml ecosystem.  It uses a few conventions to detect and setup the testsuites, and that is it.


### How DRY can you be?

This is a simplified version of Alcotest's sample test at the time of writing.

````ocaml
module MyLib = struct
  let capit letter = Char.uppercase letter
  let plus int_list = List.fold_left (fun a b -> a + b) 0 int_list
end

let test_capit () =
  Alcotest.(check char) "same chars"  'A' (Mylib.capit 'a')

let test_plus () =
  Alcotest.(check int) "same ints" 7 (Mylib.plus [1;1;2;3])
````



As you can see, all bootstrapping code is absent. To run this, create a new file in the same directory with this line:

```ocaml
let () = [%alcotest]
```

This is your main test executable. It replaces whatever you used to setup your tests before. From now on, any test function in any OCaml file in the same dir will be recognized and sent to Alcotest. The same thing works for OUnit. *Neat!*


That's it. No special syntax for tests, no need to migrate existing test code, not even a new command line to integrate. You can leverage the same workflow and existing test code. No learning curve. Just the same building system you already use - *one line of code to activate the ppx and your done*.

The only convention here is that all unit tests must start with the name "test". So if you need to disable a test `test_feature_works`, you can just rename it to `_test_feature_works`.



### Under the hood

When processing the extension, the following happens:

- Dryunit checks if it's running from a `*build/*` directory, and exits otherwise. *This matters because when interacting with Merlin in your editor, you don't benefit from the generation of metadata*.

- Look the directory where the extension was declared and find all `*.ml` files. Each one will represent a corresponding testsuite.

- Extract a structured representation of each file, using OCaml parser. This is fast, but produce boilerplate files.

- Create a test suite with all functions starting with `"test"`. *Functions inside nested modules or variables will be ignored*.

- Replace `[%alcotest]` in the AST with the apropriate code to bootstrap Alcotest.



## The future of Dryunit

One of the big advantages of the project is that is *framework independent*. It changes the AST to write the code a developer would, filling in the framework conventions for bootstrapping. It relies on the user building system to provide the apropriate dependencies, so the project itself is *light*. It's fairly easy to add new test frameworks that support similar workflows.

This feels like an ambitious project, but is actually *low maintanance*. Thanks to the amazing work developed in the [OCaml-Migrate-Parsetree](https://github.com/ocaml-ppx/ocaml-migrate-parsetree) project, this ppx already works on all major OCaml versions, since 4.02.3.

New configuration options and conventions would be something to be desired. Like, *before* and *after* hooks, or a parameter to define a list of directories to look for test files, in order to allow one to set test projects as libraries in the building system, not executables.

Anyhow, since `ppx_dryunit` uses the same tools people already know, and rely on, and yet bypasses completely the need to write manual, painful and easily-outdated bootstrapping code, I expect the project to have good reception. It will stay for a long time, or at the very least, be replaced for an equivalent tool. Either way, *thank god*, our tests will stay the same.
