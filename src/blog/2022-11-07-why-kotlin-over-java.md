---
title: Why Kotlin over Java
tags:
  - blog
  - Kotlin
  - Java
date: "2022-11-07"
layout: base/index.pug
highlighting: true
---

> Repost from [the Cloudflight Engineering blog](https://engineering.cloudflight.io/why-kotlin-over-java)

<!--toc:start-->

- [A plain old Java object according to Kotlin](#a-plain-old-java-object-according-to-kotlin)
  - [Plain old Java objects](#plain-old-java-objects)
  - [Constructors](#constructors)
  - [Equals, Hashcode, ToString](#equals-hashcode-tostring)
- [Safer and more expressive code](#safer-and-more-expressive-code)
  - [Expressions](#expressions)
  - [Smart casting](#smart-casting)
  - [Pattern matching](#pattern-matching)
  - [Sealed classes](#sealed-classes)
  - [Functional abstraction](#functional-abstraction)
- [Other features](#other-features)
  - [Compile-time null safety](#compile-time-null-safety)
  - [Interoperability with Java](#interoperability-with-java)
  - [Preferred immutability](#preferred-immutability)
  - [Internal visibility](#internal-visibility)
- [Clarifications of some risks](#clarifications-of-some-risks)
  - [Is it possible to find Kotlin developers?](#is-it-possible-to-find-kotlin-developers)
  - [Is Kotlin future-proof?](#is-kotlin-future-proof)
- [Conclusion](#conclusion)
- [Sources](#sources)
<!--toc:end-->

For most projects related to server-side software development, Cloudflight
prefers to use Kotlin over Java. This has a multitude of reasons, some of which
I'll describe in this blog post.

# A plain old Java object according to Kotlin

When transferring data from one place to another with Java, it's common to use
a plain old java object (POJO). Usually, this is an object with some properties
and accessor methods.

Kotlin provides means to reduce the amount of code used in these objects. In
this example, we'll take a POJO, and convert it into a Kotlin class.

## Plain old Java objects

Let's start with a `UserDto`, for now, it will only contain a few fields, and
accessor methods for those fields. It could look as follows:

```java
public class UserDto {
    private Integer id;

    private String name;

    private String email;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
```

If you are using IntelliJ IDEA and would copy this code into a Kotlin file,
we'll get a notification asking if the Java code should be converted to Kotlin
code. After clicking yes, we get the following code.

```kotlin
class UserDto {
    var id: Int? = null
    var name: String? = null
    var email: String? = null
}
```

The piece of Kotlin code is 25 lines shorter compared to the Java code. All the
accessor methods can be omitted by the syntax of Kotlin.

## Constructors

To be able to instantiate a fully initialized copy of the earlier defined Java
object we would need to add a constructor. If we would make one for all our
arguments, it would look as follows:

```java
public class UserDto {
    public UserDto(
        id: Integer,
        name: String,
        email: String
    ) {
        this.id = id;
        this.name = name;
        this.email = email;
    }

    ...
}
```

Adding the constructor in Java would add more code. if we add more properties
to the class, we would have to update the constructor as well.

Meanwhile, on the Kotlin side, we can update our class as follows to add a
constructor.

```kotlin
class UserDto(
    var id: Int? = null,
    var name: String? = null,
    var email: String? = null
)
```

By replacing the braces with parentheses, we added a constructor to the class,
without adding a line of code. Both constructors are called the same way in
both Java and Kotlin code.

## Equals, Hashcode, ToString

Commonly, Java classes use some boilerplate methods as well. This would add
more code to our `UserDto` class.

```java
public class UserDto {
    ...

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        UserDto userDto = (UserDto) o;
        return id.equals(userDto.id) && name.equals(userDto.name) && email.equals(userDto.email);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, name, email);
    }

    @Override
    public String toString() {
        return "UserDto{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", email='" + email + '\'' +
                '}';
    }
}
```

Similar to the constructor, when updating our class, we would need to update
these methods as well.

Kotlin again provides a solution for this with only one line change. Kotlin
introduces data classes. Data classes define a handful of extra methods for us
(`equals`, `hashCode`, `toString` and `copy`). If we would use a data class to
give us these methods, our class will look as follows.

```kotlin
data class UserDto(
    var id: Int? = null,
    var name: String? = null,
    var email: String? = null
)
```

> But all of this code can be generated by any modern IDE. Why would I use
> Kotlin for this?

The resulting Java version has a whopping 63 lines of code, and 63 lines of
maintenance. Meanwhile, the Kotlin version has only 5 lines. Leading to a
codebase that's easier to navigate, has fewer surprises and is easier to
maintain.

I took a quick look at a relatively small project and found 35 similar classes
to the freshly refactored class. I'd estimate that using Kotlin in this project
would save 4000 lines of code and just POJO's.

# Safer and more expressive code

The following section will refactor a function from a Java-looking function,
into a Kotlin function, using features Kotlin provides us to write safe and
more expressive code.

First, we define a basic tree. A tree is either a branch with multiple `Tree`
items or a leaf with one value in it. Here is the Java version:

```java
interface Tree<T> {

}

class Branch<T> implements Tree<T> {
    public Branch(List<Tree<T>> nodes) {
        this.nodes = nodes;
    }

    List<Tree<T>> nodes;

    public List<Tree<T>> getNodes() {
        return nodes;
    }
}

class Leaf<T> implements Tree<T> {
    public Leaf(T value) {
        this.value = value;
    }

    T value;

    public T getValue() {
        return value;
    }
}
```

In Kotlin it would look as follows:

```kotlin
interface Tree<T>

class Branch<T>(val nodes: List<Tree<T>>) : Tree<T>

class Leaf<T>(val value: T) : Tree<T>
```

Next, we write a function to refactor into Kotlin. For this example, I made a
function to sum all numbers in the tree. In Java you could make it like this:

```java
class TreeUtil {
    static Integer sumTree(Tree<Integer> tree) {
        Integer count;

        if (tree instanceof Branch) {
            var branch = (Branch<Integer>) tree;
            count = 0;
            for (var node : branch.getNodes()) {
                count += sumTree(node);
            }
        } else if (tree instanceof Leaf) {
            var leaf = (Leaf<Integer>) tree;
            count = leaf.getValue();
        } else {
            throw new IllegalArgumentException("Unknown variant");
        }

        return count;
    }
}
```

Directly translating this to Kotlin gives me the following:

```kotlin
fun sumTree(tree: Tree<Int>): Int {
    var count: Int

    if (tree is Branch) {
        val branch = tree as Branch

        count = 0
        for (node in branch.nodes) {
            count += sumTree(node)
        }
    } else if (tree is Leaf) {
        val leaf = tree as Leaf
        count = leaf.value
    } else {
        throw IllegalArgumentException("Unknown variant")
    }

    return count
}
```

Now let's apply some of Kotlin's features to make this function more readable
and expressive.

## Expressions

A common pattern in Java is to define a variable set to null and update it
during an if statement. In Kotlin, if statements are expressions, this allows
us to return values from the if statement instead of mutating it during the if
statement. Allowing us to refactor the method as follows.

```kotlin
fun sumTree(tree: Tree<Int>): Int = if (tree is Branch) {
    val branch = tree as Branch
    var count = 0
    for (node in branch.nodes) {
        count += sumTree(node)
    }

    count
} else if (tree is Leaf) {
    val leaf = tree as Leaf
    leaf.value
} else {
    throw IllegalArgumentException("Unknown variant")
}
```

Instead of returning a value, we can return the if statement as a whole, making
for less noise code.

## Smart casting

Type casting an object in Java requires two steps. First, a check needs to be
made if the type matches the expected one, then the value needs to be cast into
another type. Kotlin introduces smart casting here. After checking the type,
the compiler already knows the actual type, so here we could omit the cast.
When using smart casting, our code would look like this.

```kotlin
fun sumTree(tree: Tree<Int>): Int = if (tree is Branch) {
    var count = 0
    for (node in tree.nodes) {
        count += sumTree(node)
    }

    count
} else if (tree is Leaf) {
    tree.value
} else {
    throw IllegalArgumentException("Unknown variant")
}
```

After calling the type check, `tree` becomes either a `Branch` or a `Leaf`
implicitly, allowing us to remove the unsafe typecast and directly access the
properties from the `tree` variable.

## Pattern matching

Kotlin allows us to pattern match for a type, then we could check the type
without adding cases to an if statement, refactoring our code to the following.

```kotlin
fun sumTree(tree: Tree<Int>): Int = when (tree) {
    is Branch -> {
        var count = 0
        for (node in tree.nodes) {
            count += sumTree(node)
        }

        count
    }
    is Leaf -> tree.value
    else -> throw IllegalArgumentException("Unknown variant")
}
```

The `when` statement in Kotlin is similar to the `switch` in Java, but it
provides some superpowers compared to `switch`, primarily that we can define a
condition for each branch instead of only checking equality.

## Sealed classes

Kotlin introduces sealed classes, all implementors of a sealed class must be in
the same module as the sealed class itself. We can make our tree a sealed class
in the following manner:

```kotlin
sealed interface Tree<T>
```

Now the compiler knows all possible types a tree could be, allowing us to
safely remove the else clause from the when statement.

```kotlin
fun sumTree(tree: Tree<Int>): Int = when (tree) {
    is Branch -> {
        var count = 0
        for (node in tree.nodes) {
            count += sumTree(node)
        }

        count
    }
    is Leaf -> tree.value
}
```

If we would remove the sealed modifier, the program will not compile because
the pattern match is not exhaustive. Because only two versions of `Tree` are
possible, we only need to check for those types.

## Functional abstraction

To clean up the last part of the Java code, we could rewrite the iteration of
all nodes in the branch into something more readable.

```kotlin
fun sumTree(tree: Tree<Int>): Int = when (tree) {
    is Branch -> tree.nodes.sumOf { node -> sumTree(node) }
    is Leaf -> tree.value
}
```

The `sumOf` method is a standard library method turning iterable into an int.
If we would write it ourselves it could look like this:

```kotlin
fun <T> Iterable<T>.sumOf(operation: (T) -> Int): Int {
    var sum = 0
    for (item in this) {
        sum += operation(item)
    }

    return sum
}
```

A few things are happening here:

- We are defining an extension method, even though `Iterable` is not in our
  class, we can write functions for it. This is not possible in Java at all.
- The parameter `operation` is a function that expects type `T` and returns a
  `Int`.

Using the tools that Kotlin provides, the Java-like function is rewritten into 4
lines of expressive Kotlin code.

# Other features

Next, some other features of Kotlin.

## Compile-time null safety

One of the primary selling points for Kotlin is compile-time null safety. For a
variable to be null, it needs to be defined as nullable. Nullable variables
need to be handled or checked. This is one of the primary defects in Java
systems.

In Kotlin, a parameter can be assigned as nullable as follows:

```kotlin
fun sumTwoNumbers(n1: Int?, n2: Int?): Int {
    return n1 + n2 // Will not compile because n1 or n2 could be null
}
```

This example will not compile. Both `n1` and `n2` could be null. To make it
compile, we need to add some checks or have different behavior for null values.
Using smart-casting, we can safely add the values.

```kotlin
fun sumTwoNumbers(n1: Int?, n2: Int?): Int {
    if (n1 == null || n2 == null) throw Exception("Invalid value passed")
    return n1 + n2
}
```

## Interoperability with Java

Kotlin was designed to be fully cross-compatible with JVM Java. This allows us
to define logic or structures in either Kotlin or Java code, and call them from
both Kotlin and Java code. I'll take the earlier created `UserDto` as an
example.

```kotlin
data class UserDto(var id: Int, var name: String, var email: String)
```

With Gradle or Maven properly configured, we can call this code the Java side
in an idiomatically correct manner. It would look at follows:

```java
void main() {
    var user = new UserDto(1, "Cloudflight", "info@cloudflight.io");

    System.out.println(user.toString()); // UserDto(id=1, name=Cloudflight, email=info@cloudflight.io)
    System.out.println(user.getId()); // 1
}
```

## Preferred immutability

Java includes a `final` keyword, which disallows a variable from being
reassigned. A small example is shown below.

```java
void main() {
    var someMutableValue = "The first value";
    someMutableValue = "The value is updated"

    final var someImmutableValue = "The first value"
    someImmutableValue = "Will not compile now"
}
```

The `final` keyword does add noise to the code. Kotlin has a much more subtile
approach to this.

```kotlin
fun main() {
    var someMutableValue = "The first value";
    someMutableValue = "The value is updated"

    val someImmutableValue = "The first value"
    someImmutableValue = "Will not compile now"
}
```

Kotlin has two keywords for defining variables, `val` and `var`. `val` is used
for immutable variables, while `var` is for mutable variables.

This pattern can also be found in the Kotlin standard library.

Due to historical reasons, most collections in Java have a method named `add`,
which adds an item to the collection. This includes immutable lists. These
usually throw an `UnsupportedOperationException` at runtime when called.

```java
void main() {
    var list = new ArrayList();
    list.add(1);
    list.add(2);

    var immutableList = List.of();
    immutableList.add(1); // Throws an UnsupportedOperationException at runtime
}
```

In Kotlin, collections are immutable by default. To create a mutable list
`mutableListOf` should be called, and to create an immutable list, `listOf` is
called. An immutable list has no to add items to a collection, this could
prevent runtime defects.

```kotlin
fun main() {
    var list = mutableListOf()
    list.add(1)
    list.add(2)

    var immutableList = listOf()
    immutableList.add(1) // Will not compile here
}
```

## Internal visibility

Kotlin introduces a new visibility keyword, `internal`. This allows code to be
visible in the following cases:

- The internal code can be called within the same Maven project.
- The internal code can be called within the same Gradle source set.
- The internal code can be called by code compiled with the same `kotlinc`
  invocation.

This helps with modularizing codebases when working with separate modules.

# Clarifications of some risks

There are a few points commonly made on why switching to Kotlin is a bad idea.
This section explains why these points are not as strong as commonly thought
of.

## Is it possible to find Kotlin developers?

According to the StackOverflow developer survey 2022, 9.2% of developers work
with Kotlin compared to 33.27% who work with Java. The survey also finds that
at least 10% of these developers want to work with Kotlin instead of Java.

Turning a Java developer into a Kotlin developer is easy. Writing Kotlin
compared to writing Java is very similar. Both are usually run in the same
environment as well. Both for development and execution. Together with the
better code safety of Kotlin, a Java developer can quickly write good Kotlin
code.

## Is Kotlin future-proof?

At [I/O 2019](https://android-developers.googleblog.com/2019/05/google-io-2019-empowering-developers-to-build-experiences-on-Android-Play.html),
Google announced that Kotlin is going to be the preferred programming language
for all Android apps. This shows that Google is certain Kotlin will stay and
Kotlin stays for a long time to come.

According to Google, 80% of the top 1000 android apps use Kotlin as a
programming language.

# Conclusion

So, a few of the reasons why Cloudflight (and other companies) prefer to use
Kotlin over Java for server-side app development.

# Sources

- [Android developers blog](https://android-developers.googleblog.com/)
- [StackOverflow developer survey 2022](https://survey.stackoverflow.co/2022/)
- [Kotlin docs](https://kotlinlang.org/docs/home.html)
