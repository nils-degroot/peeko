---
tags:
  - blog
  - rust
  - clap
date: "2025-04-28"
title: Web-service configuration using clap
layout: base/index.pug
highlighting: true
description: "Learn how to configure web services in Rust using the Clap crate. This guide covers setting up base configurations, handling nested values, managing secrets securely, and integrating with the Poem framework for a robust and flexible application setup."
---

Somewhat recently at work, we migrated our web services from the Rocket framework to Poem for several reasons. As part of that transition, we re-evaluated whether Rocket’s integrated [`figment`](https://docs.rs/figment/latest/figment/) was the right choice for us. We ultimately chose [`clap`](https://docs.rs/clap/latest/clap/) instead, as we found it simpler to set up and use.

# Base configuration

Let's first define a basic configuration for our application. Typically, this starts with a host and port.

```rust
#[derive(Debug, Clone, clap::Parser)]
struct Config {
    /// Host to bind to
    #[clap(long, env = "HOST", default_value = "127.0.0.1")]
    pub(crate) host: IpAddr,
    /// Port to bind to
    #[clap(long, env = "PORT", default_value_t = 8080)]
    pub(crate) port: u16,
}
```

A few things happen here:

- We always add the `long` annotation to the argument to prevent Clap from making it a positional argument.
- Using the `env` annotation, we can provide an environment variable to fall back on when the argument isn't passed.
- We use either `default_value` (for parsable values) or `default_value_t` (when we construct values using Rust code) to supply defaults.

# Nested values

To separate different parts of our configuration, we can use the [`Args`](https://docs.rs/clap/latest/clap/trait.Args.html) trait combined with the `flatten` annotation:

```rust
#[derive(Debug, Clone, clap::Parser)]
struct Config {
    ...
    /// Limits configuration for the application
    #[clap(flatten)]
    limits: LimitsConfig
}

#[derive(Debug, Clone, clap::Args)]
struct LimitsConfig {
    /// Maximum number of concurrent tasks
    #[clap(long, env = "MAX_CONCURRENT_TASKS", default_value_t = 4)]
    max_concurrent_tasks: u32
}
```

This allows us to move the `LimitsConfig` into a separate structure, while still exposing its fields as part of the top-level CLI.

```txt
Usage: some-web-service [OPTIONS]

Options:
      --host <HOST>
          Host to bind to [env: HOST=] [default: 127.0.0.1]
      --port <PORT>
          Port to bind to [env: PORT=] [default: 8080]
      --max-concurrent-tasks <MAX_CONCURRENT_TASKS>
          Maximum number of concurrent tasks [env: MAX_CONCURRENT_TASKS=] [default: 4]
  -h, --help
          Print help
```

# Secrets

Next, let's add some secrets. In our stack, we use [`sqlx`](https://docs.rs/sqlx/latest/sqlx/), and our preferred approach is to configure the database connection via a URL.

```rust
#[derive(Debug, Clone, clap::Parser)]
struct Config {
    ...
    /// Database configuration
    #[clap(flatten)]
    database: DatabaseConfig
}

#[derive(Debug, Clone, clap::Args)]
struct DatabaseConfig {
    /// Database URL used to connect to the database
    #[clap(long, env = "DATABASE_URL", hide_env_values = true)]
    database_url: secrecy::SecretBox<str>
}
```

We use [`secrecy`](https://docs.rs/secrecy/latest/secrecy/) to avoid printing sensitive information. When printed in debug, it will appear redacted:

```txt
DatabaseConfig { database_url: SecretBox<str>([REDACTED]) }
```

We also use the `hide_env_values` flag to prevent `--help` output from printing the value of `DATABASE_URL`.

# Usage

Now we can use the config to bootstrap our application:

```rust
use clap::Parser;

#[derive(Debug, Clone, Parser)]
struct Config {
    /// Host to bind to
    #[clap(long, env = "HOST", default_value = "127.0.0.1")]
    pub(crate) host: std::net::IpAddr,
    /// Port to bind to
    #[clap(long, env = "PORT", default_value_t = 8080)]
    pub(crate) port: u16,
    /// Limits configuration for the application
    #[clap(flatten)]
    limits: LimitsConfig,
    /// Database configuration
    #[clap(flatten)]
    database: DatabaseConfig,
}

#[derive(Debug, Clone, clap::Args)]
struct LimitsConfig {
    /// Maximum number of concurrent tasks
    #[clap(long, env = "MAX_CONCURRENT_TASKS", default_value_t = 4)]
    max_concurrent_tasks: u32,
}

#[derive(Debug, Clone, clap::Args)]
struct DatabaseConfig {
    /// Database URL used to connect to the database
    #[clap(long, env = "DATABASE_URL", hide_env_values = true)]
    database_url: secrecy::SecretBox<str>,
}

#[tokio::main]
async fn main() {
    let config = Config::parse();

    let app = poem::Route::new().at("/hello/:name", poem::get(hello));

    let listener = poem::listener::TcpListener::bind((config.host, config.port));

    poem::Server::new(listener)
        .run(app)
        .await
        .expect("Failed to run the webserver");
}

#[poem::handler]
fn hello(poem::web::Path(name): poem::web::Path<String>) -> String {
    format!("hello: {}", name)
}
```

Running `cargo run -- --help` will show all available configuration options:

```txt
Usage: blog-tingy [OPTIONS] --database-url <DATABASE_URL>

Options:
      --host <HOST>
          Host to bind to [env: HOST=] [default: 127.0.0.1]
      --port <PORT>
          Port to bind to [env: PORT=] [default: 8080]
      --max-concurrent-tasks <MAX_CONCURRENT_TASKS>
          Maximum number of concurrent tasks [env: MAX_CONCURRENT_TASKS=] [default: 4]
      --database-url <DATABASE_URL>
          Database URL used to connect to the database [env: DATABASE_URL]
  -h, --help
          Print help
```

# Limitations

So far, the main limitation we've encountered is that all argument names must be unique. For instance, if you have two nested structs both using a `host` field, the program will panic when `Config::parse()` is called. Since we usually catch this during development, it's not a big concern.
