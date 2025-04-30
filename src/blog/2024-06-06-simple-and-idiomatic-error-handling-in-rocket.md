---
tags:
  - blog
  - rust
  - rocket
  - eyre
date: "2024-06-06"
title: Simple and idiomatic error handling in rocket
layout: base/index.pug
highlighting: true
description: "Learn how to implement simple and idiomatic error handling in the Rocket framework using Rust. This guide explores leveraging the `eyre` crate, custom error types, the `?` operator, and RFC 7807-compliant error responses for clean and maintainable code."
---

The [Rocket framework](https://rocket.rs/) framework required endpoint to
return values that implement responder. The works similarly for `Result<T, E>`.
Both `T` and `E` need to implement responder. But what if you want to use a
library like [anyhow](https://github.com/dtolnay/anyhow) or
[eyre](https://github.com/eyre-rs/eyre) to simplify error handling while
keeping that idiomatic rust? Using some rust magic this is possible.

# The `?` operator

For more readable error handling, rust provides the `?` operator, which can
terminate a function early by aborting in case of an error when the function
returns a result. Lets take the following code

```rust
#[derive(Debug)]
enum MathError {
    DivisionByZero,
    NonPositiveLogarithm,
    NegativeSquareRoot,
}

fn div(x: f64, y: f64) -> Result<f64, MathError> {
    if y == 0.0 {
        Err(MathError::DivisionByZero)
    } else {
        Ok(x / y)
    }
}

fn div_twice(x: f64, y: f64) -> Result<f64, MathError> {
    let once = div(x, y)?;
    div(once, y)
}
```

If a zero would be passed to the `y` parameter in the `div_twice` function,
then the second division would never start in the first place. Under the hood
some extra magic happens as well.

If needed, `into` is called the error, to convert it into the required type.
With this in mind, lets start building our error. For this example in adhering
to [RFC 7807](https://datatracker.ietf.org/doc/html/rfc7807).

# Our error type

First lets define a error type. This type be passed around our application. For
this example, I'm using the `eyre` crate, but this would work with the `Error`
type in the `anyhow` crate as well.

```rust
#[derive(Debug)]
pub(crate) struct Error {
    inner: eyre::Report,
    error_type: Option<String>,
    status: Option<Status>,
    title: Option<String>,
    detail: Option<String>,
    instance: Option<String>,
}

impl Error {
    pub(crate) fn new(inner: impl Into<eyre::Report>) -> Self {
        Self {
            inner: inner.into(),
            status: None,
            error_type: None,
            title: None,
            detail: None,
            instance: None,
        }
    }

    pub(crate) fn with_status(self, status: Status) -> Self {
        let mut new = self;
        new.status = Some(status);
        new
    }
}

impl<E: Into<eyre::Report>> From<E> for Error {
    fn from(inner: E) -> Self {
        Self::new(inner)
    }
}
```

Our error type has the `inner` field, which points to the error itself. Here we
could get the backtrace of other information is needed. The remaining fields is
just metadata passed into the response.

A simple constructor is added along with the into method. The into method is
quite important here. It allows us to accept any `std::error::Error` to be cast
into our custom error.

Next a `Result` type:

```rust
pub(crate) type Result<T, E = Error> = std::result::Result<T, E>;
```

# Responding to requests

Lastly for our error related code, the code responding to in our endpoints.

```rust
#[derive(Debug, Clone, Serialize, PartialEq, Eq)]
struct ErrorResponse {
    #[serde(rename = "type")]
    error_type: String,
    status: u16,
    title: String,
    detail: Option<String>,
    instance: String,
}

impl<'r, 'o: 'r> Responder<'r, 'o> for Error {
    fn respond_to(self, request: &Request<'_>) -> response::Result<'o> {
        let status = self.status.unwrap_or(Status::InternalServerError);

        let error_response = ErrorResponse {
            error_type: self.error_type.unwrap_or_else(|| "about:blank".to_string()),
            status: status.code,
            title: self.title.unwrap_or_else(|| "An unknown error occured".to_string()),
            detail: self.detail,
            instance: self.instance.unwrap_or_else(|| request.uri().to_string()),
        };

        let error_string = serde_json::to_string(&error_response).unwrap();

        Response::build()
            .header(Header::new("Content-Type", "application/json+problem"))
            .status(status)
            .sized_body(error_string.len(), Cursor::new(error_string))
            .ok()
    }
}
```

First we define `ErrorResponse`, which is a simple object containing
information about what went wrong. It almost directly maps to our `Error`.

Based on our error we may be able to provide all needed data to the response
itself. If that's not the case, we can have some sane defaults.

# Wrapping it into Rocket

After defining all these types, we can use it in a rocket application as so:

```rust
#[rocket::get("/error")]
fn error_route() -> Error {
    io::Error::new(ErrorKind::Other, "Something went wrong").into()
}
```

In this route, we always return an error with the default response. To add a
status code to the response, we can use the `with_status` method defined
earlier.

```rust
#[rocket::get("/unauthorized")]
fn unauthorized_route() -> Error {
    io::Error::new(ErrorKind::Unauthorized, "You are not allowed to do this")
        .into()
        .with_status(Status::Unauthorized)
}
```

Lastly, for fallible route, we can return a result or abort early with the `?`
operator.

```rust
#[rocket::get("/fallible")]
fn fallible_route() -> Result<String> {
    let result = some_fallible_function()?;
    Ok(result)
}
```

If we need to pass a status to the error. We could use the `map_err` method.

```rust
#[rocket::get("/fallible")]
fn fallible_route() -> Result<String> {
    let result = some_fallible_function()
      .map_err(|e| e.into().with_status(Status::BadRequest))?;

    Ok(result)
}
```
