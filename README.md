# pure-tcl-aws-lambda

AWS LAMBDA client implemented in Tcl 9.1. Its only package dependency is
[`pure-tcl-aws-core`](https://github.com/jerily/pure-tcl-aws-core), which supplies
HTTP, JSON, XML, credentials and signing. No AWS C++ SDK is required.

```tcl
package require pure-tcl-aws-lambda 0.1.0
set client [::aws::lambda::create {region us-east-1}]
try {
    puts [$client list_functions]
} finally {
    $client destroy
}
```

`package require awslambda 1.0.19` is also supported. Use one implementation
of the `awslambda` package per interpreter. Existing namespace commands
(`::aws::lambda::method $client ...`) and client methods share the same behavior.
Client destruction returns an empty result. Unknown methods and invalid arguments
raise Tcl errors. See the core README for credentials, configuration and retries.

## Methods

| Method | Arguments after the client handle |
| --- | --- |
| `list_functions` | — |
| `get_function` | `name` |
| `create_function` | `name filename handler runtime role ?timeout?` |
| `delete_function` | `name` |
| `invoke_function` | `name payload ?type?` |

## Behavior

Deployment ZIPs and invocation payloads use the REST API. Function configuration dictionaries retain the existing field names. `invoke_function` returns the response payload, including function-error payloads, matching the old binding. Invocation requests are sent once; an HTTP success does not imply the function itself succeeded.

## Install and examples

Install the core and its dependencies first, then run:

```sh
make install PREFIX=/your/prefix
```

The release recipe declares examples with `file` entries. After registry installation:

```sh
ttrek run -package pure-tcl-aws-lambda -script example-list-functions
ttrek run -package pure-tcl-aws-lambda -script example-get-function -- function-name
```

`./run-example.sh --help` lists arguments. Set AWS credentials and `AWS_REGION`
or `AWS_DEFAULT_REGION` before running AWS examples. Examples read resources or sign URLs.

## Tests

With Tcl 9.1 and the dependencies on `TCLLIBPATH`:

```sh
make test TCLSH=tclsh9.1
```

Python 3 supplies local HTTP fixtures. Tests use fake credentials and do not
contact AWS. They check requests, result formats, and error handling.

## Install with ttrek

If you do not have the ttrek client, get it from [ttrek.sh](https://ttrek.sh).
Then install the package:

```sh
ttrek install pure-tcl-aws-lambda
```
