# 
# Copyright Jerily LTD. All Rights Reserved.
# SPDX-FileCopyrightText: 2026 Neofytos Dimitriou (neo@jerily.cy)
# SPDX-License-Identifier: MIT.
# 

package require pure-tcl-aws-core 0.1.0
namespace eval ::aws::lambda {namespace path ::aws::core}
::aws::core::register lambda {list_functions get_function create_function delete_function invoke_function}

# Send a Lambda REST request with an explicitly encoded path.
proc ::aws::lambda::call {client method path {body {}} {headers {}} {retry 0}} {
    set endpoint [string trimright [dict get [$client awsconfig] endpoint] /]
    dict set headers Content-Type application/json
    $client awsrequest $method $endpoint$path $headers $body $retry
}

# Fill the legacy configuration fields when AWS omits optional values.
proc ::aws::lambda::configuration {data} {
    set result {}
    foreach key {FunctionName FunctionArn Description Runtime Role Handler LastModified CodeSha256 PackageType Version RevisionId} {dict set result $key [get $data $key]}
    foreach key {CodeSize Timeout MemorySize} {dict set result $key [get $data $key 0]}
    dict set result KmsKeyArn [get $data KMSKeyArn]
    set vpc [get $data VpcConfig]
    dict set result VpcConfig [dict create VpcId [get $vpc VpcId] SubnetIds [get $vpc SubnetIds] SecurityGroupIds [get $vpc SecurityGroupIds]]
    dict set result Environment [dict create Variables [get [get $data Environment] Variables]]
    dict set result TracingConfig [dict create Mode [get [get $data TracingConfig] Mode]]
    dict set result Architectures [get $data Architectures]
    dict set result EphemeralStorage [dict create Size [get [get $data EphemeralStorage] Size 0]]
    dict set result FileSystemConfigs [get $data FileSystemConfigs]
    dict set result Layers [get $data Layers]
    return $result
}

# Return function configurations from every page.
proc ::aws::lambda::_list_functions {client} {
    set path /2015-03-31/functions/; set out {}; set seen {}
    while {1} {
        set page [json_decode [dict get [call $client GET $path {} {} 1] body]]
        foreach function [get $page Functions] {lappend out [configuration $function]}
        set token [get $page NextMarker]
        if {![next seen $token]} {return $out}
        set path /2015-03-31/functions/?[querystring [list Marker $token]]
    }
}

# Return one function's configuration.
proc ::aws::lambda::_get_function {client name} {
    configuration [dict get [json_decode [dict get [call $client GET /2015-03-31/functions/[uri $name] {} {} 1] body]] Configuration]
}

# Create a function from a local ZIP archive.
proc ::aws::lambda::_create_function {client name filename handler runtime role {timeout 3}} {
    integer $timeout 1 900 timeout
    set fields [dict create FunctionName [list S $name] Handler [list S $handler] Runtime [list S $runtime] Role [list S $role] Timeout [list N $timeout] Code [list M [dict create ZipFile [list S [binary encode base64 -maxlen 0 [readfile $filename]]]]]]
    call $client POST /2015-03-31/functions [encoding convertto utf-8 [json_encode $fields]]
    return
}

# Delete a function by name or ARN.
proc ::aws::lambda::_delete_function {client name} {call $client DELETE /2015-03-31/functions/[uri $name]; return}

# Return the invocation payload, preserving function-error payloads for compatibility.
proc ::aws::lambda::_invoke_function {client name payload {type RequestResponse}} {
    if {$type ni {RequestResponse Event DryRun}} {error "invocation_type must be RequestResponse, Event or DryRun"}
    set response [call $client POST /2015-03-31/functions/[uri $name]/invocations [encoding convertto utf-8 $payload] [dict create X-Amz-Invocation-Type $type]]
    return [encoding convertfrom utf-8 [dict get $response body]]
}
package provide pure-tcl-aws-lambda 0.1.0
package provide awslambda 1.0.19
