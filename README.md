# Epiphany

[![Build Status](https://travis-ci.org/vptheron/epiphany.svg?branch=master)](https://travis-ci.org/vptheron/epiphany) [![Coverage Status](https://coveralls.io/repos/github/vptheron/epiphany/badge.svg?branch=master)](https://coveralls.io/github/vptheron/epiphany?branch=master)
[![hex.pm version](https://img.shields.io/hexpm/v/epiphany.svg)](https://hex.pm/packages/epiphany)

An Elixir driver for [Apache Cassandra](http://cassandra.apache.org/).

## Important Disclaimer

**Epiphany** is a _pet project_ for now.  I use it to practice and learn Elixir.

**Do not use in production**.  The API will probably change a lot.
Furthermore, I will not put a lot of effort into tests and documentation until
I have a better idea of where this is going.

However, if you would like to help improve the driver and provide feedback, you 
are very welcome to do so :)

## Usage

**Epiphany** implements version 3 of the CQL binary protocol used by Cassandra.  
This means that it should work with versions 2.x and 3.x of Cassandra.  It is 
currently tested against Apache Cassandra 3.3.

### Installation

Add epiphany to your list of dependencies in `mix.exs`:

    def deps do
      [{:epiphany, "~> 0.1.0-dev"}]
    end
    
### Examples

For now, *Epiphany* supports opening/closing a connection to one Cassandra node, 
and running simple queries.

Opening a connection:

```elixir
# Open a connection to default (localhost:9042)
iex(1)> {:ok, conn} = Epiphany.new()
{:ok, #PID<0.124.0>}

# Open a connection to 10.5.5.5 on 9043
iex(1)> {:ok, conn} = Epiphany.new({'10.5.5.5', 9043})
{:ok, #PID<0.124.0>}

# Closing a connection
iex(2)> Epiphany.close(conn)
:ok
```
The connection can (and should) be shared among several clients.

Running simple queries:

```elixir
iex(2)> Epiphany.query(conn, "use excelsior")
{:result, {:set_keyspace, "excelsior"}}

iex(3)> Epiphany.query(conn, "INSERT INTO users(user_name, birth_year) VALUES ('alice', 1993)")          
{:result, :void}

iex(4)> {:result, result} = Epiphany.query(conn, "SELECT * FROM users")
{:result, %Epiphany.Result{... omitted ...}}

iex(4)> {:result, result} = Epiphany.query(
                              conn, 
                              "SELECT * FROM users WHERE user_name = ?",
                              ["peter"])
{:result, %Epiphany.Result{... omitted ...}}
```

Using `%Epiphany.Result`:

```elixir
iex(5)> result.row_count
3

iex(6)> Enum.map(result.rows, &(Epiphany.Result.Row.as_text(&1,0)))
["bob", "peter", "alice"]

iex(7)> Enum.map(result.rows, &(Epiphany.Result.Row.as_bigint(&1,1)))
[1902, 1967, 1993]
```

Complex queries:

```elixir
iex(8)> Epiphany.query(
          conn,
          %Epiphany.Query{
            statement: "SELECT * FROM users WHERE user_name = ?",
            values: [Epiphany.DataTypes.to_text("peter")],
            consistency: :one,
            page_size: 1,
            paging_state: result.paging_state,
            serial_consistency: :local_serial})
```

`statement` can include value placeholders (`?`).  `values` is a list of bytestrings
 used with the placeholders.  `Epiphany.DataTypes` contains functions `to_XXX` to 
 be used to encode various types into bytestrings.
 
`consistency` can be set to the following values:
 
* `:one`
* `:two`
* `:three`
* `:quorum`
* `:all`
* `:local_quorum`
* `:each_quorum`
* `:serial`
* `:local_serial`
* `:local_one`

Note that `:serial` and `:local_serial` are the only supported values for 
`serial_consistency`.
 
`page_size` is used to control the size of the result set for each query.  The result
set will contain at most `page_size` rows.  If there are more rows available, 
`paging_state` will be not-nil in the returned `%Epiphany.Result`, 
and can be used to run the exact same query with the `paging_state`.  Example:
 
```elixir
iex(9)> {:result, result} = Epiphany.query(
                              conn,
                              %Epiphany.Query{
                                statement: "SELECT * FROM users",
                                page_size: 1})
{:result,
 %Epiphany.Result{
    row_count: 1,
    rows: [%Epiphany.Result.Row{
             col_count: 2, 
             columns: ["bob", <<0, 0, 0, 0, 0, 0, 7, 110>>]}]}}

iex(10)> {:result, result} = Epiphany.query(
                               conn,
                               %Epiphany.Query{
                                 statement: "SELECT * FROM users", 
                                 page_size: 1, 
                                 paging_state:  result.paging_state})
{:result,
 %Epiphany.Result{
    row_count: 1,
    rows: [%Epiphany.Result.Row{
              col_count: 2,
              columns: ["peter", <<0, 0, 0, 0, 0, 0, 7, 175>>]}]}}
```

Note that it will likely be detrimental to performance to pick a `page_size` value too low. 
A value below 100 is probably too low for most use cases.

Using prepared queries:

```elixir
iex(5)> {:result, {:prepared, id}} = Epiphany.prepare(conn, "SELECT * FROM users")
{:result,
 {:prepared,
  <<101, 144, 20, 44, 208, 131, 139, 221, 194, 118, 95, 142, 46, 35, 223, 228>>}}
  
iex(6)> Epiphany.execute(conn, id)
{:result, %Epiphany.Result{... omitted ...}}
```

## Roadmap

A lot of things left to do.  My main goal is to improve the quality of the code,
the tests and the documentation.  I use this project to learn the "Elixir Way".
Other than that, here is a non-exhaustive list of what I have in mind:

* Support missing data types (decimal, inet, uuid, varint and timeuuid)
* Access to metadata in query result to be able to access fields by name instead of
by indices
* Handle reconnection to a node
* Support authentication and SSL
* Support batch statements
* Introduce `Cluster` type to support connection to an entire cluster with automatic
discovery of the nodes, reconnection, session management, etc

## License

Copyright 2016 Vincent Theron

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
